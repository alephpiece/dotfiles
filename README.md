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

Version numbers are defined as variables at the top of `install.sh`. Edit and re-run.