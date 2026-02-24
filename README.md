# jupyterhub-images


## Build manual da imagem

```bash
DOCKER_BUILDKIT=1 docker build \
  -f general/Dockerfile \
  -t linea/jupyter-datascience:$(git describe --always) \
  datascience
```


Testar todos os workflows

act workflow_dispatch \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest


Testar workflow especifico simulando pull request.

```bash
act pull_request \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

Testar workflow especifico simulando push em main

```bash
act push \
  -W .github/workflows/build.yml \
  --secret-file .secrets \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```
