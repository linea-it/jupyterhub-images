import json
import os

# LINEA_HOST = 'http://ollama.linea-llm.svc.cluster.local:11434'
LINEA_HOST = "http://host.docker.internal:11434"

try:
    from linea_provider.provider import (
        DEFAULT_EMBEDDING_MODEL,
        GROQ_CHAT_MODEL_IDS,
        GROQ_OPENAI_BASE,
        NVIDIA_CHAT_MODEL_IDS,
        NVIDIA_OPENAI_BASE,
    )
except ImportError:
    DEFAULT_EMBEDDING_MODEL = "nomic-embed-text"
    GROQ_OPENAI_BASE = "https://api.groq.com/openai/v1"
    GROQ_CHAT_MODEL_IDS = (
        "openai/gpt-oss-120b",
        "qwen/qwen3-32b",
        "llama-3.3-70b-versatile",
    )
    NVIDIA_OPENAI_BASE = "https://integrate.api.nvidia.com/v1"
    NVIDIA_CHAT_MODEL_IDS = (
        "qwen/qwen2.5-coder-32b-instruct",
        "qwen/qwen3-coder-480b-a35b-instruct",
        "mistralai/mistral-nemotron",
    )
DEFAULT_EMBEDDINGS_PROVIDER_ID = f"linea:{DEFAULT_EMBEDDING_MODEL}"

# ── 1. ipython_config.py (%%ai magics) ───────────────────────────────────────
IPYTHON_DIR = "/home/jovyan/.ipython/profile_default"
os.makedirs(IPYTHON_DIR, exist_ok=True)

ipython_cfg_path = os.path.join(IPYTHON_DIR, "ipython_config.py")
ai_magic_block = """
# Suppress google-cloud FutureWarning
import warnings
warnings.filterwarnings("ignore", category=FutureWarning, module="google")

# Aliases for %%ai. Required format: provider:model (colon).
from jupyter_ai_magics import AiMagics
_default_aliases = AiMagics.class_traits()['aliases'].default()
_default_aliases.update({
    "coder0.5b": "linea:qwen2.5-coder:0.5b",
    "coder1.5b": "linea:qwen2.5-coder:1.5b",
    "coder3b": "linea:qwen2.5-coder:3b",
    "coder7b": "linea:qwen2.5-coder:7b",
    "groq-gpt-oss-120b": "groq:openai/gpt-oss-120b",
    "groq-qwen3-32b": "groq:qwen/qwen3-32b",
    "groq-llama-3.3-70b": "groq:llama-3.3-70b-versatile",
    "nvidia-qwen2.5-coder-32b": "nvidia:qwen/qwen2.5-coder-32b-instruct",
    "nvidia-mistral-nemotron": "nvidia:mistralai/mistral-nemotron",
    "nvidia-qwen3-coder-480b": "nvidia:qwen/qwen3-coder-480b-a35b-instruct",
})
c.AiMagics.aliases = _default_aliases
c.AiMagics.default_language_model = "linea:qwen2.5-coder:1.5b"
"""
# OpenAI-compatible aliases only (IPython profiles that already had the LineA block).
ipython_openai_compatible_aliases_append = """
# OpenAI-compatible providers. In Jupyter AI settings, use:
# - GROQ_API_KEY for Groq
# - NVIDIA_API_KEY for NVIDIA
_default_aliases.update({
    "groq-gpt-oss-120b": "groq:openai/gpt-oss-120b",
    "groq-qwen3-32b": "groq:qwen/qwen3-32b",
    "groq-llama-3.3-70b": "groq:llama-3.3-70b-versatile",
    "nvidia-qwen2.5-coder-32b": "nvidia:qwen/qwen2.5-coder-32b-instruct",
    "nvidia-mistral-nemotron": "nvidia:mistralai/mistral-nemotron",
    "nvidia-qwen3-coder-480b": "nvidia:qwen/qwen3-coder-480b-a35b-instruct",
})
c.AiMagics.aliases = _default_aliases
"""
# Append only if not already present
existing = open(ipython_cfg_path).read() if os.path.exists(ipython_cfg_path) else ""
if "jupyter_ai_magics" not in existing:
    with open(ipython_cfg_path, "a") as f:
        f.write(ai_magic_block)
    print(f"Updated: {ipython_cfg_path}")
else:
    print(f"Skipped (already configured): {ipython_cfg_path}")
    if (
        "groq-gpt-oss-120b" not in existing
        or "nvidia-qwen2.5-coder-32b" not in existing
        or "nvidia-mistral-nemotron" not in existing
        or "nvidia-qwen3-coder-480b" not in existing
    ):
        with open(ipython_cfg_path, "a") as f:
            f.write(ipython_openai_compatible_aliases_append)
        print(f"Updated (aliases OpenAI-compatible): {ipython_cfg_path}")

# ── 2. jupyter_ai/config.json (AI chat extension) ────────────────────────────
AI_DATA_DIR = "/home/jovyan/.local/share/jupyter/jupyter_ai"
os.makedirs(AI_DATA_DIR, exist_ok=True)

ai_cfg_path = os.path.join(AI_DATA_DIR, "config.json")
cfg = json.load(open(ai_cfg_path)) if os.path.exists(ai_cfg_path) else {}

cfg.setdefault("model_provider_id", "linea:qwen2.5-coder:1.5b")
if not cfg.get("embeddings_provider_id"):
    cfg["embeddings_provider_id"] = DEFAULT_EMBEDDINGS_PROVIDER_ID
cfg.setdefault("send_with_shift_enter", False)
cfg.setdefault("api_keys", {})
cfg.setdefault("completions_model_provider_id", None)
cfg.setdefault("completions_fields", {})

emb_fields = cfg.setdefault("embeddings_fields", {})
emb_key = DEFAULT_EMBEDDINGS_PROVIDER_ID
blk = emb_fields.get(emb_key, {})
if isinstance(blk, dict):
    new_blk = {k: v for k, v in blk.items() if k != "base_url"}
    new_blk["num_ctx"] = 4096
    emb_fields[emb_key] = new_blk

_default_model_fields = {
    "linea:qwen2.5-coder:0.5b": {"base_url": LINEA_HOST, "num_ctx": 4096},
    "linea:qwen2.5-coder:1.5b": {"base_url": LINEA_HOST, "num_ctx": 4096},
    "linea:qwen2.5-coder:3b": {"base_url": LINEA_HOST, "num_ctx": 4096},
    "linea:qwen2.5-coder:7b": {"base_url": LINEA_HOST, "num_ctx": 4096},
}
for mid in GROQ_CHAT_MODEL_IDS:
    _default_model_fields[f"groq:{mid}"] = {"openai_api_base": GROQ_OPENAI_BASE}
for mid in NVIDIA_CHAT_MODEL_IDS:
    _default_model_fields[f"nvidia:{mid}"] = {"openai_api_base": NVIDIA_OPENAI_BASE}
fields = cfg.setdefault("fields", {})
for model_id, field_values in _default_model_fields.items():
    if model_id not in fields:
        fields[model_id] = dict(field_values)

with open(ai_cfg_path, "w") as f:
    json.dump(cfg, f, indent=4)

print(f"Written: {ai_cfg_path}")
