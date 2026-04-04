"""
Generic RAG Ingestion Script — PDF → chunk → embed → Pinecone upsert.
"""

import hashlib
import logging
import os
import time
from pathlib import Path
from typing import List

from dotenv import load_dotenv
from pinecone import Pinecone, ServerlessSpec
from sentence_transformers import SentenceTransformer
from tqdm import tqdm
from pypdf import PdfReader

load_dotenv()

logger = logging.getLogger(__name__)

# ==============================
# CONFIGURATION
# ==============================

PINECONE_API_KEY: str = os.environ["PINECONE_API_KEY"]
INDEX_NAME: str = os.environ["PINECONE_INDEX"]
NAMESPACE: str = os.environ.get("PINECONE_NAMESPACE", "default")
DOCUMENTS_PATH: str = os.environ["DOCUMENTS_PATH"]
MODEL_NAME: str = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
CHUNK_SIZE: int = int(os.environ.get("CHUNK_SIZE", "512"))
CHUNK_OVERLAP: int = int(os.environ.get("CHUNK_OVERLAP", "50"))
UPSERT_BATCH: int = 100

# ==============================
# LOAD EMBEDDING MODEL
# ==============================

logger.info("Loading embedding model: %s", MODEL_NAME)
embed_model = SentenceTransformer(MODEL_NAME)
EMBEDDING_DIM: int = embed_model.get_sentence_embedding_dimension()
logger.info("Model loaded (dim=%d)", EMBEDDING_DIM)

# ==============================
# PINECONE SETUP
# ==============================

pc = Pinecone(api_key=PINECONE_API_KEY)


def get_or_create_index():
    """Return the Pinecone index, creating it if it does not exist.

    Returns:
        Pinecone Index object ready for upsert/query.
    """
    existing = [i.name for i in pc.list_indexes()]

    if INDEX_NAME not in existing:
        logger.info("Creating index '%s' (dim=%d)", INDEX_NAME, EMBEDDING_DIM)
        pc.create_index(
            name=INDEX_NAME,
            dimension=EMBEDDING_DIM,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region="us-east-1"),
        )
        time.sleep(15)

    return pc.Index(INDEX_NAME)


# ==============================
# TEXT EXTRACTION
# ==============================

def read_pdf(filepath: Path) -> str:
    """Extract all text from a PDF file, page by page.

    Args:
        filepath: Path to the PDF file.

    Returns:
        Concatenated text from all pages with page markers.
    """
    reader = PdfReader(str(filepath))
    pages_text = []

    for i, page in enumerate(reader.pages):
        text = page.extract_text()
        if text and text.strip():
            pages_text.append(f"[Page {i + 1}]\n{text}")

    return "\n\n".join(pages_text)


# ==============================
# CHUNKING
# ==============================

def chunk_text(text: str) -> List[str]:
    """Split text into overlapping fixed-size chunks.

    Args:
        text: Raw extracted text to split.

    Returns:
        List of non-empty text chunks.

    Raises:
        ValueError: If text is empty.
    """
    if not text.strip():
        raise ValueError("text must not be empty")

    chunks = []
    text = text.strip()
    start = 0

    while start < len(text):
        end = min(start + CHUNK_SIZE, len(text))
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        start += CHUNK_SIZE - CHUNK_OVERLAP

    return chunks


# ==============================
# EMBEDDINGS
# ==============================

def get_embeddings(texts: List[str]) -> List[List[float]]:
    """Batch-encode texts into normalised embeddings.

    Args:
        texts: List of text strings to embed.

    Returns:
        List of embedding vectors (each of length EMBEDDING_DIM).
    """
    return embed_model.encode(
        texts,
        batch_size=32,
        show_progress_bar=False,
        normalize_embeddings=True,
    ).tolist()


# ==============================
# UPSERT
# ==============================

def upsert_vectors(index, vectors: list) -> None:
    """Upload vectors to Pinecone in batches of UPSERT_BATCH.

    Args:
        index: Pinecone Index object.
        vectors: List of vector dicts with id, values, and metadata.
    """
    batches = [vectors[i : i + UPSERT_BATCH] for i in range(0, len(vectors), UPSERT_BATCH)]

    for batch in tqdm(batches, desc=f"Uploading to namespace '{NAMESPACE}'"):
        index.upsert(vectors=batch, namespace=NAMESPACE)


# ==============================
# MAIN INGESTION
# ==============================

def ingest() -> None:
    """Run the full PDF ingestion pipeline: extract → chunk → embed → upsert.

    Raises:
        FileNotFoundError: If DOCUMENTS_PATH does not exist.
    """
    root = Path(DOCUMENTS_PATH)

    if not root.exists():
        raise FileNotFoundError(f"Documents path not found: {DOCUMENTS_PATH}")

    index = get_or_create_index()
    pdf_files = list(root.rglob("*.pdf"))

    if not pdf_files:
        logger.warning("No PDFs found in %s", DOCUMENTS_PATH)
        return

    logger.info("Found %d PDF files", len(pdf_files))
    total_vectors = 0

    for filepath in pdf_files:
        logger.info("Processing: %s", filepath.name)

        text = read_pdf(filepath)

        if not text.strip():
            logger.warning("No extractable text in %s — skipping", filepath.name)
            continue

        file_hash = hashlib.sha256(filepath.read_bytes()).hexdigest()
        chunks = chunk_text(text)
        embeddings = get_embeddings(chunks)

        vectors = [
            {
                "id": f"{file_hash}_{i}",
                "values": embedding,
                "metadata": {
                    "source": filepath.name,
                    "chunk_index": i,
                    "chunk_text": chunk,
                },
            }
            for i, (chunk, embedding) in enumerate(zip(chunks, embeddings))
        ]

        upsert_vectors(index, vectors)
        total_vectors += len(vectors)
        logger.info("Uploaded %d vectors from %s", len(vectors), filepath.name)

    logger.info("Ingestion complete — total vectors: %d", total_vectors)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    ingest()
