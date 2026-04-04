"""
Generic RAG Ingestion Script

"""

import logging
import os
import uuid
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
logging.basicConfig(level=logging.INFO)

# ==============================
# CONFIGURATION (from env vars)
# ==============================

PINECONE_API_KEY = os.environ["PINECONE_API_KEY"]
INDEX_NAME       = os.environ["PINECONE_INDEX_NAME"]

NAMESPACE        = os.environ.get("PINECONE_NAMESPACE", "default")
DOCUMENTS_PATH   = os.environ["DOCUMENTS_PATH"]

MODEL_NAME       = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
CHUNK_SIZE       = int(os.environ.get("CHUNK_SIZE", "1000"))
CHUNK_OVERLAP    = int(os.environ.get("CHUNK_OVERLAP", "150"))
UPSERT_BATCH     = 100


# ==============================
# LOAD EMBEDDING MODEL
# ==============================

logger.info("Loading embedding model: %s", MODEL_NAME)
embed_model = SentenceTransformer(MODEL_NAME)
EMBEDDING_DIM = embed_model.get_sentence_embedding_dimension()
logger.info("Model loaded (dim=%d)", EMBEDDING_DIM)


# ==============================
# PINECONE SETUP
# ==============================

pc = Pinecone(api_key=PINECONE_API_KEY)

def get_or_create_index():
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
    reader = PdfReader(str(filepath))
    pages_text = []

    for i, page in enumerate(reader.pages):
        text = page.extract_text()
        if text and text.strip():
            pages_text.append(f"[Page {i+1}]\n{text}")

    return "\n\n".join(pages_text)


# ==============================
# CHUNKING
# ==============================

def chunk_text(text: str) -> List[str]:
    chunks = []
    start = 0
    text = text.strip()
    length = len(text)

    while start < length:
        end = min(start + CHUNK_SIZE, length)
        chunk = text[start:end]

        if chunk.strip():
            chunks.append(chunk)

        start += CHUNK_SIZE - CHUNK_OVERLAP

    return chunks


# ==============================
# EMBEDDINGS
# ==============================

def get_embeddings(texts: List[str]) -> List[List[float]]:
    return embed_model.encode(texts, show_progress_bar=True).tolist()


# ==============================
# UPSERT
# ==============================

def upsert_vectors(index, vectors):
    batches = [vectors[i:i+UPSERT_BATCH] for i in range(0, len(vectors), UPSERT_BATCH)]

    for batch in tqdm(batches, desc=f"⬆ Uploading to namespace '{NAMESPACE}'"):
        index.upsert(vectors=batch, namespace=NAMESPACE)


# ==============================
# MAIN INGESTION
# ==============================

def ingest():
    root = Path(DOCUMENTS_PATH)

    if not root.exists():
        logger.error("Documents path not found: %s", root)
        return

    index = get_or_create_index()

    pdf_files = list(root.rglob("*.pdf"))

    if not pdf_files:
        logger.warning("No PDFs found in %s", root)
        return

    logger.info("Found %d PDF files", len(pdf_files))
    total_vectors = 0

    for filepath in pdf_files:
        logger.info("Processing: %s", filepath.name)

        text = read_pdf(filepath)

        if not text.strip():
            logger.warning("No extractable text in %s (possibly scanned PDF)", filepath.name)
            continue

        chunks = chunk_text(text)
        embeddings = get_embeddings(chunks)

        vectors = []
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            vectors.append({
                "id": f"{filepath.stem}_{i}_{uuid.uuid4().hex[:6]}",
                "values": embedding,
                "metadata": {
                    "source": filepath.name,
                    "chunk_index": i,
                    "text": chunk
                }
            })

        upsert_vectors(index, vectors)
        total_vectors += len(vectors)

        logger.info("Uploaded %d vectors for %s", len(vectors), filepath.name)

    logger.info("Ingestion complete. Total vectors uploaded: %d", total_vectors)


if __name__ == "__main__":
    ingest()