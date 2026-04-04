# My-Utils

One-click dev environment setup for Linux / macOS. Default shells: **bash** + **zsh** (Oh My Zsh); **Fish** is optional (see below). Also vimrc, tmux, etc.

## Features

- Linux (Ubuntu / Debian / Fedora) and macOS
- Configs managed via symlinks; edits stay in repo for backup and version control
- One-shot or selective install; `--yes` for non-interactive mode
- Profile presets: C++, Python, AI Infra (LLVM / MLIR); optional Triton (GPU kernel) via `config/triton.bash`
- **One env file:** `config/resetrc.bash` holds all shared env as **`# SECTION: …`** blocks (nvm, pyenv, CUDA, LLVM, …). Edit **that file** to affect **bash, zsh, and profiles**; optional Fish uses the same file via `emit_fish_env.bash` when linked.

## Design: multi-OS, multi-shell, minimal host changes

**What touches the system**

- **Only `$HOME` (and standard XDG paths)** are modified by default, via **[`common/link.ini`](common/link.ini)** → **`create_links.sh`**: symlinks such as `~/.bashrc`, `~/.zshrc`, `~/.my-utils.env`, `~/.shell_init.bash`, etc. **Fish** symlinks are **commented out** in `link.ini` until you opt in.
- **Shell env logic** lives entirely under the cloned repo (`config/resetrc.bash`, `shell_init.bash`, …). **No `/etc` patches** are required for this dotfiles layout.
- **`common/misc.sh`** may run **`chsh` to zsh** after Oh My Zsh install—that **does** change the login shell in `/etc/passwd` (or equivalent). Remove or guard that block if you want **zero** account-level changes.

**Multi-OS**

- **Packages:** [`common/install_packages.sh`](common/install_packages.sh) + [`common/deb_app_list.ini`](common/deb_app_list.ini) / [`common/mac_app_list.txt`](common/mac_app_list.txt) / [`common/rpm_app_list.ini`](common/rpm_app_list.ini).
- **Env:** [`config/resetrc.bash`](config/resetrc.bash) uses **`_is_linux` / `_is_macos`** inside sections (PATH, CUDA, brew kegs, …).

**Multi-shell**

- **bash / zsh (default):** One **`resetrc.bash`** (bash-compatible); [`config/shell_init.bash`](config/shell_init.bash) loads **`bash_interactive.bash`** or [`config/zsh_entry.zsh`](config/zsh_entry.zsh) (Oh My Zsh), then **`resetrc`** + **`optional_home.bash`**.
- **fish (optional):** Install **`fish`** yourself (`apt`/`brew`/…), uncomment the Fish lines in [`common/link.ini`](common/link.ini), run **`./bootstrap.sh --tools links --yes`**. Then [`config/emit_fish_env.bash`](config/emit_fish_env.bash) + [`config/fish/my-utils.fish`](config/fish/my-utils.fish) import **exported variables** from **`resetrc`**; aliases/functions are not auto-ported.

**Gaps (by choice)**

- **Login-only** sessions that never source `~/.bashrc` / `~/.zshrc` won’t load my-utils unless **you** add a one-liner to `~/.profile` or `~/.zprofile` pointing at `shell_init` / `resetrc`—not linked by default to keep the installer conservative.

**中文概要：** 默认 **packages** 只装 **zsh**（含 Oh My Zsh 相关），**不装 Fish**；**Fish** 相关 symlink 在 `link.ini` 里默认注释，需用时自行安装 fish 并取消注释后再跑 **links**。**misc** 里 **chsh** 可能把登录 shell 改为 zsh。

## Quick Start

```bash
git clone https://github.com/your-user/my-utils.git ~/repos/my-utils
cd ~/repos/my-utils

# One-shot init (no prompts): packages, links, misc, vimrc, cursor
./bootstrap.sh --yes

# Interactive: asks which of (packages, links, misc, vimrc, cursor) to run
./bootstrap.sh

exec $SHELL
```

## Install Options

```bash
# Without --yes: prompts for each step (packages / links / misc / vimrc / cursor)
./bootstrap.sh

# With --yes: run selected steps with no prompts
./bootstrap.sh --yes                              # all steps
./bootstrap.sh --tools packages --yes             # system packages only
./bootstrap.sh --tools links --yes                # symlinks only (vimrc, bashrc, zshrc, etc.)
./bootstrap.sh --tools misc --yes                 # oh-my-zsh, pyenv
./bootstrap.sh --tools vimrc --yes                # vim plugins
./bootstrap.sh --tools cursor --yes               # Cursor config backup link
./bootstrap.sh --tools packages links cursor --yes # multiple steps
```

## Config Layout

`~/.vimrc`, `~/.bashrc`, `~/.zshrc` symlink to files under `config/`. **`~/.p10k.zsh`** → **`config/p10k.zsh`** (Powerlevel10k; edit in repo, re-run links if needed). **`~/.bashrc` / `~/.zshrc` end with `source ~/.shell_init.bash`**, which runs `config/shell_init.bash`: **zsh** → Oh My Zsh + p10k + **`resetrc.bash`**; **bash** → interactive defaults + **`resetrc.bash`**. **All shared env** lives in **`config/resetrc.bash`** as ordered **`# SECTION: …`** blocks (proxy, PATH, nvm, pyenv, zsh-only OpenClaw/fzf, CUDA, LLVM, …). **Zsh-only** bits are guarded with `ZSH_VERSION` inside that file.

```
config/
├── _vimrc, _bashrc, _zshrc   → ~/.vimrc, ~/.bashrc, ~/.zshrc
├── p10k.zsh                  → ~/.p10k.zsh (Powerlevel10k theme)
├── shell_init.bash           → ~/.shell_init.bash
├── resetrc.bash              # monolithic env (comment sections; search SECTION:)
├── sections/README.md        # pointer only (old split layout archived in deprecated/)
├── bash_interactive.bash     # bash-only prompt, completion
├── zsh_entry.zsh             # Oh My Zsh + theme/plugins, then resetrc
├── path.bash, cmake_env.bash # thin → resetrc (IDE one-liners)
├── emit_fish_env.bash, fish/my-utils.fish  # optional Fish; symlink via commented lines in link.ini
├── triton.bash               # optional GPU/Triton layer on top of resetrc
├── deprecated/               # archive (see deprecated/README.md)
└── ...
```

### Optional Fish

Not installed or linked by default. Steps: **`sudo apt install fish`** (or `brew install fish`) → uncomment the two Fish lines in **[`common/link.ini`](common/link.ini)** → **`./bootstrap.sh --tools links --yes`**. Then Fish loads **`my-utils.fish`**, which runs **`emit_fish_env.bash`** to mirror **`resetrc.bash`** + **`optional_home.bash`** exports. For **pyenv** in Fish, see **`pyenv init - fish`** upstream.

## Profiles and optional env

```bash
# Preset profiles (manual source)
source ~/repos/my-utils/profiles/cpp/env.bash      # C++ / LLVM
source ~/repos/my-utils/profiles/python/env.bash   # Python
source ~/repos/my-utils/profiles/ai_infra/env.bash  # AI Infra

# Triton (GPU kernel) dev
source "$MYRC_PATH/triton.bash"
```

## Troubleshooting

### CMake: Ninja / C/C++ compiler not found

If you see:
- `CMake was unable to find a build program corresponding to "Ninja"`
- `CMAKE_C_COMPILER not set` / `CMAKE_CXX_COMPILER not set`

**Quick fix (any terminal, including Cursor/IDE):** source the CMake env script before running cmake so `PATH`, `CC`, `CXX`, and `CMAKE_MAKE_PROGRAM` are set:

```bash
# Replace with your actual my-utils path if different
source ~/workspace/my-utils/config/cmake_env.bash
# or, if MY_UTILS_ROOT is already set:
source "$MY_UTILS_ROOT/config/cmake_env.bash"

cd /path/to/your/project/build
cmake ..
```

**macOS:**

1. **PATH:** Homebrew and baseline paths are set in `config/resetrc.bash` when you use the linked rc. If your terminal didn’t load it (e.g. Cursor’s built-in terminal), use the `source .../config/cmake_env.bash` one-liner above (it sources `resetrc.bash`).

2. **C/C++ compiler:** Install Xcode Command Line Tools so `clang` is available:
   ```bash
   xcode-select --install
   ```

**Linux (apt):** Install packages with `./bootstrap.sh --tools packages --yes`. If the terminal didn’t load your rc, run `source .../config/cmake_env.bash` before cmake.

## Cursor Config Backup

Sync Cursor settings to `cursor_bak/` and use symlinks so edits stay in the repo. Backed up (macOS: `~/Library/Application Support/Cursor`, Linux: `~/.config/Cursor`):

- **User/** – settings.json, keybindings.json, mcp.json, snippets, etc.
- **Preferences** – app-level preferences file
- **ide_state.json** – when present
- **~/.cursor/rules** → `cursor_bak/rules`
- **~/.cursor/projects** → `cursor_bak/projects` (per-workspace state; `terminals/` and `agent-transcripts/` are gitignored)

**Included in default tool list** (both `./bootstrap.sh --yes` and interactive `./bootstrap.sh` will include cursor unless you use `--tools` to limit):

```bash
./bootstrap.sh --yes                    # runs cursor step with others
./bootstrap.sh --tools cursor --yes     # only Cursor config link
./bootstrap.sh --tools cursor          # interactive: ask then link
# Standalone:
./common/cursor_config_link.sh          # Link
./common/cursor_config_link.sh --restore   # Restore original paths
```

## License

MIT
