colorscheme pablo
set nocompatible    " This enables a bunch of the stuff below

set hlsearch        " highlight search results
set incsearch       " highlight search results as you type
set number          " turn off with set nonumber
set numberwidth=2   " will auto adjust for files with > 99 lines
set ruler           " show line and column num of cursor on bottom right
set showcmd         " show size of selected area in visual mode

filetype on         " Highlight text based on syntax
filetype plugin on  " 
syntax enable       " 

" These restore the cursor to the last known position
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

" Enable more colors for fancier colorschemes
if $TERM == "xterm-256color"
  set t_Co=256
endif
if $TERM == "screen-256color"
  set t_Co=256
endif


