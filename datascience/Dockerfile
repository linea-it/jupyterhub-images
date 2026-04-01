FROM quay.io/jupyter/datascience-notebook:python-3.13

# Use root to install system dependencies
USER root

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    libcfitsio-dev \
    wcslib-dev \
    liberfa-dev \
    libchealpix-dev \
    libhealpix-cxx-dev \
    libopenblas-dev \
    liblapack-dev \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Postgresql client
# -----------------------------------------------------
RUN mkdir -p /etc/apt/keyrings

RUN wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] \
    http://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-18 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Adicionar welcome message
# -----------------------------------------------------
# Arquivos ficam em /opt/linea-tutorials/ (staging na imagem)
# e são copiados para $HOME do usuário real via before-notebook.d
USER root
COPY notebook-templates/ /opt/linea-tutorials/
COPY datascience/welcome/ /opt/linea-tutorials/
RUN chmod -R a+rX /opt/linea-tutorials/

# cp -rn: copia arquivos ausentes, preserva os que já existem (inclusive edições do usuário)
# before-notebook.d roda antes do Jupyter subir, garantindo que o default_url sempre encontre o arquivo
RUN printf '#!/bin/bash\nset -e\nmkdir -p "$HOME/notebooks/tutorials"\ncp -rn /opt/linea-tutorials/. "$HOME/notebooks/tutorials/"\nif [ "$(id -u)" = "0" ]; then\n  OWNER="$(ls -nd "$HOME" | awk '"'"'{print $3 ":" $4}'"'"')"\n  chown -R "$OWNER" "$HOME/notebooks/tutorials"\nfi\nchmod -R u+rwX "$HOME/notebooks/tutorials"\n' \
    > /usr/local/bin/before-notebook.d/10-init-tutorials.sh && \
    chmod +x /usr/local/bin/before-notebook.d/10-init-tutorials.sh
# Configurar default_url para abrir o welcome message
# default_url via json config (mais alta prioridade que jupyter_server_config.py)
RUN echo '{"ServerApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.md"},"LabApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.md"}}' > /opt/conda/etc/jupyter/jupyter_server_config.d/welcome.json
ENV NOTEBOOK_ARGS="--ContentsManager.allow_hidden=True --ServerApp.default_url=/lab/tree/notebooks/tutorials/welcome.md --LabApp.default_url=/lab/tree/notebooks/tutorials/welcome.md"
# Abrir todos os .md com Markdown Preview (renderizado) em vez do editor de texto
RUN LAB_SETTINGS="/opt/conda/share/jupyter/lab/settings" && \
    mkdir -p "${LAB_SETTINGS}" && \
    echo '{"@jupyterlab/docmanager-extension:plugin":{"defaultViewers":{"markdown":"Markdown Preview"}}}' > "${LAB_SETTINGS}/overrides.json" && \
    chown -R ${NB_UID}:users "${LAB_SETTINGS}"

# Adiiconar extensões JupyterLab
# -----------------------------------------------------
# Adicionar extensão Jupyter linea-tutorials-menu
ARG WHEEL_URL=https://github.com/linea-it/jupyterhub-templates/releases/download/v0.1.0/templates_menu-0.1.0-py3-none-any.whl
USER root
RUN mkdir -p /opt/notebook-templates
COPY notebook-templates/ /opt/notebook-templates/
RUN chown -R  ${NB_UID}:users /opt/notebook-templates && \
    chmod -R a+rX /opt/notebook-templates
RUN curl -f -L -o /tmp/templates_menu-0.1.0-py3-none-any.whl "${WHEEL_URL}" \
    && python3 -c "import zipfile; zipfile.ZipFile('/tmp/templates_menu-0.1.0-py3-none-any.whl')" \
    || (echo "Downloaded file is not a valid wheel. Confira WHEEL_URL e se o release/asset existem e são públicos." && exit 1)
USER ${NB_UID}
RUN pip install --no-cache-dir /tmp/templates_menu-0.1.0-py3-none-any.whl
USER root
RUN rm -f /tmp/templates_menu-0.1.0-py3-none-any.whl
RUN printf '%s\n' '{' '  "ServerApp": {' '    "jpserver_extensions": {' '      "templates_menu": true' '    }' '  }' '}' > /opt/conda/etc/jupyter/jupyter_server_config.d/templates_menu.json
ENV JUPYTER_TEMPLATES_DIR=/opt/notebook-templates

# Extensoes para usar IA dentro do JupyterLab
USER ${NB_UID}
RUN pip install --no-cache-dir "jupyter-ai<3" \
    langchain-google-genai \
    langchain-openai \
    langchain-anthropic \
    langchain-groq \
    langchain-deepseek
# Configurar IA para usar o provedor customizado LineA
USER root
COPY setup_ai/linea_provider/ /tmp/linea_provider/
COPY setup_ai/setup_ai_config.py /tmp/setup_ai_config.py
COPY setup_ai/15-init-jupyter-ai.sh /tmp/15-init-jupyter-ai.sh
RUN chown -R ${NB_UID}:users /tmp
# Customizar configuração para usar o provedor customizado LineA e aliases para os modelos
USER ${NB_UID}
RUN jupyter lab --generate-config && \
    pip install /tmp/linea_provider/ && \
    python3 /tmp/setup_ai_config.py
USER root
RUN chmod +x /tmp/15-init-jupyter-ai.sh && mv /tmp/15-init-jupyter-ai.sh /usr/local/bin/before-notebook.d/ && \
    rm -rf /tmp/linea_provider/ /tmp/setup_ai_config.py

# Extensoes Juypyterlab genéricas
RUN pip install --no-cache-dir jupyterlab_execute_time \
    jupytext \
    jupyterlab-git \
    jupyterlab-lsp \
    python-lsp-server \
    jupyter_bokeh \
    pyviz_comms \
    ipyaladin \
    "holoviews[recommended]" \
    hvplot \
    datashader \
    jupyterlab-code-formatter \
    black \
    isort \
    jupyterlab-spreadsheet-editor \
    ipyvolume \
    jupyter-resource-usage

# remoção de binários desnecessários
USER root
RUN rm -f \
    /usr/sbin/chroot \
    /usr/bin/unshare \
    /usr/bin/nsenter

# Python dependencies
# -----------------------------------------------------
# mamba como root para evitar Permission denied ao atualizar pacotes da imagem base;
COPY datascience/environment.yml /tmp/environment.yml
RUN mamba env update --name base -f /tmp/environment.yml \
    && mamba clean --all -f -y
RUN rm -rf /tmp/environment.yml
