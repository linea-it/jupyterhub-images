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
│   └── environment.yml
├── astronomy/
│   ├── Dockerfile
│   └── environment.yml
├── solarsystem/
│   ├── Dockerfile
│   └── environment.yml
├── scripts/
│   └── before-notebook.d/
│       └── 10-init-tutorials.sh
├── setup_ai/
│   └── ...
├── docker-compose.yml
├── .github/workflows/
│   ├── build.yml
│   ├── build-manual.yml
│   └── pre-commit.yml
└── .pre-commit-config.yaml
```

Tutorials (welcome message and notebook templates) are downloaded during Docker build from [linea-it/jupyterhub-tutorial](https://github.com/linea-it/jupyterhub-tutorial). At container start, `scripts/before-notebook.d/10-init-tutorials.sh` (installed under `/usr/local/bin/before-notebook.d/`) may refresh that content from the network and always syncs tutorials into the user’s home (see below).

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

2. Mirror the tutorial hooks from an existing `Dockerfile`: download tutorials at build time and `COPY scripts/before-notebook.d/10-init-tutorials.sh` into `/usr/local/bin/before-notebook.d/` (see any current image `Dockerfile`).

3. Add the image to the matrix in `.github/workflows/build.yml`:

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

4. Commit and open a Pull Request.

The image will be built automatically on PR.


# Image Tagging Strategy

## Automatic workflow ([`build.yml`](.github/workflows/build.yml))

On **push to `main`**, each image is pushed with:

* `YYYY-MM-DD` → Build date
* `python-3.13` → Python major/minor version
* `<short-sha>` → Git commit short SHA
* `latest`

Example:

```
linea/jupyter-datascience:2026-02-24
linea/jupyter-datascience:python-3.13
linea/jupyter-datascience:edd67e4
linea/jupyter-datascience:latest
```

## Manual workflow ([`build-manual.yml`](.github/workflows/build-manual.yml))

Pushes **only** `<short-sha>` for the selected image(s). It does **not** update `latest`, the date tag, or the Python tag—use this when you need a one-off or selective publish from the UI without going through `main`.

# Reproducibility

* Once pushed to DockerHub, images are immutable.
* Tags are never rebuilt.
* A new build always generates new tags.
* Reproducibility is guaranteed by the published image, not by rebuilding old tags.

Never rebuild an existing tag.


# CI/CD Build Process

There are **two** workflows. Both use Docker Buildx and GitHub Actions cache (`type=gha`, `mode=max`), and push to `linea/jupyter-<image>` when publishing.

## 1) Automatic — [`build.yml`](.github/workflows/build.yml) (“Build and Push Jupyter Images”)

### Triggers

* **`pull_request`** — every pull request (any branch).
* **`push`** — only when commits land on **`main`**.

### Behaviour

* **Matrix** over `datascience`, `astronomy`, and `solarsystem` (one parallel job per image).
* **On PR:** build only (`push: false`); tags are computed locally (date, Python tag, short SHA) but nothing is sent to Docker Hub.
* **On push to `main`:** login to Docker Hub, then build and push the full tag set including **`latest`** (see [Image Tagging Strategy](#image-tagging-strategy)).

## 2) Manual — [`build-manual.yml`](.github/workflows/build-manual.yml) (“Build and Push (manual)”)

### Trigger

* **`workflow_dispatch`** only — start from GitHub → Actions → **“Build and Push (manual)”** → **Run workflow**.

### Inputs

* **`image`** — `all`, or a single image: `datascience`, `astronomy`, `solarsystem`.

### Behaviour

* A **`setup`** job builds the matrix JSON (all three images or just the one you picked); the **`build`** job runs `fromJson` on that output.
* Always **logs in** and **pushes** to Docker Hub.
* Publishes **only** the `: <short-sha>` tag per built image (no `latest`, no date, no `python-*` tag)—see [Image Tagging Strategy](#image-tagging-strategy).

Use this when you need to rebuild and push a subset of images (or all) from the default branch **without** merging or without refreshing `latest`/dated tags the way `main` does.

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

### 1) Tutorials and notebook templates

Tutorials (including the welcome message and notebook templates) are **not stored in this repository**. They are downloaded at build time from:

**https://github.com/linea-it/jupyterhub-tutorial** (branch `main`, directory `tutorials/`)

To update the welcome message or notebook templates, edit the content in that repository.

Each Dockerfile downloads the tutorials using a tarball:

```dockerfile
ARG TUTORIALS_REPO=https://github.com/linea-it/jupyterhub-tutorial
ARG TUTORIALS_BRANCH=main
RUN mkdir -p /opt/linea-tutorials /opt/notebook-templates && \
    curl -fsSL "${TUTORIALS_REPO}/archive/refs/heads/${TUTORIALS_BRANCH}.tar.gz" \
    | tar xz --strip-components=2 -C /opt/linea-tutorials/ \
        "jupyterhub-tutorial-${TUTORIALS_BRANCH}/tutorials/" && \
    cp -a /opt/linea-tutorials/. /opt/notebook-templates/ && \
    rm -f /opt/notebook-templates/welcome.html && \
    chmod -R a+rX /opt/linea-tutorials /opt/notebook-templates
```

The build ARGs `TUTORIALS_REPO` and `TUTORIALS_BRANCH` allow overriding the source repository or branch at build time:

```bash
docker build --build-arg TUTORIALS_BRANCH=develop -f datascience/Dockerfile -t test .
```

Files are placed in two locations:
* `/opt/linea-tutorials/` — all content (welcome.html + notebooks), copied to `$HOME/notebooks/tutorials/` at runtime via `before-notebook.d`
* `/opt/notebook-templates/` — notebooks only (no welcome.html), used by the `templates_menu` JupyterLab extension

#### Runtime hook: `scripts/before-notebook.d/10-init-tutorials.sh`

Each image copies this script to `/usr/local/bin/before-notebook.d/10-init-tutorials.sh` so the [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/) entrypoint runs it before the notebook server starts.

The script:

1. Downloads the same tutorials tarball used at build time (`curl` with short connect/read timeouts).
2. On success, if `/opt/linea-tutorials` is writable (typical when the process runs as root in the container), it replaces `/opt/linea-tutorials` and `/opt/notebook-templates` with the fresh extract (still removing `welcome.html` from the templates tree).
3. On failure (offline, timeout, etc.), it uses the tutorials already baked into the image under `/opt/linea-tutorials`.
4. Syncs the chosen source into `$HOME/notebooks/tutorials` with `cp -rn` so only missing files are added and user edits are never overwritten.
5. If running as root, adjusts ownership of `$HOME/notebooks/tutorials` to match the mounted home; applies user-writable permissions.

Runtime overrides (same semantics as the Docker build args):

* `TUTORIALS_REPO` — default `https://github.com/linea-it/jupyterhub-tutorial`
* `TUTORIALS_BRANCH` — default `main`

Example:

```bash
docker run -e TUTORIALS_BRANCH=develop …
```

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

### 3) How to update the welcome message

The welcome message (`welcome.html`) is maintained in the [linea-it/jupyterhub-tutorial](https://github.com/linea-it/jupyterhub-tutorial) repository under `tutorials/welcome.html`. All images share the same welcome message.

To update it, edit the file in that repository. Changes will take effect on the next Docker image build.

At runtime, `10-init-tutorials.sh` in `before-notebook.d` runs because JupyterHub mounts the real user home over `/home/<username>` via PVC/NFS at spawn time.
The `cp -rn` keeps user files and edits untouched while ensuring missing tutorial files are created.
The script also enforces writable permissions (`u+rwX`) and, when running as root, aligns ownership with the mounted home owner.
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

Which file to simulate:

* **`build.yml`** — `pull_request` and `push` to `main` (first two commands below).
* **`build-manual.yml`** — `workflow_dispatch` (third command); use `--input image=…` with `all`, `datascience`, `astronomy`, or `solarsystem`.

## Simulate pull request (`build.yml`)

```bash
act pull_request \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## Simulate push to `main` (`build.yml`)

Same as a merge to `main`: login and full tag push including `latest`.

```bash
act push \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## Simulate manual dispatch (`build-manual.yml`)

Pushes only the short-SHA tag for the chosen scope (mirrors the GitHub “Run workflow” form).

```bash
act workflow_dispatch \
  -W .github/workflows/build-manual.yml \
  --input image=all \
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
* Shared startup scripts under `scripts/before-notebook.d/` (tutorial fetch/sync at container start)
* Parallel CI builds with caching
* Conditional push strategy (PR = build only, main = build + push)
* Automatic CI (`build.yml`) on PRs and pushes to `main`, plus optional manual builds (`build-manual.yml`)
* Local testing via Docker and act
* Pre-commit validation
