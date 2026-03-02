# 📚 Generic RAG Ingestion Pipeline (Pinecone + Sentence Transformers)

This project provides a **production-ready ingestion pipeline** for
building a Retrieval-Augmented Generation (RAG) system using:

-   🔹 Pinecone (Vector Database)
-   🔹 Sentence Transformers (Embeddings)
-   🔹 PDF Document Processing
-   🔹 Automatic Chunking
-   🔹 Batch Vector Uploading

------------------------------------------------------------------------

## 🚀 Features

-   ✅ Extracts text from PDFs
-   ✅ Smart text chunking with overlap
-   ✅ Generates embeddings using `all-MiniLM-L6-v2`
-   ✅ Batch upserts to Pinecone namespace
-   ✅ Stores metadata (source file, chunk index, text)

------------------------------------------------------------------------

## 📂 Project Structure

    .
    ├── generic_rag.py        # Main ingestion script
    ├── requirements.txt      # Python dependencies
    └── README.md             # Project documentation

------------------------------------------------------------------------

## 🛠 Installation

### 1️⃣ Clone the Repository

``` bash
git clone <your-repo-url>
cd <your-repo-folder>
```

### 2️⃣ Create Virtual Environment

``` bash
python -m venv venv
venv\Scripts\activate   # Windows
# source venv/bin/activate  # Mac/Linux
```

### 3️⃣ Install Dependencies

``` bash
pip install -r requirements.txt
```

------------------------------------------------------------------------

## 🔑 Configuration

Open `generic_rag.py` and update:

``` python
PINECONE_API_KEY = "your_api_key"
INDEX_NAME       = "your-index-name"
NAMESPACE        = "my-namespace"
DOCUMENTS_PATH   = r"F:\documents_folder"
```

You can also modify:

-   `MODEL_NAME`
-   `CHUNK_SIZE`
-   `CHUNK_OVERLAP`
-   `UPSERT_BATCH`

------------------------------------------------------------------------

## ▶️ Run Ingestion

Place your PDF documents inside the configured `DOCUMENTS_PATH`, then
run:

``` bash
python generic_rag.py
```

------------------------------------------------------------------------

## 📊 How It Works

1.  Loads embedding model
2.  Creates Pinecone index (if not exists)
3.  Extracts text from PDFs
4.  Splits text into overlapping chunks
5.  Generates embeddings
6.  Uploads vectors with metadata

------------------------------------------------------------------------

## 📦 Requirements

-   pinecone-client\>=3.0.0
-   sentence-transformers\>=2.6.0
-   pypdf\>=4.0.0
-   tqdm\>=4.66.0
-   torch\>=2.0.0
-   transformers\>=4.38.0

------------------------------------------------------------------------

## ⚠ Notes

-   Scanned PDFs (image-only) will not work unless OCR is added.
-   Ensure Pinecone index dimension matches embedding model dimension.


------------------------------------------------------------------------
