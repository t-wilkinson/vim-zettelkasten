let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/.vim/plugin/zettel/mdnav
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +9 shell.nix
badd +317 ftplugin/markdown/mdnav.py
badd +207 ~/.vimrc
badd +2 ~/dotfiles/.config/nixpkgs/config.nix
badd +2 ftplugin/markdown/mdnav.vim
badd +5 ~/notes/2020321000000.md
badd +6 ~/notes/2020322104643.md
badd +1 ~/notes/2020322055740.md
badd +38 ~/notes/2020324181847.md
badd +7 ~/notes/2020322111656.md
badd +292 ~/notes/2020321000001.md
badd +2 tests/test_mdnav.py
badd +1 ftplugin/markdown/href
argglobal
%argdel
$argadd shell.nix
set stal=2
edit ~/notes/2020321000001.md
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 127 + 127) / 255)
exe 'vert 2resize ' . ((&columns * 127 + 127) / 255)
argglobal
if bufexists("/usr/share/nvim/runtime/doc/if_pyth.txt") | buffer /usr/share/nvim/runtime/doc/if_pyth.txt | else | edit /usr/share/nvim/runtime/doc/if_pyth.txt | endif
setlocal fdm=manual
setlocal fde=foldexprs.c()
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=9
setlocal fml=1
setlocal fdn=20
setlocal nofen
silent! normal! zE
let s:l = 526 - ((18 * winheight(0) + 23) / 47)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
526
normal! 0
wincmd w
argglobal
setlocal fdm=expr
setlocal fde=foldexprs.nc()
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=9
setlocal fml=1
setlocal fdn=20
setlocal fen
291
normal! zo
291
normal! zo
291
normal! zo
let s:l = 293 - ((33 * winheight(0) + 23) / 47)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
293
normal! 016|
wincmd w
exe 'vert 1resize ' . ((&columns * 127 + 127) / 255)
exe 'vert 2resize ' . ((&columns * 127 + 127) / 255)
tabedit ftplugin/markdown/mdnav.py
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 127 + 127) / 255)
exe 'vert 2resize ' . ((&columns * 127 + 127) / 255)
argglobal
setlocal fdm=expr
setlocal fde=foldexprs.nc()
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=9
setlocal fml=1
setlocal fdn=20
setlocal fen
18
normal! zo
18
normal! zo
22
normal! zo
256
normal! zo
256
normal! zo
299
normal! zo
316
normal! zo
316
normal! zo
let s:l = 317 - ((23 * winheight(0) + 23) / 47)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
317
normal! 010|
wincmd w
argglobal
if bufexists("ftplugin/markdown/mdnav.py") | buffer ftplugin/markdown/mdnav.py | else | edit ftplugin/markdown/mdnav.py | endif
setlocal fdm=expr
setlocal fde=foldexprs.nc()
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=9
setlocal fml=1
setlocal fdn=20
setlocal fen
let s:l = 47 - ((17 * winheight(0) + 23) / 47)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
47
normal! 0
wincmd w
2wincmd w
exe 'vert 1resize ' . ((&columns * 127 + 127) / 255)
exe 'vert 2resize ' . ((&columns * 127 + 127) / 255)
tabnext 2
set stal=1
if exists('s:wipebuf') && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 winminheight=1 winminwidth=1 shortmess=filnxtToOF
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
