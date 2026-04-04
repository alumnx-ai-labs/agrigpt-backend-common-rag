"""
Query API for AgriGPT RAG — semantic search over Pinecone vector index.
"""

import hashlib
import logging
import os
from typing import Any

from dotenv import load_dotenv
from pinecone import Pinecone
from sentence_transformers import SentenceTransformer

load_dotenv()

logger = logging.getLogger(__name__)

PINECONE_API_KEY: str = os.environ["PINECONE_API_KEY"]
INDEX_NAME: str = os.environ.get("PINECONE_INDEX", "agrigpt-prod")
NAMESPACE: str = os.environ.get("PINECONE_NAMESPACE", "default")
EMBEDDING_DIM: int = 384
PINECONE_BATCH_SIZE: int = 100

logger.info("Connecting to Pinecone...")
pc = Pinecone(api_key=PINECONE_API_KEY)
index = pc.Index(INDEX_NAME)


def load_model() -> SentenceTransformer:
    """Load and return the sentence transformer embedding model.

    Returns:
        Loaded SentenceTransformer model (all-MiniLM-L6-v2, 384-dim).
    """
    logger.info("Loading embedding model...")
    return SentenceTransformer("all-MiniLM-L6-v2")


model = load_model()


def search(query: str, top_k: int = 5) -> list[dict[str, Any]]:
    """Perform semantic search against the Pinecone index.

    Args:
        query: Natural language query string.
        top_k: Number of top results to return.

    Returns:
        List of matching document metadata dicts.

    Raises:
        RuntimeError: If the Pinecone query fails.
    """
    embedding = model.encode([query], normalize_embeddings=True)[0].tolist()
    results = index.query(
        vector=embedding,
        top_k=top_k,
        namespace=NAMESPACE,
        include_metadata=True,
    )
    return results["matches"]


def upsert_chunks(file_hash: str, chunks: list[str]) -> None:
    """Embed and upsert text chunks into Pinecone with idempotent vector IDs.

    Args:
        file_hash: SHA-256 hash of the source file (ensures idempotency).
        chunks: List of text chunks to embed and store.

    Raises:
        ValueError: If chunks list is empty.
    """
    if not chunks:
        raise ValueError("chunks must not be empty")

    embeddings = model.encode(
        chunks,
        batch_size=32,
        show_progress_bar=False,
        normalize_embeddings=True,
    ).tolist()

    vectors = [
        {
            "id": f"{file_hash}_{i}",
            "values": embedding,
            "metadata": {"chunk_text": chunk, "chunk_index": i},
        }
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings))
    ]

    for i in range(0, len(vectors), PINECONE_BATCH_SIZE):
        batch = vectors[i : i + PINECONE_BATCH_SIZE]
        index.upsert(vectors=batch, namespace=NAMESPACE)
        logger.info("Upserted %d vectors (batch %d)", len(batch), i // PINECONE_BATCH_SIZE)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    hits = search("how to treat wheat rust")
    for h in hits:
        logger.info(h["metadata"].get("chunk_text", ""))
