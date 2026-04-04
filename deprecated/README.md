# Deprecated / archive

This folder holds **historical or alternate layouts** that are no longer the recommended path. Active configuration lives under **`config/`**, especially **`config/resetrc.bash`** (monolithic env with **`# SECTION:`** comment blocks).

## What changed (summary)

- **Single env file:** `config/resetrc.bash` contains all feature areas in one file, separated by comment banners. **bash / zsh** use it by default; **Fish** can use **`emit_fish_env.bash`** if linked (optional).
- **Shell entrypoints** (`shell_init.bash`, `zsh_entry.zsh`; optional `emit_fish_env.bash` for Fish) chain **Oh My Zsh / bash UI** + **`resetrc.bash`** + `optional_home.bash`.

## Contents

| Path | Note |
|------|------|
| `deprecated/config/llvm.bash.standalone` | Old standalone LLVM loader (logic now under `SECTION: LLVM` in `resetrc.bash`). |
| `deprecated/config/sections-split-archive/` | Copy of the former `config/sections/NN-*.bash` split layout (superseded by monolithic `resetrc.bash`). |

If you have local scripts that still `source .../config/llvm.bash`, switch to:

```bash
source "$MYRC_PATH/resetrc.bash"
```

(or rely on your normal `~/.bashrc` / `~/.zshrc` → `shell_init`).

---

# 中文说明

本目录用于**归档**。当前推荐：**环境集中在 [`config/resetrc.bash`](../config/resetrc.bash)**，用 **`# SECTION:`** 注释分块。曾按多文件拆分的版本见 **`deprecated/config/sections-split-archive/`**。
