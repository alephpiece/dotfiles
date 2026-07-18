# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), targeting Ubuntu/Debian.

## Installation

Install binaries and apply configs:

```bash
curl -fsSL https://raw.githubusercontent.com/alephpiece/dotfiles/main/install.sh | bash
```

Install binaries only:

```bash
curl -fsSL https://raw.githubusercontent.com/alephpiece/dotfiles/main/install.sh | bash -s -- --bin
```

Apply configs only:

```bash
curl -fsSL https://raw.githubusercontent.com/alephpiece/dotfiles/main/install.sh | bash -s -- --conf
```

### Optional GitHub proxy

Set `GH_PROXY` to use a URL-prefixing GitHub proxy for requests made by the
installer:

```bash
curl -fsSL https://raw.githubusercontent.com/alephpiece/dotfiles/main/install.sh \
  | GH_PROXY="https://proxy.example" bash
```

The installer tries URLs in the form
`https://proxy.example/https://github.com/...` first and falls back to GitHub
directly if the proxy fails. If `GH_PROXY` is unset, installation behaves as
before.

## Structure

```
~/.dotfiles/
├── install.sh       # Install binaries, patch ~/.bashrc, stow all packages
├── bash/            # Shell init — only .bashrc.d/ is stowed (see below)
├── <tool>/          # One Stow package per tool, mirroring $HOME paths
└── ...
```

Each top-level directory is a **Stow package**. Running `stow <package>` symlinks its
contents into `$HOME`, preserving the relative path. For example,
`starship/.config/starship.toml` becomes `~/.config/starship.toml`.

### Why `~/.bashrc` is not managed by Stow

The system `~/.bashrc` is left untouched to preserve machine-specific config. Instead,
`install.sh` appends a single loader line to the existing `~/.bashrc`:

```bash
for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && source "$f"; done
```

Shell init for each tool lives in `bash/.bashrc.d/<tool>.sh` and is sourced
automatically.

## Adding a new tool

1. Create a Stow package directory mirroring the home path, e.g.:
   ```
   mkdir -p ~/.dotfiles/mytool/.config/mytool
   ```
2. Add config files inside it.
3. If the tool needs shell init, add `bash/.bashrc.d/mytool.sh`.
4. Add the package name to the `stow` call in `install.sh`.

## Upgrading tool versions

Re-run `install.sh` to check for updates. Tools installed from GitHub Releases (`fd`,
`ripgrep`, `starship`, `glow`, and `witr`) resolve their latest release dynamically;
their versions are not pinned in the script.

APT dependencies are installed only when missing, and an existing `~/.fzf` clone is
not updated automatically.
