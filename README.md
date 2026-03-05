# LIneA JupyterHub Images

![Build Status](https://github.com/linea-it/jupyterhub-images/actions/workflows/build.yml/badge.svg)

![Pre-commit](https://github.com/linea-it/jupyterhub-images/actions/workflows/pre-commit.yml/badge.svg)

![DockerHub DataScience](https://img.shields.io/docker/v/linea/jupyter-datascience?label=datascience&sort=semver)
![DockerHub SolarSystem](https://img.shields.io/docker/v/linea/jupyter-solarsystem?label=solarsystem&sort=semver)





This repository contains the Docker images used by LIneA’s JupyterHub infrastructure.

It provides reproducible, versioned Jupyter environments built on top of the official Jupyter Docker Stacks and extended with scientific and domain-specific dependencies.



## Repository Structure

```
.
├── datascience/
│   ├── Dockerfile
│   ├── environment.yml
│   └── welcome/
│       ├── welcome.md
│       └── image.png
├── astronomy/
│   ├── Dockerfile
│   ├── environment.yml
│   └── welcome/
│       ├── welcome.md
│       └── image.png
├── solarsystem/
│   ├── Dockerfile
│   ├── environment.yml
│   └── welcome/
│       ├── welcome.md
│       └── image.png
├── notebook-templates/
│   └── ...
├── docker-compose.yml
├── .github/workflows/
│   ├── build.yml
│   └── pre-commit.yml
└── .pre-commit-config.yaml
```

## Image Directories

Each image has its own directory containing:

* `Dockerfile`
* Context-specific configuration
* Domain-specific dependencies

### Current images

* `datascience/` → General scientific and astronomy stack.
* `astronomy/` → Astronomy-focused stack.
* `solarsystem/` → Solar System–specific stack (extendable).


# Adding a New Image

To add a new image:

1. Create a new directory:

    ```
    newimage/
      Dockerfile
      environment.yml
    ```

2. Add the image to the matrix in `.github/workflows/build.yml`:

    ```yaml
    strategy:
      matrix:
        image:
          - name: datascience
            context: .
            file: datascience/Dockerfile
          - name: solarsystem
            context: .
            file: solarsystem/Dockerfile
          - name: newimage
            context: .
            file: newimage/Dockerfile
    ```

3. Commit and open a Pull Request.

The image will be built automatically on PR.


# Image Tagging Strategy

Each image is tagged with:

* `YYYY-MM-DD` → Build date
* `python-3.13` → Python major/minor version
* `<short-sha>` → Git commit short SHA
* `latest` → Only for `main` branch

Example:

```
linea/jupyter-datascience:2026-02-24
linea/jupyter-datascience:python-3.13
linea/jupyter-datascience:edd67e4
linea/jupyter-datascience:latest
```

# Reproducibility

* Once pushed to DockerHub, images are immutable.
* Tags are never rebuilt.
* A new build always generates new tags.
* Reproducibility is guaranteed by the published image, not by rebuilding old tags.

Never rebuild an existing tag.


# CI/CD Build Process

## Pull Request

* Builds images
* Does **not** push to DockerHub
* Validates Dockerfiles and dependencies

## Merge to `main`

* Builds images
* Pushes images to DockerHub
* Updates `latest` tag

## Manual Execution

You can manually trigger the workflow from:

GitHub → Actions → “Build and Push Jupyter Images” → Run workflow

Manual execution behaves like `main` (build + push).

---

# Adding or Updating Dependencies

Dependencies are declared per image in `environment.yml` and applied with `mamba env update` to keep Conda and pip resolution in a single transaction, reducing the risk of pip replacing or removing Conda-managed packages:

```dockerfile
COPY <image>/environment.yml /tmp/environment.yml
RUN mamba env update --name base -f /tmp/environment.yml && \
    mamba clean --all -f -y
RUN rm -rf /tmp/environment.yml
```

To add new libraries:

1. Edit `<image>/environment.yml`.
2. Put Conda/Mamba packages directly under `dependencies`.
3. Put pip-only packages under:

   ```yaml
    name: base
    channels:
      - conda-forge
      - defaults
    dependencies:
      # --- Database Access & Querying ---
      - psycopg2
      - sqlalchemy
      # --- Pip-only packages ---
      - pip
      - pip:
        - astrocut
   ```

4. Open a Pull Request.
5. Validate build in CI.

### Pip compatibility guidelines

* Prefer `conda-forge` packages when available; use `pip` only when a package is not available (or not viable) in Conda.
* Do not install the same package in both Conda and pip in the same image.
* Keep the `pip:` list inside `environment.yml` (instead of ad-hoc `pip install` lines) to preserve reproducibility.
* When adding pip-only packages that depend on compiled scientific stack, run a local image build to validate solver/runtime compatibility.

## Image Customization (Templates, AI Host, Welcome)

### 1) How to add notebook templates (`notebook-templates/`)

Templates are shared across images and must live in the repository root:

```
notebook-templates/
```

To expose templates inside an image, ensure the image Dockerfile includes:

```dockerfile
COPY notebook-templates/ /opt/notebook-templates/
RUN chown -R ${NB_UID}:users /opt/notebook-templates && \
    chmod -R a+rX /opt/notebook-templates
ENV JUPYTER_TEMPLATES_DIR=/opt/notebook-templates
```

And the server extension config:

```dockerfile
RUN printf '%s\n' '{' '  "ServerApp": {' '    "jpserver_extensions": {' '      "templates_menu": true' '    }' '  }' '}' > /opt/conda/etc/jupyter/jupyter_server_config.d/templates_menu.json
```

`chmod -R a+rX` is required so dynamic UIDs from JupyterHub/Kubernetes can read templates.

Important: use build context `.` in CI/local builds so `notebook-templates/` is available to `COPY`.

### 2) How and where to update `LINEA_HOST` for AI configuration

`LINEA_HOST` is defined in:

* `setup_ai/setup_ai_config.py`
* `setup_ai/linea_provider/src/linea_provider/provider.py`

Update this constant:

```python
LINEA_HOST = "http://your-host:11434"
```

Important: keep both files in sync. If you change `LINEA_HOST` in one place, update the other one to the same value.

This script is copied and executed during image build:

* `COPY setup_ai/setup_ai_config.py /tmp/setup_ai_config.py`
* `python3 /tmp/setup_ai_config.py`

It writes Jupyter AI settings (provider fields and aliases) into the user config at build/runtime setup.

### 3) How to update the welcome message per image

Each image should have its own welcome directory:

* `datascience/welcome/`
* `astronomy/welcome/`
* `solarsystem/welcome/`

Each directory should contain at least:

* `welcome.md`
* `image.png`

In each Dockerfile, stage welcome files under `/opt/linea-tutorials/`:

```dockerfile
COPY notebook-templates/ /opt/linea-tutorials/
COPY <image>/welcome/ /opt/linea-tutorials/
RUN chmod -R a+rX /opt/linea-tutorials/
RUN printf '#!/bin/bash\nmkdir -p "$HOME/notebooks/tutorials"\ncp -rn /opt/linea-tutorials/. "$HOME/notebooks/tutorials/"\n' \
    > /usr/local/bin/before-notebook.d/10-init-tutorials.sh && \
    chmod +x /usr/local/bin/before-notebook.d/10-init-tutorials.sh
RUN echo '{"ServerApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.md"},"LabApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.md"}}' > /opt/conda/etc/jupyter/jupyter_server_config.d/welcome.json
```

`before-notebook.d` is used because JupyterHub mounts the real user home over `/home/<username>` via PVC/NFS at spawn time.
The `cp -rn` keeps user files and edits untouched while ensuring missing tutorial files are created.
This makes JupyterLab open the welcome page by default without 404 on first launch.

---

# Local Build (Manual Test)

You can build locally using Docker:

```bash
DOCKER_BUILDKIT=1 docker build \
  -f datascience/Dockerfile \
  -t linea/jupyter-datascience:test \
  .
```

---

# Local Test with Docker Compose

Example:

```bash
docker compose up --build
```

Then access:

```
http://localhost:8888
```

---

# Running GitHub Actions Locally (act)

Requires:

* `act` installed
* `.secrets` file with:

```
DOCKERHUB_USERNAME=your_user
DOCKERHUB_TOKEN=your_token
```

## Run build workflow manually

```bash
act workflow_dispatch \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## Simulate Pull Request

```bash
act pull_request \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## Simulate Push to main

```bash
act push \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

---

# Pre-commit

Pre-commit runs automatically on Pull Requests.

To run locally before pushing:

```bash
pre-commit run --all-files
```

This ensures formatting and validation rules are respected before opening a PR.

---

# Summary

This repository provides:

* Versioned and reproducible JupyterHub images
* Parallel CI builds with caching
* Conditional push strategy (PR = build only, main = build + push)
* Manual execution via GitHub UI
* Local testing via Docker and act
* Pre-commit validation
