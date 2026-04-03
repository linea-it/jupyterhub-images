# Carregado cedo pelo Jupyter Server (antes das extensões).
# Personaliza título e ícone do launcher do desktop remoto (jupyter-remote-desktop-proxy).

def _linea_iraf_remote_desktop_launcher():
    import jupyter_remote_desktop_proxy.setup_websockify as m

    _orig = m.setup_websockify

    def _wrapped():
        cfg = _orig()
        le = cfg.setdefault("launcher_entry", {})
        le["title"] = "LIneA IRAF Desktop"
        le["icon_path"] = "/opt/linea-iraf/iraf.png"
        return cfg

    m.setup_websockify = _wrapped


_linea_iraf_remote_desktop_launcher()
