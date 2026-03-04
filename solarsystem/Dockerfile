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

# Hardening
# -----------------------------------------------------------------------------

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
    && mamba clean --all -f -y

# Install additional Python packages via pip
RUN pip install --no-cache-dir \
    astrocut \
    lineassp