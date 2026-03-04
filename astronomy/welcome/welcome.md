# Bem-vindo ao ambiente de Astronomia LineA

![Logo LineA](image.png)

Este é o seu ambiente Jupyter **Astronomy** preparado pela LineA. A imagem é baseada no [Jupyter Data Science Notebook](https://jupyter-docker-stacks.readthedocs.io/) (Python 3.13) e inclui o stack de astronomia, ferramentas de IA e extensões do JupyterLab.

## O que está disponível

- **Python 3.13** com o stack base de ciência de dados (NumPy, SciPy, pandas, Matplotlib, Seaborn, scikit-image, scikit-learn, Dask) e **pacotes de astronomia** instalados via mamba:
  - **Astropy**, **Astroquery**, **Healpy**, **Photutils**, **Regions**, **Reproject**
  - **HATS**, **hats-import**, **LSDB**, **PyVO**, **sbpy**, **ipyaladin** (Aladin)
  - **Dustmaps**, **Specutils**, **PySpecKit**, **SpiceyPy**, **Cartopy**
  - **Visualização**: Bokeh, HoloViews, hvplot, Datashader, Plotly
  - **Inferência e ML**: emcee, corner, dynesty, AstroML, lmfit

- **Pacotes adicionais (pip)**: astrocut, pyspac, lineassp, pzserver, rail, sora-astro.

- **Banco de dados**: cliente **PostgreSQL 18**, **psycopg** e **SQLAlchemy** para conectar e consultar bancos de dados.

- **Templates de notebooks**: menu de modelos de notebooks no JupyterLab (extensão linea-tutorials-menu) para começar rapidamente novos projetos.

- **Jupyter AI**: assistente de IA integrado ao Lab, com suporte a Google GenAI, OpenAI, Anthropic, Groq, DeepSeek e ao provedor customizado LineA (aliases coder05, coder1b, coder3b, coder7b).

- **Desenvolvimento e produtividade**:
  - **Git** (jupyterlab-git), **LSP** e **python-lsp-server**, **Jupytext**
  - **Black** e **isort** com **jupyterlab-code-formatter**
  - **jupyterlab_execute_time**, **jupyter-resource-usage**
  - **jupyterlab-spreadsheet-editor**, **ipyvolume**

Use o menu **Templates** para criar novos notebooks e o painel de **IA** para assistência no Lab.

Bom trabalho!
