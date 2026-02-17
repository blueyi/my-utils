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

1. **PATH:** Homebrew’s `bin` is added by `config/path.bash` when you use the linked rc. If your terminal didn’t load it (e.g. Cursor’s built-in terminal), use the `source .../config/cmake_env.bash` one-liner above.

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
