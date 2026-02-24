# jupyterhub-images


## Build manual da imagem

```bash
DOCKER_BUILDKIT=1 docker build \
  -f general/Dockerfile \
  -t linea/jupyter-general:$(git describe --always) \
  .


```
