" Minimal portable Vim configuration for servers.

set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set number
set ruler
set hidden
set wildmenu
set showcmd
set showmatch
set ignorecase
set smartcase
set incsearch
set hlsearch
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=2
set backspace=indent,eol,start
set mouse=

syntax on
filetype plugin indent on

" Keep temporary files under ~/.cache when possible.
if isdirectory($HOME . '/.cache/vim') || mkdir($HOME . '/.cache/vim', 'p', 0700)
  set backupdir=~/.cache/vim//
  set directory=~/.cache/vim//
  set undodir=~/.cache/vim//
  if has('persistent_undo')
    set undofile
  endif
endif

