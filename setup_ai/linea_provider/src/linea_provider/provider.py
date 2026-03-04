from jupyter_ai_magics import BaseProvider
from langchain_ollama import ChatOllama

LINEA_HOST = "http://ollama.linea-llm.svc.cluster.local:11434"

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
