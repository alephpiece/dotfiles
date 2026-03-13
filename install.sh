#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="https://github.com/alephpiece/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# ── Versions ──────────────────────────────────────────────────────────────────
STARSHIP_VER=1.24.2
FD_VER=10.4.2
RG_VER=15.1.0

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo ">>> $*"; }
ok()  { echo "✓  $*"; }

# ── Options ───────────────────────────────────────────────────────────────────
DO_BIN=true
DO_CONF=true

usage() {
  echo "Usage: install.sh [--all | --bin | --conf]"
  echo "  --all   Install binaries and apply configs (default)"
  echo "  --bin   Install binaries only"
  echo "  --conf  Apply configs only (clone/pull + stow)"
  exit 0
}

case "${1:-}" in
  --all)  DO_BIN=true;  DO_CONF=true  ;;
  --bin)  DO_BIN=true;  DO_CONF=false ;;
  --conf) DO_BIN=false; DO_CONF=true  ;;
  --help) usage ;;
  "")     ;;  # default: --all
  *)      echo "Unknown option: $1"; usage ;;
esac


# ── Binaries ──────────────────────────────────────────────────────────────────
if $DO_BIN; then

  # 1. Base tools ──────────────────────────────────────────────────────────────
  _base_pkgs=(tmux less curl git stow python3-pip)
  _missing=()
  for pkg in "${_base_pkgs[@]}"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" || _missing+=("$pkg")
  done

  if (( ${#_missing[@]} > 0 )); then
    log "Installing base tools: ${_missing[*]}..."
    sudo apt-get update -q
    sudo apt-get install -y "${_missing[@]}"
    ok "Base tools"
  else
    ok "Base tools already installed"
  fi

  # 2. Starship ────────────────────────────────────────────────────────────────
  if ! command -v starship &>/dev/null \
      || [[ "$(starship --version | awk '{print $2}')" != "${STARSHIP_VER}" ]]; then
    log "Installing starship ${STARSHIP_VER}..."
    curl -fL --progress-bar \
      "https://github.com/starship/starship/releases/download/v${STARSHIP_VER}/starship-x86_64-unknown-linux-musl.tar.gz" \
      -o /tmp/starship.tar.gz
    sudo tar -xzof /tmp/starship.tar.gz -C /usr/local/bin
    ok "Starship"
  else
    ok "Starship already up-to-date (${STARSHIP_VER})"
  fi

  # 3. pipx ────────────────────────────────────────────────────────────────────
  if ! command -v pipx &>/dev/null; then
    log "Installing pipx..."
    pip3 install --user pipx
    ~/.local/bin/pipx ensurepath
    ok "pipx"
  else
    ok "pipx already installed"
  fi

  # 4. fzf ─────────────────────────────────────────────────────────────────────
  if [ ! -d ~/.fzf ]; then
    log "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  fi
  ~/.fzf/install --all --no-update-rc
  ok "fzf"

  # 5. fd ──────────────────────────────────────────────────────────────────────
  _fd_cur=""
  command -v fd &>/dev/null && _fd_cur=$(fd --version | awk '{print $2}')
  if [[ -z "$_fd_cur" ]] || dpkg --compare-versions "$_fd_cur" lt "$FD_VER"; then
    log "Installing fd ${FD_VER}..."
    curl -fL --progress-bar \
      "https://github.com/sharkdp/fd/releases/download/v${FD_VER}/fd_${FD_VER}_amd64.deb" \
      -o /tmp/fd.deb
    sudo apt-get install -y /tmp/fd.deb
    mkdir -p ~/.local/share/bash-completion/completions
    fd --gen-completions bash > ~/.local/share/bash-completion/completions/fd
    ok "fd"
  elif [[ "$_fd_cur" == "$FD_VER" ]]; then
    ok "fd already up-to-date (${FD_VER})"
  else
    ok "fd already newer (${_fd_cur}), skipping"
  fi

  # 6. ripgrep ─────────────────────────────────────────────────────────────────
  _rg_cur=""
  command -v rg &>/dev/null && _rg_cur=$(rg --version | head -1 | awk '{print $2}')
  if [[ -z "$_rg_cur" ]] || dpkg --compare-versions "$_rg_cur" lt "$RG_VER"; then
    log "Installing ripgrep ${RG_VER}..."
    curl -fL --progress-bar \
      "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep_${RG_VER}-1_amd64.deb" \
      -o /tmp/ripgrep.deb
    sudo apt-get install -y /tmp/ripgrep.deb
    ok "ripgrep"
  elif [[ "$_rg_cur" == "$RG_VER" ]]; then
    ok "ripgrep already up-to-date (${RG_VER})"
  else
    ok "ripgrep already newer (${_rg_cur}), skipping"
  fi

  # 7. vim-plug ────────────────────────────────────────────────────────────────
  PLUG_PATH=~/.vim/autoload/plug.vim
  if [ ! -f "${PLUG_PATH}" ]; then
    log "Installing vim-plug..."
    curl -fLo "${PLUG_PATH}" --create-dirs --progress-bar \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug"
  else
    ok "vim-plug already installed"
  fi
  log "Running :PlugInstall..."
  vim +PlugInstall +qall < /dev/tty
  ok "Vim plugins"

  # 8. .bashrc.d loader ────────────────────────────────────────────────────────
  log "Patching ~/.bashrc with .bashrc.d loader..."
  LOADER='for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && source "$f"; done'
  grep -qxF "$LOADER" ~/.bashrc || echo "$LOADER" >> ~/.bashrc
  ok ".bashrc loader"

fi  # DO_BIN


# ── Configs ───────────────────────────────────────────────────────────────────
if $DO_CONF; then

  # 9. Clone or pull dotfiles ──────────────────────────────────────────────────
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Dotfiles already present at ${DOTFILES_DIR}, pulling..."
    git -C "$DOTFILES_DIR" pull
  elif git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR" 2>&1; then
    ok "Dotfiles cloned"
  else
    echo ""
    echo "⚠ Could not clone dotfiles — tools are installed but config symlinks were skipped."
    echo "  Once the repo is available, run: install.sh --conf"
    exit 0
  fi

  # 10. Stow ───────────────────────────────────────────────────────────────────
  log "Symlinking dotfiles with stow..."
  stow --dir="${DOTFILES_DIR}" --target="${HOME}" --restow \
    bash starship vim tmux
  ok "Stow"

fi  # DO_CONF


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ All done! Run 'exec bash' to reload your shell."