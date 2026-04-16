"""
Patch for Jupyter AI /learn command.

LearnChatHandler uses ``await dask_client.compute(delayed)`` with
``distributed.Client(..., asynchronous=True)``. In this context, the
Jupyter Server (Tornado) loop can block indefinitely, while the same graph
completes with ``dask.compute()`` (local thread scheduler).

Cell-based embedding does not go through this path, so it works.

This module replaces ``LearnChatHandler.learn_dir`` with a version using
``dask.compute(..., scheduler="threads")`` for both phases (split + embeddings).
Without explicit ``scheduler``, Dask reuses the asynchronous
``distributed.Client`` already created by Jupyter AI and fails with:
"Attempting to use an asynchronous Client in a synchronous context".
We keep ``await self.dask_client_future`` for the client lifecycle used by
other extension parts.

``/learn`` chunking limits: Jupyter AI 2.x ``config.json`` only persists what
``GlobalConfig`` exposes; keys like ``retriever_options`` are dropped when the
extension writes config. So chunk sizes come from optional
``LINEA_CHUNK_SIZE`` and ``LINEA_CHUNK_OVERLAP``, with fallback to
``_DEFAULT_CHUNK_SIZE`` / ``_DEFAULT_CHUNK_OVERLAP``, overriding command args
(hub policy).
"""

from __future__ import annotations

import logging
import os
from typing import Any

_log = logging.getLogger(__name__)

_DEFAULT_CHUNK_SIZE = 1200
_DEFAULT_CHUNK_OVERLAP = 240


def _linea_env_positive_int(var: str, default: int) -> int:
    raw = os.environ.get(var)
    if raw is None or not str(raw).strip():
        return default
    try:
        v = int(str(raw).strip(), 10)
    except ValueError:
        _log.warning("%s=%r invalid; using default %s", var, raw, default)
        return default
    if v < 1:
        _log.warning("%s=%s must be >= 1; using default %s", var, v, default)
        return default
    return v


def apply_patch() -> bool:
    """Apply monkeypatch to ``LearnChatHandler.learn_dir``. Idempotent."""
    import dask
    from jupyter_ai.document_loaders.directory import get_embeddings, split
    from jupyter_ai.document_loaders.splitter import ExtensionSplitter, NotebookSplitter
    from jupyter_ai.chat_handlers.learn import LearnChatHandler
    from langchain.text_splitter import (
        LatexTextSplitter,
        MarkdownTextSplitter,
        PythonCodeTextSplitter,
        RecursiveCharacterTextSplitter,
    )

    if getattr(LearnChatHandler.learn_dir, "__linea_patched__", False):
        return True

    async def learn_dir_linea(
        self: Any,
        path: str,
        chunk_size: int,
        chunk_overlap: int,
        all_files: bool = False,
    ):
        chunk_size = _linea_env_positive_int("LINEA_CHUNK_SIZE", _DEFAULT_CHUNK_SIZE)
        chunk_overlap = _linea_env_positive_int(
            "LINEA_CHUNK_OVERLAP", _DEFAULT_CHUNK_OVERLAP
        )
        if chunk_overlap >= chunk_size:
            chunk_overlap = max(0, chunk_size - 1)
            _log.warning(
                "LINEA_CHUNK_OVERLAP adjusted to %s (< chunk_size=%s)",
                chunk_overlap,
                chunk_size,
            )

        await self.dask_client_future
        splitter_kwargs = {"chunk_size": chunk_size, "chunk_overlap": chunk_overlap}
        splitters = {
            ".py": PythonCodeTextSplitter(**splitter_kwargs),
            ".md": MarkdownTextSplitter(**splitter_kwargs),
            ".tex": LatexTextSplitter(**splitter_kwargs),
            ".ipynb": NotebookSplitter(**splitter_kwargs),
        }
        splitter = ExtensionSplitter(
            splitters=splitters,
            default_splitter=RecursiveCharacterTextSplitter(
                **splitter_kwargs  # type: ignore[arg-type]
            ),
        )

        delayed = split(path, all_files, splitter=splitter)
        (doc_chunks,) = dask.compute(delayed, scheduler="threads")

        em_provider_cls, em_provider_args = self.get_embedding_provider()
        delayed = get_embeddings(doc_chunks, em_provider_cls, em_provider_args)
        (embedding_bundle,) = dask.compute(delayed, scheduler="threads")

        if self.index:
            self.index.add_embeddings(*embedding_bundle)
        else:
            self.create(*embedding_bundle)

        self._add_dir_to_metadata(path, chunk_size, chunk_overlap)
        self.prev_em_id = em_provider_cls.id + ":" + em_provider_args["model_id"]

    learn_dir_linea.__linea_patched__ = True  # type: ignore[attr-defined]
    LearnChatHandler.learn_dir = learn_dir_linea
    _log.info(
        "linea_jupyter_ai_learn_patch: LearnChatHandler.learn_dir uses "
        "dask.compute(..., scheduler='threads'); chunking via "
        "LINEA_CHUNK_SIZE / LINEA_CHUNK_OVERLAP (default %s / %s).",
        _DEFAULT_CHUNK_SIZE,
        _DEFAULT_CHUNK_OVERLAP,
    )
    return True
