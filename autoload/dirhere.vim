
function! dirhere#GetDirFromPrompt() abort
  let l:line=getline('.')
  " if you're reading this wondering if this is good code...
  " no.
  " whenever stuff breaks I hack on another regex that happens to match what
  " I'm currently using
  if l:line =~? '^[^@]*@[^:]*:'
    " do mrt 31-15:54:27 - tama@apollo11:~/code/stuff/somewhere [master]
    let l:line=substitute(l:line, '^[^@]*@[^:]*:', '', '')
    let l:dir=substitute(l:line, ' \[[^\]]*\]$', '', '')
  elseif l:line =~? '^[^> ]*@[^> ]* MINGW.. '
    " USER@DOMAIN MINGW64 ~/vimscripts/dein/repos/github.com/autozimu/LanguageClient-neovim_next (next)
    let home='/' . $HOME[0] . substitute($HOME[2:], '\', '/', 'g')
    let l:line=substitute(l:line, '\~', home, '')
    " USER@DOMAIN MINGW64 /c/code/with spaces
    " USER@DOMAIN MINGW64 /c/code/in_git (master)
    let l:dir=substitute(substitute(substitute(l:line, '.*MINGW.. /\(.\)', '\1:', ''), '(.*)$', '', ''), '/', '\', 'g')
  elseif l:line =~# '.:[^>]*>.*'
    " C:\Program Files\Neovim\bin>some user-input
    let l:dir=substitute(l:line, '>.*', '', '')
  elseif l:line =~# '^\((.*) \)\?[^@> ]*@[^:>@ ]*:[^$]'
    " tama@tama-hp-laptop:~/code/adacore/libadalang$
    let l:line=substitute(l:line, '^(.*) ', '', '')
    let l:dir=substitute(substitute(l:line, '$.*', '', ''), '^[^@> ]*@[^:>@ ]*:', '', '')
  else
    throw 'No pattern matches '.l:line
  endif
  return l:dir
endfunction

function! dirhere#GetDir() abort
  if &buftype ==# 'terminal'
    return dirhere#GetDirFromPrompt()
  else
    return expand('%:p:h')
  endif
endfunction

" Change directory to current line
function! dirhere#DirToCurrentLine() abort
  let l:dir = dirhere#GetDir()
  execute 'cd '.l:dir
  echom 'cd '.l:dir
endfunction

function! dirhere#JumpToTerminalBuffer() abort
  if &buftype ==# 'terminal'
    return
  endif
  let l:first_window_number = winnr()
  while v:true
    execute "wincmd W"
    if &buftype ==# 'terminal'
      return
    endif
    if winnr() == l:first_window_number
      break
    endif
  endwhile
  throw "Unable to find terminal window in current tab"
endfunction

function! dirhere#TermDirToCwd() abort
  call dirhere#JumpToTerminalBuffer()
  call feedkeys('acd ' . getcwd() . '')
endfunction

" Change directory of terminal to current line
function! dirhere#TermDirToCurrentLine() abort
  let l:dir = dirhere#GetDir()
  call dirhere#JumpToTerminalBuffer()
  call feedkeys('acd ' . l:dir . '')
endfunction

