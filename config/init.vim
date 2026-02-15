" Neovim init - shares config with Vim via ~/.vimrc
" Symlink: config/init.vim -> ~/.config/nvim/init.vim
set runtimepath^=~/.vim
set runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
