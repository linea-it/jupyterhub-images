# O painel XFCE chama Logout/Shutdown/Restart via D-Bus (org.xfce.Session.Manager), não só o binário
# xfce4-session-logout — esconder botões não impede o fim da sessão X / TigerVNC.
# Recompilar xfce4-session com patch em xfsm-manager.c (Ubuntu 4.18.3-1build2).
FROM ubuntu:24.04 AS linea-xfce4-session-build
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      dpkg-dev \
      devscripts \
      fakeroot \
      wget && \
    apt-get build-dep -y xfce4-session
WORKDIR /build
ARG XFCE_SESSION_ORIG_URL=http://archive.ubuntu.com/ubuntu/pool/universe/x/xfce4-session/xfce4-session_4.18.3.orig.tar.bz2
ARG XFCE_SESSION_DEBIAN_URL=http://archive.ubuntu.com/ubuntu/pool/universe/x/xfce4-session/xfce4-session_4.18.3-1build2.debian.tar.xz
RUN wget -q -O xfce4-session.orig.tar.bz2 "${XFCE_SESSION_ORIG_URL}" && \
    wget -q -O xfce4-session.debian.tar.xz "${XFCE_SESSION_DEBIAN_URL}" && \
    tar xjf xfce4-session.orig.tar.bz2 && \
    cd xfce4-session-4.18.3 && \
    tar xJf ../xfce4-session.debian.tar.xz
COPY iraf/assets/patches/xfce4-session-linea-no-remote-session-end.patch /build/linea.patch
RUN cd /build/xfce4-session-4.18.3 && \
    patch -p0 < /build/linea.patch && \
    DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -uc -us -j"$(nproc)"
RUN cp "/build/xfce4-session_4.18.3-1build2_$(dpkg --print-architecture).deb" /build/linea-xfce4-session.deb

FROM quay.io/jupyter/minimal-notebook:python-3.13

USER root

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

# IRAF build deps: https://github.com/iraf-community/iraf/blob/main/INSTALL.md
# X11 / VNC / XFCE for jupyter-remote-desktop-proxy
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    bison \
    flex \
    zlib1g-dev \
    libreadline-dev \
    perl \
    libncurses6 \
    libtinfo6 \
    libx11-6 \
    libx11-dev \
    tcsh \
    wget \
    curl \
    make \
    gcc \
    libc6-dev \
    libcurl4 \
    x11-apps \
    xterm \
    xdotool \
    mesa-utils \
    libgl1 \
    dbus-x11 \
    adwaita-icon-theme \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    tigervnc-standalone-server \
    xgterm \
    saods9 \
    xpa-tools \
    xfonts-terminus \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# OpenSSL 3 (base Jupyter): servidores DSS/catálogos legados podem falhar com SECLEVEL=2 (handshake).
# O openssl.cnf da imagem não traz CipherString @SECLEVEL; define-se via ssl_conf em [openssl_init].
RUN sed -i '/^\[openssl_init\]$/a ssl_conf = linea_ssl_sect' /etc/ssl/openssl.cnf && \
    printf '%s\n' '' '# LIneA: TLS legado para DS9/DSS e serviços astronómicos antigos' \
      '[linea_ssl_sect]' 'system_default = linea_system_default_sect' '' \
      '[linea_system_default_sect]' 'CipherString = DEFAULT:@SECLEVEL=0' >> /etc/ssl/openssl.cnf && \
    grep -q 'ssl_conf = linea_ssl_sect' /etc/ssl/openssl.cnf && \
    grep -q 'CipherString = DEFAULT:@SECLEVEL=0' /etc/ssl/openssl.cnf

COPY --from=linea-xfce4-session-build /build/linea-xfce4-session.deb /tmp/linea-xfce4-session.deb
RUN dpkg -i /tmp/linea-xfce4-session.deb && rm -f /tmp/linea-xfce4-session.deb

# XFCE (UX): xfconf + .desktop — complementam o patch D-Bus; não substituem-no.
COPY iraf/assets/xfce-perchannel-xml/xfce4-session.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
RUN chmod 644 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
COPY iraf/assets/xfce-perchannel-xml/xfce4-desktop.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
RUN chmod 644 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY iraf/assets/applications/xfce4-session-logout.desktop /usr/local/share/applications/xfce4-session-logout.desktop
RUN chmod 644 /usr/local/share/applications/xfce4-session-logout.desktop

# Compilar e instalar IRAF Community em /usr/local
WORKDIR /opt
RUN git clone --depth 1 https://github.com/iraf-community/iraf.git && \
    cd iraf && \
    make -j4 && \
    make install

ENV iraf=/usr/local/lib/iraf/

# Arquivos auxiliares IRAF (scripts, ícones, configs desktop); welcome dos tutoriais vem de jupyterhub-tutorial + default_url abaixo
# login.cl com uparm -> $HOME/iraf/uparm/ (evita uparm$pipe em ~/.iraf/uparm/ em PVC)
RUN mkdir -p /opt/linea-iraf
COPY iraf/assets/login.cl /opt/linea-iraf/login.cl
COPY iraf/assets/iraf.png /opt/linea-iraf/iraf.png
COPY iraf/assets/SAOImageDS9.png /opt/linea-iraf/SAOImageDS9.png
RUN chmod 644 /opt/linea-iraf/login.cl /opt/linea-iraf/iraf.png /opt/linea-iraf/SAOImageDS9.png

COPY iraf/assets/linea-ds9-cl-inner.sh /usr/local/bin/linea-ds9-cl-inner.sh
RUN chmod 755 /usr/local/bin/linea-ds9-cl-inner.sh

# Modelo do lançador na área de trabalho (copiado para ~/Desktop no before-notebook.d)
COPY iraf/assets/linea-ds9-cl.desktop /opt/linea-iraf/linea-ds9-cl.desktop
RUN chmod 644 /opt/linea-iraf/linea-ds9-cl.desktop

# DS9 sozinho (ícone PNG em /opt/linea-iraf; o SVG do apt falha em alguns renderizadores do desktop)
COPY iraf/assets/linea-saods9.desktop /opt/linea-iraf/linea-saods9.desktop
RUN chmod 644 /opt/linea-iraf/linea-saods9.desktop

# Entrada no menu de aplicativos (XFCE)
COPY iraf/assets/linea-ds9-cl.desktop /usr/local/share/applications/linea-ds9-cl.desktop
RUN chmod 644 /usr/local/share/applications/linea-ds9-cl.desktop

COPY iraf/assets/linea-terminal.desktop /opt/linea-iraf/linea-terminal.desktop
COPY iraf/assets/linea-xterm.desktop /opt/linea-iraf/linea-xterm.desktop
RUN chmod 644 /opt/linea-iraf/linea-terminal.desktop /opt/linea-iraf/linea-xterm.desktop
COPY iraf/assets/linea-terminal.desktop /usr/local/share/applications/linea-terminal.desktop
COPY iraf/assets/linea-xterm.desktop /usr/local/share/applications/linea-xterm.desktop
RUN chmod 644 /usr/local/share/applications/linea-terminal.desktop /usr/local/share/applications/linea-xterm.desktop

# xfce4-panel (Applications, workspaces, etc.) permanece visível — sem autohide no VNC

# Desktop XFCE/VNC: impedir logout de sessão (utilizador pode não voltar ao desktop)
COPY iraf/assets/xfce-logout-disabled.sh /opt/linea-iraf/scripts/xfce-logout-disabled.sh
RUN chmod 755 /opt/linea-iraf/scripts/xfce-logout-disabled.sh && \
    dpkg-divert --quiet --add --rename --divert /usr/bin/xfce4-session-logout.distrib /usr/bin/xfce4-session-logout && \
    ln -sf /opt/linea-iraf/scripts/xfce-logout-disabled.sh /usr/bin/xfce4-session-logout
COPY iraf/assets/linea-xfce-hide-logout.sh /opt/linea-iraf/scripts/linea-xfce-hide-logout.sh
RUN chmod 755 /opt/linea-iraf/scripts/linea-xfce-hide-logout.sh
COPY iraf/assets/linea-xfce-hide-logout.desktop /etc/xdg/autostart/linea-xfce-hide-logout.desktop
RUN chmod 644 /etc/xdg/autostart/linea-xfce-hide-logout.desktop

COPY iraf/assets/set-linea-desktop-bg.sh /opt/linea-iraf/scripts/set-linea-desktop-bg.sh
RUN chmod 755 /opt/linea-iraf/scripts/set-linea-desktop-bg.sh
COPY iraf/assets/linea-desktop-bg.desktop /etc/xdg/autostart/linea-desktop-bg.desktop
RUN chmod 644 /etc/xdg/autostart/linea-desktop-bg.desktop

# Tutoriais LIneA (igual astronomy: staging /opt/linea-tutorials + /opt/notebook-templates sem welcome.html)
# Sincronizados para $HOME via before-notebook.d; fetch em runtime usa TUTORIALS_REPO / TUTORIALS_BRANCH
ARG TUTORIALS_REPO=https://github.com/linea-it/jupyterhub-tutorial
ARG TUTORIALS_BRANCH=main
ENV TUTORIALS_REPO=${TUTORIALS_REPO}
ENV TUTORIALS_BRANCH=${TUTORIALS_BRANCH}
RUN mkdir -p /opt/linea-tutorials /opt/notebook-templates && \
    curl -fsSL "${TUTORIALS_REPO}/archive/refs/heads/${TUTORIALS_BRANCH}.tar.gz" \
    | tar xz --strip-components=2 -C /opt/linea-tutorials/ \
        "jupyterhub-tutorial-${TUTORIALS_BRANCH}/tutorials/" && \
    cp -a /opt/linea-tutorials/. /opt/notebook-templates/ && \
    rm -f /opt/notebook-templates/welcome.html && \
    chmod -R a+rX /opt/linea-tutorials /opt/notebook-templates

# Scripts de inicialização (before-notebook.d): executados antes do Jupyter subir, com o
# usuário real (que pode ser reatribuído pelo KubeSpawner).
COPY scripts/before-notebook.d/10-init-tutorials.sh /usr/local/bin/before-notebook.d/
COPY scripts/before-notebook.d/20-init-iraf.sh      /usr/local/bin/before-notebook.d/
RUN chmod +x /usr/local/bin/before-notebook.d/*.sh

# default_url via json config (mais alta prioridade que jupyter_server_config.py)
RUN echo '{"ServerApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.html"},"LabApp":{"default_url":"/lab/tree/notebooks/tutorials/welcome.html"}}' > /opt/conda/etc/jupyter/jupyter_server_config.d/welcome.json
ENV NOTEBOOK_ARGS="--ContentsManager.allow_hidden=True --ServerApp.default_url=/lab/tree/notebooks/tutorials/welcome.html --LabApp.default_url=/lab/tree/notebooks/tutorials/welcome.html"
# Abrir todos os .md com Markdown Preview (renderizado) em vez do editor de texto
RUN LAB_SETTINGS="/opt/conda/share/jupyter/lab/settings" && \
    mkdir -p "${LAB_SETTINGS}" && \
    echo '{"@jupyterlab/docmanager-extension:plugin":{"defaultViewers":{"markdown":"Markdown Preview"}}}' > "${LAB_SETTINGS}/overrides.json" && \
    chown -R ${NB_UID}:users "${LAB_SETTINGS}"

# Conveniência: iraf-cl abre o CL com TERM=xgterm (gráficos Tek no desktop XFCE/VNC)
COPY iraf/assets/iraf-cl /usr/local/bin/iraf-cl
RUN chmod +x /usr/local/bin/iraf-cl

COPY iraf/assets/test-iraf-cl.sh /usr/local/bin/test-iraf-cl
RUN chmod +x /usr/local/bin/test-iraf-cl

# Dependências Python (JupyterLab, astro, pyraf, desktop proxy)
COPY iraf/environment.yml /tmp/environment.yml
RUN conda env update --name base -f /tmp/environment.yml && \
    conda clean --all -f -y && \
    rm /tmp/environment.yml

# Extensão Jupyter templates_menu (LIneA), alinhada às outras imagens
ARG WHEEL_URL=https://github.com/linea-it/jupyterhub-templates/releases/download/v0.1.0/templates_menu-0.1.0-py3-none-any.whl
USER root
RUN chown -R "${NB_UID}:users" /opt/notebook-templates
RUN curl -f -L -o /tmp/templates_menu-0.1.0-py3-none-any.whl "${WHEEL_URL}" \
    && python3 -c "import zipfile; zipfile.ZipFile('/tmp/templates_menu-0.1.0-py3-none-any.whl')" \
    || (echo "Downloaded file is not a valid wheel. Verifique WHEEL_URL e se o release/asset existem e são públicos." && exit 1)
USER ${NB_UID}
RUN pip install --no-cache-dir /tmp/templates_menu-0.1.0-py3-none-any.whl
USER root
RUN rm -f /tmp/templates_menu-0.1.0-py3-none-any.whl
RUN printf '%s\n' '{' '  "ServerApp": {' '    "jpserver_extensions": {' '      "templates_menu": true' '    }' '  }' '}' > /opt/conda/etc/jupyter/jupyter_server_config.d/templates_menu.json
ENV JUPYTER_TEMPLATES_DIR=/opt/notebook-templates

# Jupyter AI (igual astronomy|datascience|solarsystem)
USER ${NB_UID}
RUN pip install --no-cache-dir "jupyter-ai<3" \
    langchain-google-genai \
    langchain-openai \
    langchain-anthropic \
    langchain-groq \
    langchain-deepseek
USER root
COPY setup_ai/linea_provider/ /tmp/linea_provider/
COPY setup_ai/setup_ai_config.py /tmp/setup_ai_config.py
COPY setup_ai/15-init-jupyter-ai.sh /tmp/15-init-jupyter-ai.sh
RUN chown -R "${NB_UID}:users" /tmp
USER ${NB_UID}
RUN jupyter lab --generate-config && \
    pip install /tmp/linea_provider/ && \
    python3 /tmp/setup_ai_config.py
USER root
RUN chmod +x /tmp/15-init-jupyter-ai.sh && mv /tmp/15-init-jupyter-ai.sh /usr/local/bin/before-notebook.d/ && \
    rm -rf /tmp/linea_provider/ /tmp/setup_ai_config.py

# Extensão leve: tempo por célula (útil para tarefas IRAF/PyRAF lentas)
RUN pip install --no-cache-dir jupyterlab_execute_time

# Título e ícone do launcher do desktop remoto no JupyterLab (evita duplicar desktop-websockify)
COPY iraf/assets/jupyter_server_config.py /opt/conda/etc/jupyter/jupyter_server_config.py
RUN chmod 644 /opt/conda/etc/jupyter/jupyter_server_config.py

# Barra superior da UI /desktop/ (jupyter-remote-desktop-proxy): símbolo LIneA + gradiente
COPY iraf/assets/remote-desktop/linea-desktop-topbar.css /tmp/linea-rdp/linea-desktop-topbar.css
COPY iraf/assets/linea-symbol.svg /tmp/linea-rdp/linea-symbol.svg
COPY iraf/assets/remote-desktop/index.html /tmp/linea-rdp/index.html
RUN RDP="$(/opt/conda/bin/python -c 'import jupyter_remote_desktop_proxy as p, os; print(os.path.dirname(p.__file__))')" && \
    cp /tmp/linea-rdp/linea-desktop-topbar.css "${RDP}/static/linea-desktop-topbar.css" && \
    cp /tmp/linea-rdp/linea-symbol.svg "${RDP}/static/jupyter-logo.svg" && \
    cp /tmp/linea-rdp/index.html "${RDP}/templates/index.html" && \
    chmod 644 "${RDP}/static/linea-desktop-topbar.css" "${RDP}/static/jupyter-logo.svg" "${RDP}/templates/index.html" && \
    rm -rf /tmp/linea-rdp

# Snippet no .bashrc do usuário padrão (export USER, iraf)
COPY iraf/assets/bashrc-snippet /tmp/bashrc-iraf.snippet
RUN cat /tmp/bashrc-iraf.snippet >> /home/jovyan/.bashrc && \
    chown "${NB_UID}:users" /home/jovyan/.bashrc && \
    rm -f /tmp/bashrc-iraf.snippet

# Algumas camadas (conda/pip/build) podem criar ~/.iraf como root; o CL precisa
# escrever em ~/.iraf/uparm. O before-notebook.d recria tudo como o usuário real.
RUN rm -rf /home/jovyan/.iraf /home/jovyan/iraf /home/jovyan/login.cl 2>/dev/null || true

# remoção de binários desnecessários (segurança)
USER root
RUN rm -f \
    /usr/sbin/chroot \
    /usr/bin/unshare \
    /usr/bin/nsenter

USER ${NB_USER}
WORKDIR ${HOME}
