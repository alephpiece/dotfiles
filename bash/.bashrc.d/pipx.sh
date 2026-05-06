# shellcheck shell=bash
# pipx
export PATH="$PATH:$HOME/.local/bin"
command -v register-python-argcomplete &>/dev/null \
    && eval "$(register-python-argcomplete pipx)"
