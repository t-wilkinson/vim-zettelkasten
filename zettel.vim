"============================= Dependencies ================================

if !executable('fd') " faster and simpler find
    echoerr '`fd` is not installed. See https://github.com/sharkdp/fd for installation instructions.'
    finish
endif

if !executable('bat') " cat but with syntax highlighting
    echoerr '`bat` is not installed. See https://github.com/sharkdp/bat for installation instructions.'
    finish
endif

"============================== User settings ==============================

" File stuff. Use a single, non-nested directory to store all files.
let s:script_dir = expand('<sfile>:h')
" let s:main_dir = expand('<sfile>:p:h').'/notes/'
let s:main_dir = get(g:, 'z_main_dir', $HOME.'/.vim/notes') . '/'
let s:ext = get(g:, 'z_default_extension', '.md')
let s:reg = get(g:, 'z_default_register', '+')

" Window stuff
let s:window_direction = get(g:, 'z_window_direction', 'down')
let s:window_width = get(g:, 'z_window_width', '40%')
" let s:window_command = get(g:, 'z_window_command', '')
let s:window_command = 'call FloatingFZF()'
function! FloatingFZF()
  let buf = nvim_create_buf(v:false, v:true)
  call setbufvar(buf, '&signcolumn', 'no')

  let height = float2nr(25)
  let width = float2nr(100)
  let horizontal = float2nr((&columns - width) / 2)
  let vertical = 1

  let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height,
        \ 'style': 'minimal'
        \ }

  call nvim_open_win(buf, v:true, opts)
endfunction

let s:preview_direction = get(g:, 'z_preview_direction', 'right')
let s:wrap_text = get(g:, 'z_wrap_preview_text', 0) ? 'wrap' : ''
let s:show_preview = get(g:, 'z_show_preview', 1) ? '' : 'hidden'
let s:use_ignore_files = get(g:, 'z_use_ignore_files', 1) ? '' : '--no-ignore'
let s:include_hidden = get(g:, 'z_include_hidden', 0) ? '--hidden' : ''
let s:preview_width = exists('g:z_preview_width') ? string(float2nr(str2float(g:z_preview_width) / 100.0 * &columns)) : ''

"============================ Helper Functions ==============================

" Update active buffers
function! s:redraw_file(filename, ...)
    let curwinid = get(a:, 1, win_getid())
    let winid = bufwinid(bufname(a:filename))
    if winid != -1
        call win_gotoid(winid)
        edit
        call win_gotoid(curwinid)
    endif
endfunction

function! s:file_basename(filename)
    return matchlist(a:filename, '\d*'.s:ext.'$')[0]
endfunction

"============================== Handler Functions ===========================

function! s:handler(lines) abort
    " 'a:lines' :: [query, keypress, ...previewbodies]

    " debugging
    " let g:local = l:
    " let g:script = s:

    " Convert fzf-preview 'previewbody' to managable 'basename' and 'filebody'
    function! s:parse_previewbody(previewbody)
        let [filetime; filebody] = a:previewbody
        let TimeToBasename = {time->substitute(time, '\D', '', 'g') . s:ext}
        let basename = TimeToBasename(l:filetime)
        return [l:basename, l:filebody]
    endfunction

    function! s:edit_previewbodies(req) abort
        let cmd = get(s:commands, a:req.keypress, 'edit')
        for [basename, _] in a:req.previewbodies
            execute cmd s:main_dir . basename
        endfor
    endfunction

    let request = {
                \ "query": a:lines[0],
                \ "keypress": a:lines[1],
                \ "previewbodies": map(a:lines[2:], 's:parse_previewbody(split(v:val, ""))'),
                \ }

    if empty(request.previewbodies)
        call s:new_note(request)
    else
        call get(s:actions, request.keypress, function("s:edit_previewbodies"))(request)
    endif
endfunction

function! s:create_new_note(req) abort
    let f_path = s:main_dir . strftime("%Y%W%u%H%M%S") . s:ext " $HOME/notes/YYYYWWDHHMMSS.md
    let cmd = get(s:commands, a:req.keypress, s:default_command)
    execute cmd f_path
endfunction

function! s:delete_notes(req) abort
    " Confirm
    let basenames = map(copy(a:req.previewbodies), 'v:val[0]')
    let choice = confirm("Delete " . join(basenames, ', ') . "?", "&Yes\n&No", 1)
    if choice == 2 | return | endif

    " Delete selected files and their buffers (if the are loaded)
    for basename in basenames
        let bufinfo = getbufinfo(basename)
        " Delete file buffer if exists
        if !empty(bufinfo)
            if !bufinfo[0].changed && bufinfo[0].loaded
                execute "bdelete" bufinfo[0].name
            endif
        endif
        call delete(s:main_dir . basename)
    endfor
endfunction

function! s:remove_tag_from_notes(req) abort
    let tag = input('tag to remove @')
    let RemoveTag = {line->substitute(line,
                    \ '\s*@'.tag.'\s*',
                    \ ' ',
                    \ 'g')}
    for [basename, filebody] in a:req.previewbodies
        if len(filebody) == 0 | continue | endif
        " NOTE: You COULD use the following line but it only applies to a few situations and has a dramatic slowdown
        " call map(filebody, RemoveTag)
        let filebody[0] = RemoveTag(filebody[0])
        call writefile(filebody, s:main_dir . basename)
        call s:redraw_file(s:main_dir . basename)
    endfor
endfunction

function! s:add_tag_to_notes(req) abort
    let tag = input('tag to add @')
    for [basename, filebody] in a:req.previewbodies
        let filebody[0] = filebody[0].' @'.l:tag
        call writefile(filebody, s:main_dir . basename)
        call s:redraw_file(s:main_dir . basename)
    endfor
endfunction

"=========================== Keymap ========================================
" unusable  : a c e m n p u w y
" iffy      : j k l
" usable    : b f g h q s v z
" in use    : t r d c o

" t=tag → tag zettels
let s:tag_note_key = get(g:, 'z_tag_note_key', 'ctrl-t')
" r=remove link → unlink buffer with selection list
let s:remove_tags_key = get(g:, 'z_remove_tag_key', 'ctrl-r')
" d=delete → delete all selected notes, asks user for confirmation
let s:delete_note_key = get(g:, 'z_delete_note_key', 'ctrl-d')
" o=open → create a new zettel
let s:new_note_key = get(g:, 'z_new_note_key', 'ctrl-o')

let s:default_command = 'edit'
let s:commands = get(g:, 'z_commands',
            \ {'ctrl-s': 'split',
            \ 'ctrl-v': 'vertical split',
            \ 'ctrl-t': 'tabedit',
            \ })

let s:create_note_window = get(g:, 'z_create_note_window', 'edit ')

let s:actions = {
            \ s:tag_note_key: function("s:add_tag_to_notes"),
            \ s:remove_tags_key: function("s:remove_tag_from_notes"),
            \ s:delete_note_key: function("s:delete_notes"),
            \ s:new_note_key: function("s:create_new_note"),
            \ }
let s:keymap = extend(copy(s:commands), s:actions)

" FZF expects a comma separated string.
let s:expect_keys = join(keys(s:keymap) + get(g:, 'z_expect_keys', []), ',')

"=========================== FZF ========================================

" Use `command` in front of 'rg' to ignore aliases.
" The `' "\S" '` is so that the backslash itself doesn't require escaping.
let s:fzf_options =
            \ join([
            \   '--tac',
            \   '--print-query',
            \   '--cycle',
            \   '--multi',
            \   '--exact',
            \   '--inline-info',
            \   '--tiebreak=' . 'index' ,
            \   '--bind=' .  join([
            \     'alt-a:select-all',
            \     'alt-q:deselect-all',
            \     'alt-p:toggle-preview',
            \     'alt-u:page-up',
            \     'alt-d:page-down',
            \     'ctrl-w:backward-kill-word',
            \     ], ','),
            \   '--preview=' . shellescape(join([s:script_dir . '/preview.sh', s:ext, '{}'])),
            \   '--preview-window=' . join(filter(copy([
            \       s:preview_direction,
            \       s:preview_width,
            \       s:wrap_text,
            \       s:show_preview,
            \     ]),
            \   'v:val != "" ')
            \   ,':')
            \   ])

command! -nargs=* -bang Zettel
            \ call fzf#run(
            \ fzf#wrap({
            \ 'sink*': function(exists('*z_note_handler') ? 'z_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh' . ' ' . shellescape(s:main_dir) . ' ' . s:ext,
            \ 'options': join([
            \   s:fzf_options,
            \   '--expect=' . s:expect_keys,
            \ ]),
            \ },<bang>0))

" Calling this function will initialize query with visual selection
command! -range -nargs=* -bang ZettelVvisual
            \ call fzf#run(
            \ fzf#wrap({
            \ 'sink*': function(exists('*z_note_handler') ? 'z_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh'.' '.shellescape(s:main_dir).' '.s:ext,
            \ 'options': join([
            \   s:fzf_options,
            \   '--query=' . s:get_visual_selection(),
            \   '--expect=' . s:expect_keys,
            \ ]),
            \ },<bang>0))

function! s:get_visual_selection() abort
  try
    let a_save = @a
    silent! normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

