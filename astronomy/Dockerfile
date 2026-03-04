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
# Arquivo é copiado para /home/${NB_USER}/notebooks/tutorials/ similar ao rubin
USER root
COPY notebook-templates/ /home/${NB_USER}/notebooks/tutorials/
COPY astronomy/welcome/ /home/${NB_USER}/notebooks/tutorials/
RUN chown -R ${NB_UID}:users /home/${NB_USER}/notebooks/tutorials/
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
RUN chown -R  ${NB_UID}:users /opt/notebook-templates
RUN curl -f -L -o /tmp/templates_menu-0.1.0-py3-none-any.whl "${WHEEL_URL}" \
    && python3 -c "import zipfile; zipfile.ZipFile('/tmp/templates_menu-0.1.0-py3-none-any.whl')" \
    || (echo "Downloaded file is not a valid wheel. Confira WHEEL_URL e se o release/asset existem e são públicos." && exit 1)
USER ${NB_UID}
RUN pip install --no-cache-dir /tmp/templates_menu-0.1.0-py3-none-any.whl
USER root
RUN printf '%s\n' '{' '  "ServerApp": {' '    "jpserver_extensions": {' '      "templates_menu": true' '    }' '  }' '}' > /opt/conda/etc/jupyter/jupyter_server_config.d/templates_menu.json
ENV JUPYTER_TEMPLATES_DIR=/opt/notebook-templates

# Extensoes para usar IA dentro do JupyterLab
USER ${NB_UID}
RUN pip install --no-cache-dir "jupyter-ai[all]<4" \
    jupyter-ai-magics \
    langchain-google-genai \
    langchain-openai \
    langchain-anthropic \
    langchain-groq \
    langchain-deepseek
# Configurar IA para usar o provedor customizado LineA
USER root
COPY setup_ai/linea_provider/ /tmp/linea_provider/
COPY setup_ai/setup_ai_config.py /tmp/setup_ai_config.py
RUN chown -R ${NB_UID}:users /tmp/linea_provider/
# Customizar configuração para usar o provedor customizado LineA e aliases para os modelos
USER ${NB_UID}
RUN jupyter lab --generate-config && \
    pip install /tmp/linea_provider/ && \
    python3 /tmp/setup_ai_config.py

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
RUN rm -f \
    /usr/sbin/chroot \
    /usr/bin/unshare \
    /usr/bin/nsenter

# Python dependencies
# -----------------------------------------------------

# Switch back to the notebook user
USER ${NB_UID}

# Install Python packages via mamba
RUN mamba install -y \
    # Database Access & Querying
    psycopg[c] \
    SQLAlchemy \
    # --- Data Science ---
    numpy \
    scipy \
    pandas \
    matplotlib \
    seaborn \
    scikit-image \
    scikit-learn \
    dask \
    # --- Astronomia ---
    astropy \
    astroquery \
    healpy \
    photutils \
    regions \
    reproject \
    hats \
    hats-import \
    lsdb \
    pyvo \
    sbpy \
    # ipyaladin também é instalado via pip para garantir integração/extensão no JupyterLab
    ipyaladin \
    dustmaps \
    specutils \
    pyspeckit \
    spiceypy \
    cartopy \
    # --- Interactive Visualization ---
    bokeh \
    holoviews \
    # hvplot/datashader também são instalados via pip para garantir integração/extensão no JupyterLab
    # hvplot \
    # datashader \
    plotly \
    # --- Inference, Fitting & Machine Learning ---
    emcee \
    corner \
    dynesty \
    astroml \
    lmfit \
    rebound \
    pyvista \
    pooch \
    && mamba clean --all -f -y

# Install additional Python packages via pip
RUN pip install --no-cache-dir \
    astrocut \
    pyspac \
    lineassp \
    pzserver \
    rail \
    sora-astro \
    reboundx \
    lightkurve
