# Alfred – a personal RAG chatbot

Alfred is a chatbot that answers **from Denis' perspective**. It combines a large language model with a vector database (Retrieval-Augmented Generation): facts about me are stored as embeddings in [ChromaDB](https://www.trychroma.com/), the most relevant facts are retrieved for every question and passed to the model as context.

The backend is a small Flask API that can be consumed by e.g. a web frontend.

## Features

- **Two LLM backends**
  - `LeChat` (default): Mistral API (`mistral-large-latest`)
  - `Chatbot`: local GGUF model via `llama.cpp` / LangChain
- **Knowledge base in ChromaDB** – facts from JSON files or scraped from web pages
- **Update knowledge at runtime** – via a token-protected API endpoint
- **Chat history** – the last 10 messages are passed to the model
- **Docker setup** including Gunicorn

## Project structure

```
.
├── data/
│   └── aboutMeEn.json      # Facts about me (list of strings)
├── data.json               # Configuration of knowledge sources / collections
├── dataURL.json            # Example configuration for a web source
├── src/
│   ├── app/                # Flask app, routes, initialization
│   ├── chatbot/
│   │   ├── LeChat.py       # Chatbot using the Mistral API
│   │   └── Chatbot.py      # Chatbot using a local llama.cpp model
│   ├── knowledge/          # Querying ChromaDB (retrieval)
│   ├── perception/         # Populating/updating ChromaDB
│   ├── helper/             # JSON, PDF and web scraping helpers
│   └── wsgi.py             # Entry point for Gunicorn
├── chroma/chromaDB/        # Persistent vector database (not in repo)
├── llms/                   # Local GGUF models (not in repo)
├── start.sh
├── dockerfile
└── docker-compose.yml
```

## Requirements

- Python 3.11
- An API key for the [Mistral API](https://console.mistral.ai/)
- Optional for local models: `llama-cpp-python` and a GGUF model in `llms/`
- Optional: Docker & Docker Compose

## Configuration

Create a `.env` file in the project root:

```env
LE_CHAT_TOKEN=your-mistral-api-key
CHROMA_UPDATE_TOKEN=a-secret-password-for-updates
```

| Variable              | Description                                                   |
|-----------------------|---------------------------------------------------------------|
| `LE_CHAT_TOKEN`       | API key for the Mistral API                                   |
| `CHROMA_UPDATE_TOKEN` | Token that must be sent to `/api/updateKnowledge`             |
| `ROOT_PATH`           | Project root (set automatically by `start.sh`)                |

### Knowledge sources (`data.json`)

`data.json` defines which collections are created in ChromaDB and what they are filled with:

```json
[
  {
    "title": "MyInfos",
    "update": true,
    "sources": [
      { "file": "/data/aboutMeEn.json", "update": true }
    ]
  }
]
```

A source is either a local JSON file (`file`, a list of strings) or a web page (`URL`, see `dataURL.json`). For web pages, `start` and `end` can be used to cut out the relevant part of the text; short lines and questions are filtered out.

> The chatbot currently queries the `MyInfos` collection.

## Installation & running

### Locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt gunicorn

./start.sh
```

The API is then available at `http://localhost:3333`.

### With Docker

```bash
docker compose up --build
```

The `llms/`, `chroma/` and `data/` folders are mounted as volumes, so models, database and knowledge are persisted.

### Populating the knowledge base

On first start the ChromaDB is empty. Call once:

```bash
curl http://localhost:3333/api/updateChroma
```

## API

| Method | Endpoint               | Description                                              |
|--------|------------------------|----------------------------------------------------------|
| `GET`  | `/`                    | Health check                                             |
| `POST` | `/api/chat`            | Ask Alfred a question                                    |
| `GET`  | `/api/updateChroma`    | Rebuilds the embeddings based on `data.json`             |
| `GET`  | `/api/getKnowledge`    | Returns the content of `data/aboutMeEn.json`             |
| `POST` | `/api/updateKnowledge` | Overwrites `aboutMeEn.json` and updates ChromaDB         |

### Example: chat

`question` is the chat history in Mistral API format. The last message is used to search the knowledge base.

```bash
curl -X POST http://localhost:3333/api/chat \
  -H "Content-Type: application/json" \
  -d '{"question": [{"role": "user", "content": "Which sports do you play?"}]}'
```

### Example: updating knowledge

```bash
curl -X POST http://localhost:3333/api/updateKnowledge \
  -H "Content-Type: application/json" \
  -d '{
        "pwToken": "<CHROMA_UPDATE_TOKEN>",
        "knowledge": ["My name is Denis!", "I play the guitar."]
      }'
```

## Using a local model instead of the Mistral API

1. Put a GGUF model into `llms/` (e.g. `capybarahermes-2.5-mistral-7b.Q2_K.gguf`).
2. Install `llama-cpp-python`.
3. Set `model_path` in [src/chatbot/Chatbot.py](src/chatbot/Chatbot.py) to your model.
4. Switch the import in [src/app/\_\_init\_\_.py](src/app/__init__.py):
   ```python
   from chatbot.Chatbot import Chatbot
   ```

> Note: the local backend expects `question` to be a plain string instead of a chat history.

## How it works

```
Question ──► Knowledge.query()  ──► Top 3 facts from ChromaDB (distance ≤ 1.1)
                                          │
                                          ▼
               System prompt: "You're answering from my perspective ..."
                                          │
                                          ▼
                     LLM (Mistral API or llama.cpp) ──► Answer
```
