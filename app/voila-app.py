import os
from voila.app import main

debug = os.environ.get('VOILA_DEBUG', 'false').lower() == 'true'
debug_args = [] if not debug else [
    "--autoreload=true",
    "--debug",
]
main(argv=[
    "--enable_nbextensions=True",
    "--no-browser",
    "--Voila.ip=0.0.0.0",
    # Custom template
    "--template=customvoila",
    # Allow JS and other content files to be served.
    "--VoilaConfiguration.file_whitelist=.*\\.(pdf|js|html|css|json|ttf|woff|woff2|md|png|svg|ico)$",
    # Every 60 seconds, cull potentially busy but disconnected kernels
    # that have been idle for 120 seconds.
    "--MappingKernelManager.cull_interval=60",
    "--MappingKernelManager.cull_idle_timeout=120",
    "--MappingKernelManager.cull_busy=true",
    "--MappingKernelManager.cull_connected=false",
    # Allow up to 100MB to be uploaded (100 * 1024 * 1024 bytes)
    # (https://github.com/jupyter-widgets/ipywidgets/issues/2522#issuecomment-516434947).
    "--Voila.tornado_settings={\"websocket_max_message_size\": 104857600}",
    *debug_args,
    "notebooks/voila",
])
