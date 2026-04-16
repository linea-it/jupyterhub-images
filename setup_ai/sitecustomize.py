"""
Automatically loaded by Python in each interpreter.

Only apply /learn patch in Jupyter Server / JupyterLab processes,
not in IPython kernels (ipykernel).
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
            "linea: failed to apply linea_jupyter_ai_learn_patch"
        )
