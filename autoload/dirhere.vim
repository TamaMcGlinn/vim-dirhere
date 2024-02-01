fu! s:StartsWith(longer, shorter) abort
  return a:longer[0:len(a:shorter)-1] ==# a:shorter
endfunction

function! dirhere#dir_up() abort
  cd ..
  pwd
endfunction

function! s:NextDirIn(dir, base) abort
  let l:end_index = stridx(a:dir, "/", len(a:base) + 1)
  if l:end_index == -1
    " hack to make the -1 end up in the below expression, so it goes to the
    " end of the string rather than counting back
    let l:end_index = 0
  endif
  return a:dir[len(a:base)+1:l:end_index - 1]
endfunction

function!  dirhere#find_common_parent_dir(dir1, dir2) abort
  " one of the parameters may be a file, but not both
  " e.g. l:dir1 = /home/somewhere/else/file.txt   l:dir2 = /home/elsewhere
  " result should be /home   but with l:dir2 = /home/somewhere/else
  " result would be  /home/somewhere/else
  let l:base = ""
  while len(l:base) < len(a:dir1) && len(l:base) < len(a:dir1)
    let l:next_dir1 = s:NextDirIn(a:dir1, l:base)
    let l:next_dir2 = s:NextDirIn(a:dir2, l:base)
    if l:next_dir1 !=# l:next_dir2
      return l:base
    endif
    let l:base = l:base . '/' . l:next_dir1
  endwhile
  return l:base
endfunction

function! dirhere#dir_down() abort
  let l:dir = dirhere#GetDir()
  let l:pwd = getcwd()
  let l:target = v:null
  if s:StartsWith(l:dir, l:pwd)
    " find one dir deeper towards l:dir starting from l:pwd
    " e.g. l:dir = /home/somewhere/file.txt   l:pwd = /home
    "              0123456
    " start from here:   ^  since "/home" is 5 characters
    " hence, we use len(l:pwd) + 1
    let l:end_index = stridx(l:dir, "/", len(l:pwd) + 1)
    let l:target = l:dir[0:l:end_index]
  else
    " go to common parent instead, so that qj qk work afterwards
    let l:target = dirhere#find_common_parent_dir(l:dir, l:pwd)
  endif
  execute 'cd '.l:target
  pwd
endfunction

function! dirhere#FileInGitDir() abort
  call system("git -C " . expand("%:h") . " rev-parse HEAD")
  return v:shell_error == 0
endfunction

function! s:CdToProjectRoot() abort
  if dirhere#FileInGitDir()
    execute "Gcd"
    return
  endif
  let l:dir = luaeval("require'dirhere'.get_project_root()")
  if l:dir is v:null
    return
  endif
  execute 'cd '.l:dir
  echom 'cd '.l:dir
endfunction

function! dirhere#CdToProjectRoot() abort
  call s:CdToProjectRoot()
  execute "pwd"
endfunction

function! dirhere#GetDirFromPrompt() abort
  let l:line=getline('.')
  " if you're reading this wondering if this is good code...
  " no.
  " whenever stuff breaks I hack on another regex that happens to match what
  " I'm currently using
  if l:line =~# '^\$ *$'
    " empty line; the one we want is probably one above
    let l:line = getline(line('.')-1)
  endif

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
  if &filetype ==# 'nerdtree'
    return b:NERDTreeRoot.path.str()
  endif
  if &buftype ==# 'terminal'
    return dirhere#GetDirFromPrompt()
  endif
  return expand('%:p:h')
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

let s:Opposite_dirs = {'l': 'h', 'h': 'l', 'k': 'j', 'j': 'k'}

function! dirhere#PasteFilenameFromAdjacentWindow(dir, absolute=v:false) abort
  execute 'wincmd ' . a:dir
  if a:absolute
    let l:filename = expand('%:p')
  else
    let l:filename = bufname('%')
  endif
  execute 'wincmd ' . s:Opposite_dirs[a:dir]
  call append(line('.'), l:filename)
endfunction
