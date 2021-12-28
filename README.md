# Terminal Directory Control

Dirhere lets you move the vim working dir to the directory of some line on the terminal
(not necessarily the current line, but anywhere in the terminal buffer). It also has
functions to change the directory of the terminal to that of a file in another split or
vim's working dir, or the line under the cursor in a terminal.

Works well in conjunction with [termhere](https://github.com/TamaMcGlinn/vim-termhere).

## Install

Use your favourite plugin manager.

```
Plug 'TamaMcGlinn/vim-dirhere'
```

## Example config

```
nnoremap <leader>qq :call dirhere#DirToCurrentLine()<CR>
nnoremap <leader>qw :call dirhere#TermDirToCwd()<CR>
nnoremap <leader>qc :call dirhere#TermDirToCurrentLine()<CR>
nnoremap <leader>qg :Gcd<CR>
nnoremap <leader>qp :pwd<CR>

" if you use https://github.com/liuchengxu/vim-which-key
let g:which_key_map['q'] = {'name': '+Dir',
             \'q': 'Current file',
             \'c': 'Terminal to here',
             \'w': 'Terminal to working dir',
             \'p': 'Print dir',
             \'g': 'Git root',
             \}
```
