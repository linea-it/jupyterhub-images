import json, os

LINEA_HOST = 'http://ollama.linea-llm.svc.cluster.local:11434'

# ── 1. ipython_config.py (%%ai magics) ───────────────────────────────────────
IPYTHON_DIR = '/home/jovyan/.ipython/profile_default'
os.makedirs(IPYTHON_DIR, exist_ok=True)

ipython_cfg_path = os.path.join(IPYTHON_DIR, 'ipython_config.py')
ai_magic_block = """
# Suppress google-cloud FutureWarning
import warnings
warnings.filterwarnings("ignore", category=FutureWarning, module="google")

# Aliases para %%ai. Formato obrigatório: provider:model (dois-pontos).
from jupyter_ai_magics import AiMagics
_default_aliases = AiMagics.class_traits()['aliases'].default()
_default_aliases.update({
    "coder05": "linea:qwen2.5-coder:0.5b",
    "coder1b": "linea:qwen2.5-coder:1.5b",
    "coder3b": "linea:qwen2.5-coder:3b",
    "coder7b": "linea:qwen2.5-coder:7b",
})
c.AiMagics.aliases = _default_aliases
c.AiMagics.default_language_model = "linea:qwen2.5-coder:0.5b"
"""
# Append only if not already present
existing = open(ipython_cfg_path).read() if os.path.exists(ipython_cfg_path) else ''
if 'jupyter_ai_magics' not in existing:
    with open(ipython_cfg_path, 'a') as f:
        f.write(ai_magic_block)
    print(f"Updated: {ipython_cfg_path}")
else:
    print(f"Skipped (already configured): {ipython_cfg_path}")

# ── 2. jupyter_ai/config.json (AI chat extension) ────────────────────────────
AI_DATA_DIR = '/home/jovyan/.local/share/jupyter/jupyter_ai'
os.makedirs(AI_DATA_DIR, exist_ok=True)

ai_cfg_path = os.path.join(AI_DATA_DIR, 'config.json')
cfg = json.load(open(ai_cfg_path)) if os.path.exists(ai_cfg_path) else {}

cfg.setdefault('model_provider_id', 'linea:qwen2.5-coder:0.5b')
cfg.setdefault('embeddings_provider_id', None)
cfg.setdefault('send_with_shift_enter', False)
cfg.setdefault('api_keys', {})
cfg.setdefault('completions_model_provider_id', None)
cfg.setdefault('completions_fields', {})
cfg.setdefault('embeddings_fields', {})
cfg.setdefault('fields', {
    'linea:qwen2.5-coder:0.5b': {'base_url': LINEA_HOST, 'num_ctx': 2048},
    'linea:qwen2.5-coder:1.5b': {'base_url': LINEA_HOST, 'num_ctx': 2048},
    'linea:qwen2.5-coder:3b':   {'base_url': LINEA_HOST, 'num_ctx': 2048},
    'linea:qwen2.5-coder:7b':   {'base_url': LINEA_HOST, 'num_ctx': 4096},
})

json.dump(cfg, open(ai_cfg_path, 'w'), indent=4)
print(f"Written: {ai_cfg_path}")
