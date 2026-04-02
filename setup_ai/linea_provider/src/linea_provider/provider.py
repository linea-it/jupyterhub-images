from jupyter_ai_magics import BaseEmbeddingsProvider, BaseProvider
from jupyter_ai_magics.base_provider import TextField
from langchain_ollama import ChatOllama, OllamaEmbeddings

LINEA_HOST = "http://ollama.linea-llm.svc.cluster.local:11434"

# Modelo de embedding padrão no Ollama (deve existir no servidor; ver setup do cluster).
DEFAULT_EMBEDDING_MODEL = "nomic-embed-text"


class LineaProvider(BaseProvider, ChatOllama):
    id = "linea"
    name = "LIneA"
    model_id_key = "model"
    models = [
        "qwen2.5-coder:0.5b",
        "qwen2.5-coder:1.5b",
        "qwen2.5-coder:3b",
        "qwen2.5-coder:7b",
    ]
    # No auth needed since it's local
    auth_strategy = None

    def __init__(self, **kwargs):
        kwargs.setdefault("base_url", LINEA_HOST)
        super().__init__(**kwargs)


class LineaEmbeddingsProvider(BaseEmbeddingsProvider, OllamaEmbeddings):
    id = "linea"
    name = "LIneA (embeddings)"
    model_id_key = "model"
    help = (
        "Modelos de embedding servidos pelo mesmo Ollama da LIneA. "
        "Ver https://ollama.com/search?c=embedding — por exemplo `nomic-embed-text`."
    )
    models = ["*"]
    registry = True
    auth_strategy = None
    fields = [
        TextField(key="base_url", label="Base API URL (optional)", format="text"),
    ]

    def __init__(self, **kwargs):
        kwargs.setdefault("base_url", LINEA_HOST)
        super().__init__(**kwargs)
