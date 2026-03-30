<img align="left" src="image.png" width="120" style="padding: 20px">
<img align="left" src="https://jupyter.org/assets/homepage/hublogo.svg" width="250" style="padding: 20px">

<div style="clear: both;"></div>

# Bem-vindo ao LIneA JupyterHub 👋  

O JupyterHub é um ambiente de desenvolvimento multiusuário baseado em *Jupyter Notebooks*. Aqui, você pode programar, analisar dados e visualizar resultados diretamente no navegador, sem precisar instalar ou configurar nada no seu computador.  

Como parte da LIneA Science Platform, ele é ideal para:  
- desenvolver software científico  
- explorar e analisar conjuntos de dados menores  
- realizar processamentos leves  
- visualizar e compartilhar resultados  

Se você precisar de mais poder computacional ou trabalhar com grandes volumes de dados (*big data*), entre em contato pelo e-mail helpdesk@linea.org.br para solicitar acesso ao ambiente de HPC, disponibilizado por meio do [Open OnDemand](https://ondemand.linea.org.br/).  


## O que está disponível

O JupyterHub está disponível em duas opções (imagens Docker), que variam de acordo com as bibliotecas e extensões previamente instaladas:  

* **Data Science** – o stack [Jupyter Data Science Notebook](https://jupyter-docker-stacks.readthedocs.io/), incluindo bibliotecas populares de *data science* como Pandas, NumPy, Matplotlib, SciPy e Scikit-learn.  
* **Astronomy** – o stack de astronomia, que inclui as principais bibliotecas de *data science* mais as bibliotecas mais utilizadas na área, como Astropy, Astroquery, Healpy, Photutils, PyVO, Dustmaps, LSDB, AstroML, entre outras.  

Para acessar a lista completa de bibliotecas e suas respectivas versões disponíveis por padrão, abra um Terminal e execute:  

```bash
$ pip list
```

Caso não encontre uma biblioteca essencial para o seu trabalho, ou precise utilizar versões específicas diferentes das padrão, também é possível criar ambientes customizados utilizando Conda ou Mamba.

## Jupyter AI

Ambas as imagens incluem um assistente de IA integrado ao JupyterLab, com suporte a Google GenAI, OpenAI, Anthropic, Groq, DeepSeek e ao provedor customizado LIneA (aliases coder05, coder1b, coder3b, coder7b). Para acessá-lo, clique no ícone de chat no menu vertical à esquerda.  


## Tutorial Notebooks  

👈 Acesse uma das opções de notebook tutorial:  

* `PT-BR-jupyterhub-tutorial.ipynb` em português brasileiro  
* `EN-jupyterhub-tutorial.ipynb` em inglês  
* `ES-jupyterhub-tutorial.ipynb` em espanhol  

para aprender como:  

* utilizar um Jupyter Notebook (caso seja iniciante)  
* acessar os dados hospedados no LIneA diretamente a partir de um notebook  
* customizar o seu ambiente  


Bom trabalho! 🚀  