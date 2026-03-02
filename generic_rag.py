"""
Generic RAG Ingestion Script 

"""

import uuid
import time
from pathlib import Path
from typing import List

from pinecone import Pinecone, ServerlessSpec
from sentence_transformers import SentenceTransformer
from tqdm import tqdm
from pypdf import PdfReader


# ==============================
# CONFIGURATION (EDIT THESE)
# ==============================

PINECONE_API_KEY = "your_api_key"
INDEX_NAME       = "your-index-name"

NAMESPACE        = "my-namespace"          
DOCUMENTS_PATH   = r"F:\documents_folder"  

MODEL_NAME       = "all-MiniLM-L6-v2"
CHUNK_SIZE       = 1000
CHUNK_OVERLAP    = 150
UPSERT_BATCH     = 100


# ==============================
# LOAD EMBEDDING MODEL
# ==============================

print("🔹 Loading embedding model...")
embed_model = SentenceTransformer(MODEL_NAME)
EMBEDDING_DIM = embed_model.get_sentence_embedding_dimension()
print(f"✅ Model loaded (dim={EMBEDDING_DIM})")


# ==============================
# PINECONE SETUP
# ==============================

pc = Pinecone(api_key=PINECONE_API_KEY)

def get_or_create_index():
    existing = [i.name for i in pc.list_indexes()]

    if INDEX_NAME not in existing:
        print(f"🆕 Creating index '{INDEX_NAME}' (dim={EMBEDDING_DIM})")
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
        print("❌ Documents path not found")
        return

    index = get_or_create_index()

    pdf_files = list(root.rglob("*.pdf"))

    if not pdf_files:
        print("⚠ No PDFs found")
        return

    print(f"\n📂 Found {len(pdf_files)} PDF files")
    total_vectors = 0

    for filepath in pdf_files:
        print(f"\n📄 Processing: {filepath.name}")

        text = read_pdf(filepath)

        if not text.strip():
            print("❌ No extractable text found (probably scanned PDF)")
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

        print(f"✅ {len(vectors)} vectors uploaded")

    print("\n🎉 Ingestion Complete!")
    print(f"Total vectors uploaded: {total_vectors}")


if __name__ == "__main__":
    ingest()