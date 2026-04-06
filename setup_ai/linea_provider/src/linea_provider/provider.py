from jupyter_ai_magics import BaseEmbeddingsProvider, BaseProvider
from jupyter_ai_magics.base_provider import EnvAuthStrategy, TextField
from langchain_community.embeddings import OllamaEmbeddings
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI

# LINEA_HOST = "http://ollama.linea-llm.svc.cluster.local:11434"
LINEA_HOST = "http://host.docker.internal:11434"

# Modelo de embedding padrão no Ollama (deve existir no servidor; ver setup do cluster).
DEFAULT_EMBEDDING_MODEL = "nomic-embed-text"

# Groq: mesma lista em ``GroqChatProvider.models`` (a UI do Jupyter AI lê daqui, não do config.json).
GROQ_OPENAI_BASE = "https://api.groq.com/openai/v1"
GROQ_CHAT_MODEL_IDS = (
    "openai/gpt-oss-120b",
    "qwen/qwen3-32b",
    "llama-3.3-70b-versatile",
)


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


class GroqChatProvider(BaseProvider, ChatOpenAI):
    """Chat via API Groq (OpenAI-compatible). Aparece no seletor com modelos fixos."""

    id = "groq"
    name = "Groq"
    model_id_key = "model_name"
    model_id_label = "Model ID"
    models = list(GROQ_CHAT_MODEL_IDS)
    pypi_package_deps = ["langchain_openai"]
    auth_strategy = EnvAuthStrategy(name="OPENAI_API_KEY")
    fields = [
        TextField(
            key="openai_api_base",
            label="Base API URL (optional)",
            format="text",
        ),
    ]
    help = (
        "Modelos Groq (endpoint OpenAI-compatible). "
        "Indique a chave Groq no campo OPENAI_API_KEY nas definições do Jupyter AI."
    )

    def __init__(self, **kwargs):
        kwargs.setdefault("openai_api_base", GROQ_OPENAI_BASE)
        super().__init__(**kwargs)

    @classmethod
    def is_api_key_exc(cls, e: Exception) -> bool:
        import openai

        if isinstance(e, openai.AuthenticationError):
            body = getattr(e, "json_body", None) or {}
            error_details = body.get("error", {}) if isinstance(body, dict) else {}
            return error_details.get("code") == "invalid_api_key"
        return False


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
