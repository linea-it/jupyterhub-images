"""
Carregado automaticamente pelo Python em cada interpretador.

Só aplica o patch do /learn em processos Jupyter Server / JupyterLab,
não em kernels IPython (ipykernel).
"""

from __future__ import annotations


def _linea_should_patch_jupyter_ai_learn() -> bool:
    import sys

    if not sys.argv:
        return False
    joined = " ".join(sys.argv).lower()
    if "ipykernel" in joined:
        return False
    return "jupyter" in joined


if _linea_should_patch_jupyter_ai_learn():
    try:
        from linea_jupyter_ai_learn_patch import apply_patch

        apply_patch()
    except Exception:
        import logging

        logging.getLogger("sitecustomize").exception(
            "linea: falha ao aplicar linea_jupyter_ai_learn_patch"
        )
