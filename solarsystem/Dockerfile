FROM quay.io/jupyter/datascience-notebook:python-3.13


# Use root to install system dependencies
USER root

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

RUN apt-get update --yes && \
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
# Criar diretório de keyrings
RUN mkdir -p /etc/apt/keyrings

# Adicionar chave do PostgreSQL
RUN wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg

# Adicionar repositório PGDG para Ubuntu 24.04 (noble)
RUN echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] \
    http://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

# Instalar cliente 18
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-18 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*



# Python dependencies
# -----------------------------------------------------

# Switch back to the notebook user
USER ${NB_UID}

# Install Python packages via mamba
RUN mamba install -y \
    # Database Access & Querying
    psycopg[c] \
    SQLAlchemy \
    && mamba clean --all -f -y

# Install additional Python packages via pip
RUN pip install --no-cache-dir \
    astrocut \
    lineassp
