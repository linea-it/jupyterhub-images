FROM quay.io/jupyter/base-notebook:python-3.13

# Use root to install system dependencies
USER root

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends build-essential \
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
    gcc \
    gfortran \
    curl \
    nano \
    vim \
    git && \
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

# Adicionar welcome message e tutoriais
# -----------------------------------------------------
# Baixa tutoriais (welcome.html + notebooks) do repo linea-it/jupyterhub-tutorial
# Arquivos ficam em /opt/linea-tutorials/ (staging) e /opt/notebook-templates/ (menu templates)
# e são copiados para $HOME do usuário real via before-notebook.d
ARG TUTORIALS_REPO=https://github.com/linea-it/jupyterhub-tutorial
ARG TUTORIALS_BRANCH=main
ENV TUTORIALS_REPO=${TUTORIALS_REPO}
ENV TUTORIALS_BRANCH=${TUTORIALS_BRANCH}
USER root
RUN mkdir -p /opt/linea-tutorials /opt/notebook-templates && \
    curl -fsSL "${TUTORIALS_REPO}/archive/refs/heads/${TUTORIALS_BRANCH}.tar.gz" \
    | tar xz --strip-components=2 -C /opt/linea-tutorials/ \
        "jupyterhub-tutorial-${TUTORIALS_BRANCH}/tutorials/" && \
    cp -a /opt/linea-tutorials/. /opt/notebook-templates/ && \
    rm -f /opt/notebook-templates/welcome.html && \
    chmod -R a+rX /opt/linea-tutorials /opt/notebook-templates

# before-notebook.d: fetch latest tutorials and sync to user's home
COPY scripts/before-notebook.d/10-init-tutorials.sh /usr/local/bin/before-notebook.d/10-init-tutorials.sh
RUN chmod +x /usr/local/bin/before-notebook.d/10-init-tutorials.sh
# Configurar default_url para abrir o welcome message
# default_url via json config (mais alta prioridade que jupyter_server_config.py)
RUN echo '{"ServerApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.html"},"LabApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.html"}}' > /opt/conda/etc/jupyter/jupyter_server_config.d/welcome.json
ENV NOTEBOOK_ARGS="--ContentsManager.allow_hidden=True --ServerApp.default_url=/lab/tree/notebooks/tutorials/welcome.html --LabApp.default_url=/lab/tree/notebooks/tutorials/welcome.html"
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
RUN chown -R ${NB_UID}:users /opt/notebook-templates
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
    langchain-community \
    langchain-deepseek
# Configurar IA para usar o provedor customizado LineA
USER root
COPY setup_ai/linea_provider/ /tmp/linea_provider/
COPY setup_ai/setup_ai_config.py /tmp/setup_ai_config.py
COPY setup_ai/15-init-jupyter-ai.sh /tmp/15-init-jupyter-ai.sh
COPY setup_ai/linea-load-apikeys.sh /usr/local/bin/linea-load-apikeys.sh
COPY setup_ai/linea-setup-apikeys.sh /usr/local/bin/linea-setup-apikeys.sh
RUN chown -R ${NB_UID}:users /tmp
# Customizar configuração para usar o provedor customizado LineA e aliases para os modelos
USER ${NB_UID}
RUN jupyter lab --generate-config && \
    pip install /tmp/linea_provider/ && \
    python3 /tmp/setup_ai_config.py
USER root
# /learn: evitar bloqueio Dask distributed (async) + Tornado; usar dask.compute local
COPY setup_ai/linea_jupyter_ai_learn_patch.py setup_ai/sitecustomize.py \
    /opt/conda/lib/python3.13/site-packages/
RUN chmod +x /tmp/15-init-jupyter-ai.sh /usr/local/bin/linea-load-apikeys.sh /usr/local/bin/linea-setup-apikeys.sh && mv /tmp/15-init-jupyter-ai.sh /usr/local/bin/before-notebook.d/ && \
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
COPY solarsystem/environment.yml /tmp/environment.yml
RUN mamba env update --name base -f /tmp/environment.yml \
    && mamba clean --all -f -y
RUN rm -rf /tmp/environment.yml
