" ── Plugins ───────────────────────────────────────────────────────────────────
call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()

" ── General ───────────────────────────────────────────────────────────────────
set nocompatible
set encoding=utf-8
set hidden                  " allow switching buffers without saving
set history=1000

" ── Persistent undo ───────────────────────────────────────────────────────────
set undofile
set undodir=~/.vim/undodir
if !isdirectory($HOME . '/.vim/undodir')
  call mkdir($HOME . '/.vim/undodir', 'p')
endif

" ── UI ────────────────────────────────────────────────────────────────────────
set number                  " line numbers
set wildmenu                " command completion

" ── Search ────────────────────────────────────────────────────────────────────
set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <Esc><Esc> :nohlsearch<CR>

" ── Indentation ───────────────────────────────────────────────────────────────
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" ── fzf.vim keybindings ───────────────────────────────────────────────────────
nnoremap <C-p> :Files<CR>
nnoremap <C-g> :Rg<CR>
nnoremap <C-b> :Buffers<CR>