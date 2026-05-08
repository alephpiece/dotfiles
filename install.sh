#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="https://github.com/alephpiece/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# ── Versions ──────────────────────────────────────────────────────────────────
STARSHIP_VER=1.25.1
FD_VER=10.4.2
RG_VER=15.1.0

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo ">>> $*"; }
ok()  { echo "✓  $*"; }

ensure_apt_pkgs() {
  local label="$1"
  shift

  local missing=()
  local pkg
  for pkg in "$@"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" || missing+=("$pkg")
  done

  if (( ${#missing[@]} > 0 )); then
    log "Installing ${label}: ${missing[*]}..."
    sudo apt-get update -q
    sudo apt-get install -y "${missing[@]}"
    ok "$label"
  else
    ok "${label} already installed"
  fi
}

install_bashrc_loader() {
  log "Patching ~/.bashrc with .bashrc.d loader..."
  # shellcheck disable=SC2016
  local loader='for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && source "$f"; done'
  local bashrc="$HOME/.bashrc"

  if [ ! -f "$bashrc" ] || ! grep -qxF "$loader" "$bashrc"; then
    echo "$loader" >> "$bashrc"
  fi
  ok ".bashrc loader"
}

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
  ensure_apt_pkgs "base tools" tmux less curl git stow python3-pip

  # 2. pipx ────────────────────────────────────────────────────────────────────
  if ! command -v pipx &>/dev/null; then
    log "Installing pipx..."
    sudo apt-get install -y pipx
    pipx ensurepath
    ok "pipx"
  else
    ok "pipx already installed"
  fi

  # 3. fzf ─────────────────────────────────────────────────────────────────────
  if [ ! -d ~/.fzf ]; then
    log "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  fi
  ~/.fzf/install --all --no-update-rc
  ok "fzf"

  # 4. fd ──────────────────────────────────────────────────────────────────────
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

  # 5. ripgrep ─────────────────────────────────────────────────────────────────
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

  # 6. Starship ────────────────────────────────────────────────────────────────
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

fi  # DO_BIN


# ── Configs ───────────────────────────────────────────────────────────────────
if $DO_CONF; then

  # 9. Config dependencies and .bashrc.d loader ────────────────────────────────
  if ! $DO_BIN; then
    ensure_apt_pkgs "config dependencies" git stow
  fi
  install_bashrc_loader

  # 10. Clone or pull dotfiles ──────────────────────────────────────────────────
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

  # 11. Stow ───────────────────────────────────────────────────────────────────
  log "Symlinking dotfiles with stow..."
  stow --dir="${DOTFILES_DIR}" --target="${HOME}" --restow \
    bash starship vim tmux uv
  ok "Stow"

fi  # DO_CONF


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ All done! Run 'exec bash' to reload your shell."
