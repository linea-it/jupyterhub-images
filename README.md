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
│   └── Dockerfile
├── solarsystem/
│   └── Dockerfile
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
* `solarsystem/` → Solar System–specific stack (extendable).


# Adding a New Image

To add a new image:

1. Create a new directory:

    ```
    newimage/
      Dockerfile
    ```

2. Add the image to the matrix in `.github/workflows/build.yml`:

    ```yaml
    strategy:
      matrix:
        image:
          - name: datascience
            context: datascience
          - name: solarsystem
            context: solarsystem
          - name: newimage
            context: newimage
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

To add new libraries:

1. Edit the appropriate `Dockerfile`.
2. Add:

   * System dependencies under `USER root`
   * Conda packages using `mamba`
   * Pip packages using `pip install`
3. Open a Pull Request.
4. Validate build in CI.

### Best Practices

* Install conda packages before pip packages.
* Clean mamba cache:

  ```
  mamba clean --all -f -y
  ```
* Avoid modifying existing image tags.

---

# Local Build (Manual Test)

You can build locally using Docker:

```bash
DOCKER_BUILDKIT=1 docker build \
  -f datascience/Dockerfile \
  -t linea/jupyter-datascience:test \
  datascience
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
