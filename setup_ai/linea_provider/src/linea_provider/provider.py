import os

from jupyter_ai_magics import BaseEmbeddingsProvider, BaseProvider
from jupyter_ai_magics.base_provider import EnvAuthStrategy, TextField
from langchain_community.embeddings import OllamaEmbeddings
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI

LINEA_HOST = "http://ollama.linea-llm.svc.cluster.local:11434"
# LINEA_HOST = "http://host.docker.internal:11434"

# Default embedding model on Ollama (must exist on server; see cluster setup).
DEFAULT_EMBEDDING_MODEL = "nomic-embed-text"

# OpenAI-compatible providers: Jupyter AI UI reads this list, not config.json.
GROQ_OPENAI_BASE = "https://api.groq.com/openai/v1"
GROQ_CHAT_MODEL_IDS = (
    "openai/gpt-oss-120b",
    "qwen/qwen3-32b",
    "llama-3.3-70b-versatile",
)
NVIDIA_OPENAI_BASE = "https://integrate.api.nvidia.com/v1"
NVIDIA_CHAT_MODEL_IDS = (
    "qwen/qwen2.5-coder-32b-instruct",
    "mistralai/mistral-nemotron",
    "qwen/qwen3-coder-480b-a35b-instruct",
)


def _first_non_empty(*values):
    for value in values:
        if value is None:
            continue
        if isinstance(value, str):
            value = value.strip()
        if value:
            return value
    return None


def _inject_openai_api_key(kwargs: dict, provider_key_name: str) -> None:
    """Ensure OpenAI-compatible providers always receive a non-empty api key."""
    provider_key_lower = provider_key_name.lower()
    api_keys = kwargs.pop("api_keys", None)
    api_keys_provider = None
    api_keys_openai = None
    if isinstance(api_keys, dict):
        api_keys_provider = api_keys.get(provider_key_name) or api_keys.get(
            provider_key_lower
        )
        api_keys_openai = api_keys.get("OPENAI_API_KEY") or api_keys.get(
            "openai_api_key"
        )

    provider_key_value = kwargs.pop(provider_key_name, None)
    if provider_key_value is None:
        provider_key_value = kwargs.pop(provider_key_lower, None)

    api_key = _first_non_empty(
        kwargs.get("openai_api_key"),
        kwargs.get("api_key"),
        provider_key_value,
        api_keys_provider,
        api_keys_openai,
        os.environ.get(provider_key_name),
        os.environ.get(provider_key_lower),
        os.environ.get("OPENAI_API_KEY"),
    )
    if api_key:
        kwargs["openai_api_key"] = api_key
        kwargs["api_key"] = api_key
    # Never forward provider auth field names to OpenAI-compatible payloads.
    kwargs.pop(provider_key_name, None)
    kwargs.pop(provider_key_lower, None)


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
    """Chat via Groq API (OpenAI-compatible). Appears with fixed models."""

    id = "groq"
    name = "Groq"
    model_id_key = "model_name"
    model_id_label = "Model ID"
    models = list(GROQ_CHAT_MODEL_IDS)
    pypi_package_deps = ["langchain_openai"]
    auth_strategy = EnvAuthStrategy(name="GROQ_API_KEY")
    fields = [
        TextField(
            key="openai_api_base",
            label="Base API URL (optional)",
            format="text",
        ),
    ]
    help = (
        "Groq models (OpenAI-compatible endpoint). "
        "Set your Groq key in the GROQ_API_KEY field in Jupyter AI settings."
    )

    def __init__(self, **kwargs):
        kwargs.setdefault("openai_api_base", GROQ_OPENAI_BASE)
        _inject_openai_api_key(kwargs, "GROQ_API_KEY")
        super().__init__(**kwargs)

    @classmethod
    def is_api_key_exc(cls, e: Exception) -> bool:
        import openai

        if isinstance(e, openai.AuthenticationError):
            body = getattr(e, "json_body", None) or {}
            error_details = body.get("error", {}) if isinstance(body, dict) else {}
            return error_details.get("code") == "invalid_api_key"
        return False


class NvidiaChatProvider(BaseProvider, ChatOpenAI):
    """Chat via API NVIDIA NIM (OpenAI-compatible)."""

    id = "nvidia"
    name = "NVIDIA NIM (AI Endpoints)"
    model_id_key = "model_name"
    model_id_label = "Model ID"
    models = list(NVIDIA_CHAT_MODEL_IDS)
    pypi_package_deps = ["langchain_openai"]
    auth_strategy = EnvAuthStrategy(name="NVIDIA_API_KEY")
    fields = [
        TextField(
            key="openai_api_base",
            label="Base API URL (optional)",
            format="text",
        ),
    ]
    help = (
        "NVIDIA NIM models (OpenAI-compatible endpoint). "
        "Set your NVIDIA key in the NVIDIA_API_KEY field in Jupyter AI settings."
    )

    def __init__(self, **kwargs):
        kwargs.setdefault("openai_api_base", NVIDIA_OPENAI_BASE)
        _inject_openai_api_key(kwargs, "NVIDIA_API_KEY")
        super().__init__(**kwargs)

    @classmethod
    def is_api_key_exc(cls, e: Exception) -> bool:
        import openai

        return isinstance(e, openai.AuthenticationError)


class LineaEmbeddingsProvider(BaseEmbeddingsProvider, OllamaEmbeddings):
    id = "linea"
    name = "LIneA (embeddings)"
    model_id_key = "model"
    help = (
        "Embedding models served by the same LIneA Ollama instance. "
        "See https://ollama.com/search?c=embedding - for example `nomic-embed-text`."
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
