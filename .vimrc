" vimrc (optimized, minimal, modern-friendly)

set nocompatible
set encoding=utf-8

" Core defaults
filetype plugin indent on
syntax enable

" UI
set number
set ruler
set showcmd
set visualbell
set t_vb=
set background=dark

" Editing / indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set backspace=indent,eol,start

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Mouse (only if supported)
if has('mouse')
  set mouse=a
endif

" Persistent undo (recommended). Create dirs if missing.
if has('persistent_undo')
  silent! call mkdir(expand('~/.vim/tmp/undo'), 'p', 0700)
  set undofile
  set undodir=~/.vim/tmp/undo//
endif

" Swap file location (keeps projects clean). Create dir if missing.
silent! call mkdir(expand('~/.vim/tmp/swap'), 'p', 0700)
set directory^=~/.vim/tmp/swap//

" Backup files: disable (you already have persistent undo + swap).
set nobackup
set nowritebackup

" Colorscheme: try afterglow; fall back quietly if not installed.
try
  colorscheme afterglow
catch /^Vim\%((\a\+)\)\=:E185/
endtry

" GUI font (only in GUI clients)
if has('gui_running')
  set guifont=Monospace\ 12
endif

" ------------------------------------------------------------
" Keymaps
" ------------------------------------------------------------

let mapleader = ","

" Clear search highlight on Enter (keeps Enter usable)
nnoremap <CR> :nohlsearch<CR><CR>

" Quick edit/reload vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" ------------------------------------------------------------
" Cursor shape + (optional) cursor color in modern terminals
" - Uses DECSCUSR for shape, OSC 12 for color.
" ------------------------------------------------------------
if &term =~# 'xterm\|screen\|tmux\|rxvt\|kitty\|wezterm\|alacritty'
  " Insert: solid vertical bar (6), Normal: solid block (2)
  let &t_SI = "\<Esc>[6 q\<Esc>]12;green\x7"
  let &t_EI = "\<Esc>[2 q\<Esc>]12;white\x7"
endif

" ------------------------------------------------------------
" Filetype-specific behavior (grouped to avoid duplicates)
" ------------------------------------------------------------
augroup user_filetypes
  autocmd!
  " Text: wrap to ~76 cols, spellcheck, 2-space soft tabs
  autocmd FileType text setlocal autoindent expandtab softtabstop=2 shiftwidth=2 tabstop=2 textwidth=76 spell spelllang=en_us
  " Help: no spelling
  autocmd FileType help setlocal nospell
augroup END

" ------------------------------------------------------------
" Block navigation helpers + mappings
" ------------------------------------------------------------
function! GotoBlockBeginPrev() abort
  normal! ?{
  normal! w99[{
endfunction

function! GotoBlockBeginNext() abort
  normal! j0
  normal! [[%
  normal! /{
endfunction

function! GotoBlockEndPrev() abort
  normal! k$][%
  normal! ?}
endfunction

function! GotoBlockEndNext() abort
  normal! /}
  normal! b99]}
endfunction

nnoremap [[ :call GotoBlockBeginPrev()<CR>
nnoremap ]] :call GotoBlockBeginNext()<CR>
nnoremap [] :call GotoBlockEndPrev()<CR>
nnoremap ][ :call GotoBlockEndNext()<CR>
