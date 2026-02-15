# Vimrc Refactoring Plan

> Target: Linux + macOS | Vim + Neovim. No Windows. Modernize plugins while preserving functionality.

---

## 1. Current Configuration Overview

### 1.1 Plugin Manager
- **vim-plug** — Keep (current, well-maintained)

### 1.2 Current Plugins (28 total)

| Plugin | Purpose | Status |
|--------|---------|--------|
| junegunn/vim-plug | Plugin manager | Keep |
| junegunn/goyo.vim | Markdown focus mode | Keep |
| junegunn/limelight.vim | Focus highlighting | Keep |
| xolox/vim-easytags | Auto ctags | Replace → vim-gutentags |
| xolox/vim-misc | Easytags dependency | Remove (with easytags) |
| **deoplete.nvim** | Completion | **Replace** → coc.nvim or asyncomplete |
| roxma/nvim-yarp, vim-hug-neovim-rpc | Deoplete deps (vim) | Remove |
| rust-lang/rust.vim | Rust support | Keep |
| bling/vim-airline | Status line | Keep |
| jiangmiao/auto-pairs | Bracket pairing | Keep |
| **scrooloose/syntastic** | Linting | **Replace** → ALE |
| honza/vim-snippets | Snippets | Keep |
| **kien/ctrlp.vim** | Fuzzy finder | **Replace** → fzf.vim |
| tpope/vim-fugitive | Git | Keep |
| majutsushi/tagbar | Tag sidebar | Keep |
| godlygeek/tabular | Table align | Keep |
| plasticboy/vim-markdown | Markdown | Keep |
| scrooloose/nerdcommenter | Comments | Keep |
| scrooloose/nerdtree | File tree | Keep |
| **sjl/gundo.vim** | Undo tree | **Replace** → mbbill/undotree |
| tpope/vim-surround | Surround | Keep |
| tpope/vim-sleuth | Indent detection | Keep |
| blueyi/a.vim | Alternate file (c/h) | Keep (or vim-a/vimswitch) |
| Yggdroot/indentLine | Indent lines | Keep |
| **klen/python-mode** | Python | **Remove** (redundant with LSP) |
| blueyi/vim-template | Templates | Keep |
| blueyi/vim-dep | misc (ycm_extra_conf) | Refactor (see below) |
| blueyi/myvimcolors | Colors | Keep or replace |
| tomasr/molokai | Colors | Keep |
| flazz/vim-colorschemes | Colors | Keep |

### 1.3 Custom Logic to Preserve
- F2: NERDTree, F3: Tagbar, F4: Undo tree, F5: Lint, F7: Paste toggle, F9: Run
- Leader: ;ev (edit vimrc), ;rv (reload), ;w (save), ;p/y (clipboard), ;cS/cM (trim)
- Zoom, split navigation (C-J/K/L/H)
- Run_c, Run_cpp, Run_py, Run_ruby, Run_java, Run_cuda, Run_cs, Run_sh
- Filetype detection, encoding, indentation, backup/swap/undo, search, fold
- C++ path (/usr/include/c++/*), PEP8, JS/HTML/CSS indentation

---

## 2. Plugin Replacement Plan

### 2.1 Completion (deoplete → coc.nvim)

**Current**: deoplete + nvim-yarp + vim-hug-neovim-rpc (vim 8 needs extra packages)
**Replace**: coc.nvim (works for both vim 8 and neovim, Node.js required)

```
Plug 'neoclide/coc.nvim', {'branch': 'release'}
```

- LSP-based completion (clangd, pyright, etc.)
- No neocomplete/deoplete config; use `coc-settings.json`
- F5: `:CocCommand workspace.diagnostic` or ALE for lint

### 2.2 Linting (syntastic → ALE)

**Current**: syntastic (sync, can freeze)
**Replace**: ALE (async)

```
Plug 'dense-analysis/ale'
```

- `g:ale_linters`, `g:ale_fixers`
- F5: `:ALELint` or ALE runs automatically

### 2.3 Fuzzy Finder (ctrlp → fzf.vim)

**Current**: ctrlp
**Replace**: fzf + fzf.vim (faster, depends on fzf binary)

```
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
```

- `<c-p>` → `:Files` or `:GFiles`
- Requires fzf installed (brew install fzf / apt install fzf)

### 2.4 Undo Tree (gundo → undotree)

**Current**: gundo (Python, last update 2016)
**Replace**: undotree (pure vimscript, active)

```
Plug 'mbbill/undotree'
```

- F4: `:UndotreeToggle`
- No Python dependency

### 2.5 Tags (easytags → vim-gutentags)

**Current**: vim-easytags + vim-misc
**Replace**: vim-gutentags (async, lighter)

```
Plug 'ludovicchabant/vim-gutentags'
```

- Async ctags; configure `gutentags_project_root`

### 2.6 Python (python-mode → remove)

**Current**: python-mode (heavy, overlaps LSP)
**Action**: Remove; use ALE + coc (pyright) for Python

### 2.7 vim-dep

**Current**: ycm_extra_conf.py, misc
**Action**: If using coc + clangd, use compile_commands.json or .clangd; remove or simplify vim-dep

---

## 3. Platform Considerations (Linux + macOS)

### 3.1 Paths
- Use `expand('~')` instead of `~` in script contexts
- C++ include: `/usr/include/c++/*` (Linux), `/usr/local/include` or Xcode (macOS)
- CUDA path: Linux `/usr/local/cuda`, macOS typically N/A (or optional)
- Python: `python3` on both; prefer `:!python3 %` for Run_py

### 3.2 GUI
- `has('gui_running')` for gvim/macvim
- Font: Linux `DejaVu Sans Mono`, macOS `Menlo` or `SF Mono`
- `guioptions` applies to both

### 3.3 Remove
- All `g:iswindows` branches
- Windows-specific encoding (delmenu.vim, cp936, etc.)
- Vundle / vimfiles references

---

## 4. Recommended New Plugins List (vim-plug)

```vim
call plug#begin('~/.vim/plugged')
" Plugin manager
Plug 'junegunn/vim-plug'

" Markdown
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
Plug 'junegunn/limelight.vim', { 'for': 'markdown' }

" Completion & LSP
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Linting
Plug 'dense-analysis/ale'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Misc
Plug 'rust-lang/rust.vim'
Plug 'bling/vim-airline'
Plug 'jiangmiao/auto-pairs'
Plug 'honza/vim-snippets'
Plug 'tpope/vim-fugitive'
Plug 'majutsushi/tagbar'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'mbbill/undotree'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sleuth'
Plug 'blueyi/a.vim'
Plug 'Yggdroot/indentLine'
Plug 'blueyi/vim-template'
Plug 'tomasr/molokai'
Plug 'flazz/vim-colorschemes'
call plug#end()
```

---

## 5. Implementation Order

| Phase | Task | Effort |
|-------|------|--------|
| P0 | Remove Windows branches, Vundle comments, dead neocomplete/YCM config | Low |
| P1 | Replace syntastic → ALE | Low |
| P2 | Replace gundo → undotree | Low |
| P3 | Replace ctrlp → fzf.vim | Medium |
| P4 | Replace easytags → gutentags | Medium |
| P5 | Replace deoplete → coc.nvim, remove python-mode | High |
| P6 | Clean vim-dep, add coc-settings.json / .clangd | Medium |
| P7 | Platform-specific paths (C++ include, fonts) | Low |

---

## 6. Optional: Neovim-Only Path

If targeting **Neovim only**, consider:
- nvim-lspconfig + nvim-cmp (no Node.js)
- telescope.nvim (fuzzy finder)
- lazy.nvim (plugin manager)

For **Vim 8 + Neovim** compatibility, stick with vim-plug + coc.nvim + fzf.vim + ALE.

---

## 7. Neovim Setup (Implemented)

- `config/init.vim` links to `~/.config/nvim/init.vim`
- init.vim sets `runtimepath` to include `~/.vim` and sources `~/.vimrc`
- Both Vim and Neovim share plugins in `~/.vim/plugged`
