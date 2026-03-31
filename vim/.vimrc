set nocompatible

" ── Environment ───────────────────────────────────────────────────────────────
if has('win32') || has('win64')
  let s:vimdir = expand('~/vimfiles')
else
  let s:vimdir = expand('~/.vim')
endif

" ── vim-plug ──────────────────────────────────────────────────────────────────
" Install vim-plug if not exists.
" Use :PlugInstall, :PlugUpdate, :PlugClean to manage plugins.
let s:plug_path = s:vimdir . '/autoload/plug.vim'
if empty(glob(s:plug_path))
  echohl WarningMsg | echom 'Downloading vim-plug...' | echohl None
  if executable('curl')
    silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  else
    echohl ErrorMsg | echom 'curl not found, install vim-plug manually.' | echohl None
  endif
endif

" ── Plugins ───────────────────────────────────────────────────────────────────
call plug#begin(s:vimdir . '/plugged')
Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" ── General ───────────────────────────────────────────────────────────────────
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,gb18030,gb2312,cp936,latin1
set hidden                  " allow switching buffers without saving
set history=1000

" ── Persistent undo ───────────────────────────────────────────────────────────
set undofile
let &undodir = s:vimdir . '/undodir'
if !isdirectory(&undodir)
  call mkdir(&undodir, 'p')
endif

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

" ── UI ────────────────────────────────────────────────────────────────────────
syntax on
filetype plugin indent on
set number                  " line numbers
set wildmenu                " command completion

" Theme configuration
if has('termguicolors')
  set termguicolors
endif
if exists('g:plugs[''onehalf'']')
  silent! colorscheme onehalfdark
endif
let g:airline_theme='onehalfdark'
let g:airline_powerline_fonts = 1

" ── Remember last position ────────────────────────────────────────────────────
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" ── fzf.vim keybindings ───────────────────────────────────────────────────────
nnoremap <C-p> :Files<CR>
nnoremap <C-g> :Rg<CR>
nnoremap <C-b> :Buffers<CR>
