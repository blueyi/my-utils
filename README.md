# My-Utils

One-click dev environment setup for Linux / macOS. Supports zsh, bash, vimrc, zshrc, bashrc, etc.

## Features

- Linux (Ubuntu / Debian / Fedora) and macOS
- Configs managed via symlinks; edits stay in repo for backup and version control
- One-shot or selective install; `--yes` for non-interactive mode
- Profile presets: C++, Python, AI Infra (LLVM / MLIR, TVM)

## Quick Start

```bash
git clone https://github.com/your-user/my-utils.git ~/repos/my-utils
cd ~/repos/my-utils

# One-shot install
./bootstrap.sh --yes

# Or interactive
./bootstrap.sh

exec $SHELL
```

## Install Options

```bash
# System packages only
./bootstrap.sh --tools packages --yes

# Symlinks only (vimrc, bashrc, zshrc, etc.)
./bootstrap.sh --tools links --yes

# oh-my-zsh, pyenv only
./bootstrap.sh --tools misc --yes

# Vim plugins only
./bootstrap.sh --tools vimrc --yes
```

## Config Layout

`~/.vimrc`, `~/.bashrc`, `~/.zshrc` symlink to files under `config/`. Edit files in `config/` to change live config; commit as usual.

```
config/
├── _vimrc      → ~/.vimrc
├── init.vim    → ~/.config/nvim/init.vim  (Neovim, sources ~/.vimrc)
├── _bashrc     → ~/.bashrc
├── _zshrc      → ~/.zshrc
├── myrc.bash
├── resetrc.bash
└── ...
```

## Profiles

```bash
source ~/repos/my-utils/profiles/cpp/env.bash      # C++ / LLVM
source ~/repos/my-utils/profiles/python/env.bash   # Python
source ~/repos/my-utils/profiles/ai_infra/env.bash  # AI Infra
```

## Cursor Config Backup

Sync Cursor settings to `cursor_bak/` and use symlinks so edits stay in the repo. **Not enabled by default**; use `--tools cursor`:

```bash
./bootstrap.sh --tools cursor --yes     # Link Cursor config to cursor_bak
./bootstrap.sh --tools cursor          # Interactive
# Standalone:
./common/cursor_config_link.sh          # Link
./common/cursor_config_link.sh --restore   # Restore original paths
```

## License

MIT
