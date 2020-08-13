" NOTE: This uses '\f' characters to separate items. Let me know if this is an issue.
"============================== Utility functions =============================

" XXX: fnameescape vs. shellescape: for vim's consumption vs. the shell's
" consumption

function! s:single_quote(str)
    return "'" . a:str . "'"
endfunction

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


if exists('g:z_search_paths')
    echoerr "`g:z_search_paths` is a single `g:main_dir`. You'll thank me later"
    finish
endif

" File stuff. Use a single, non-nested directory to store all files
let s:script_dir = expand('<sfile>:h')
let s:main_dir = get(g:, 'z_main_dir', $HOME . "/notes/")
let s:ext = get(g:, 'z_default_extension', '.md')

let s:window_direction = get(g:, 'z_window_direction', 'down')
let s:window_width = get(g:, 'z_window_width', '40%')
let s:window_command = get(g:, 'z_window_command', '')

" Valid options are ['up', 'down', 'right', 'left']. Default is 'right'. No colon for
" this command since it's first in the list.
let s:preview_direction = get(g:, 'z_preview_direction', 'right')

let s:wrap_text = get(g:, 'z_wrap_preview_text', 0) ? 'wrap' : ''

" Show preview unless user set it to be hidden
let s:show_preview = get(g:, 'z_show_preview', 1) ? '' : 'hidden'

" Respect .*ignore files unless user has chosen not to
let s:use_ignore_files = get(g:, 'z_use_ignore_files', 1) ? '' : '--no-ignore'

" Skip hidden files and folders unless user chooses to include them
let s:include_hidden = get(g:, 'z_include_hidden', 0) ? '--hidden' : ''

" How wide to make preview window. 72 characters is default.
let s:preview_width = exists('g:z_preview_width') ? string(float2nr(str2float(g:z_preview_width) / 100.0 * &columns)) : ''

"=========================== Windows Overrides ============================

if has('win64') || has('win32')
    let s:null_path = 'NUL'
    let s:command = ''
else
    let s:null_path = '/dev/null'
    let s:command = 'command'
endif

"=========================== Keymap ========================================

" l=link → yanks link to @" register
let s:new_link_key = get(g:, 'z_new_link_key', 'ctrl-l')
" d=delete → delete all selected notes, asks user for confirmation
let s:delete_note_key = get(g:, 'z_delete_note_key', 'ctrl-d')
" r=rename → rename the header of selected files to 'input()'
let s:rename_notes_key = get(g:, 'z_rename_notes_key', 'ctrl-r')

let s:keymap = get(g:, 'z_keymap',
            \ {'ctrl-s': 'split',
            \ 'ctrl-v': 'vertical split',
            \ 'ctrl-t': 'tabedit',
            \ })

let s:create_note_window = get(g:, 'z_create_note_window', 'edit ')
" Use `extend` in case user overrides default keys
let s:keymap = extend(s:keymap, {
            \ s:new_link_key : s:create_note_window,
            \ s:delete_note_key : s:create_note_window,
            \ s:rename_notes_key : s:create_note_window,
            \ })

" FZF expects a comma separated string.
let s:expect_normal_keys = join(keys(s:keymap) + get(g:, 'z_expect_keys', []), ',')
let s:expect_visual_keys = join(keys(s:keymap) + get(g:, 'z_expect_keys', []), ',')

"============================ Helper Functions ==============================

function! s:trim_title(title)
    return trim(a:title[1:])
endfunction

function! s:create_link(title, filename)
    return '[' . a:title . '](' . a:filename . ')'
endfunction

" Create new file with time based unique id
function! s:new_file(query)
    let filename = s:uid_to_file(strftime("%Y%W%u%H%M%S")) " YYYYWWDHHMMSS
    let hashash = (match(a:query, '^#') != -1) ? "" : "#"
    call writefile([hashash . a:query], filename)
    return filename
endfunction

" Update active buffers
function! s:update_file(filename, ...)
    let curwinid = get(a:, 1, win_getid())
    let winid = bufwinid(bufname(a:filename))
    if winid != -1
        call win_gotoid(winid)
        edit
        call win_gotoid(curwinid)
    endif
endfunction

" Convert readable 'filetime' to 'filename'
function! s:file_basename(filetime)
    return substitute(a:filetime, '\D', '', 'g') . s:ext
endfunction

" Convert preview 'filebody' to managable 'basename' and 'filebody'
function! s:read_filebody(filebody)
    let [filename; filebody] = a:filebody
    let basename = s:file_basename(l:filename)
    return [l:basename, l:filebody]
endfunction

"============================== Handler Function ===========================

function! s:handler(lines) abort
    " debugging
    let g:local = l:
    let g:script = s:

    " Expect at least 2 elements, `query` and `keypress`, which may be empty strings.
    " files is a list of all files selected through fzf
    let query    = a:lines[0]
    let keypress = a:lines[1]
    let files = map(a:lines[2:], 'split(v:val, "")')
    let cmd = get(s:keymap, keypress, 'edit')

    " Creating a new note, even if one of the params are empty.
    if empty(l:files)
        let new_file = s:new_file(query)
        execute cmd new_file

    " Rename file and all links to it
    elseif keypress ==? s:rename_notes_key
        let buf_replacement = input("New name: ")
        let buf_name = bufname("%")
        let buf_basename = matchlist(buf_name, '\d*' . s:ext . '$')[0]
        let buf_title = s:trim_title(getline(1))

        " Replace all links refering to 'buf_name' with 'buf_replacement'
        for filebody in l:files
            let [basename, body] = s:read_filebody(filebody)
            let Regex = {key,val -> substitute(val, '\[.\{-}\]('.buf_basename.')', '['.buf_replacement.']('.buf_basename.')', 'g')}
            call map(body, Regex)
            call writefile(body, s:main_dir . basename)
            call s:update_file(s:main_dir . basename)
        endfor

        " Update file with replacement
        let buf_filebody = readfile(buf_name)
        call map(buf_filebody, 'substitute(v:val, buf_title, buf_replacement, "")')
        call writefile(buf_filebody, buf_name)
        call s:update_file(buf_name)

    " Delete note/s (does not delete modified buffers)
    elseif keypress ==? s:delete_note_key
        " Setup
        let basenames = map(copy(l:files), 's:file_basename(v:val[0])')
        let titles = map(copy(l:files), 's:trim_title(v:val[1])')

        " make sure the user is sure about this
        let choice = confirm("Delete " . join(basenames, ', ') . "?", "&Yes\n&Cancel", 1)
        if choice == 2
            return
        endif

        " Go through each file,
        for filename in glob(s:main_dir . "*" . s:ext, 0, 1, 1)
            " Regex replaces all links to 'basename' with their inside text
            let Regex = {key,val -> substitute(val, '\[\(.\{-}\)](\(' . join(basenames, '\|') . '\))', '\1', 'g')}
            let filebody = map(readfile(filename), Regex)
        endfor

        " Finally delete files and their buffers
        for basename in basenames
            " Delete buffer if it exists
            let bufinfo = getbufinfo(basename)
            if !empty(bufinfo)
                if !bufinfo[0].changed && bufinfo[0].loaded
                    execute "bdelete" bufinfo[0].name
                endif
            endif
            call delete(basename)
        endfor

    " Create a link from current file to all files referencing title
    elseif keypress ==? s:new_link_key
        let buf_name = bufname("%")
        if match(buf_name, s:main_dir . '.\{-}' . s:ext) == -1
            echoerr "File name must match '" . s:main_dir . ".\{-}" . s:ext . "'."
            return
        endif
        " get buffer title+basename and create a link
        let buf_title = s:trim_title(getline(1))
        let buf_basename = matchlist(buf_name, '\v(\d*'.s:ext.')')[1]
        let buf_link = s:create_link(buf_title, buf_basename)

        for filebody in l:files
            " get meta info
            let [basename, body] = s:read_filebody(filebody)
            let title = s:trim_title(body[0])

            " Place link in current body (don't link pre-existing link)
            let body[1:] = map(body[1:], "substitute(v:val, '\\[\\@<!'.buf_title.'\\]\\@!', buf_link, 'g')")
            call writefile(body, s:main_dir . basename)
            call s:update_file(s:main_dir . basename)

            " Don't append link to buffer
            if basename == buf_basename
                continue
            endif
            " Place link in current buffer (or set register if only one file selected)
            let filelink = s:create_link(title, basename)
            " search the whole buffer
            if search(basename, 'cnw') == 0
                if len(l:files) == 1
                    let @" = filelink
                    let @* = filelink
                    let @+ = filelink
                else
                    call append("$", '- ' . filelink)
                endif
            endif
        endfor
        redraw!
        write

    " Execute cmd for each file files
    else
        for filebody in l:files
            execute cmd s:main_dir . s:file_basename(filebody[0])
        endfor
    endif

endfunction

" If the file you're looking for is empty, then why does it even exist? It's a
" note. Just type its name. Hence we ignore lines with only space characters,
" and use the "\S" regex.

" Use a big ugly option list. The '.. ' is because fzf wants a term of the
" form 'N.. ' where N is a number.

" Use `command` in front of 'rg' to ignore aliases.
" The `' "\S" '` is so that the backslash itself doesn't require escaping.
let s:fzf_options =
            \ join([
            \   '--print-query',
            \   '--cycle',
            \   '--multi',
            \   '--exact',
            \   '--inline-info',
            \   '--tiebreak=' . 'length,begin' ,
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

command! -nargs=* -bang Z
            \ call fzf#run(
            \ fzf#wrap({
            \ 'sink*': function(exists('*z_note_handler') ? 'z_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh' . ' ' . shellescape(s:main_dir) . ' ' . s:ext,
            \ 'options': join([
            \   s:fzf_options,
            \   '--expect=' . s:expect_normal_keys,
            \ ]),
            \ },<bang>0))

" Return visual selection
function! s:get_visual_selection() abort
  try
    let a_save = @a
    silent! normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" Calling this function will initialize query with visual selection
command! -range -nargs=* -bang ZV
            \ call fzf#run(
            \ fzf#wrap({
            \ 'sink*': function(exists('*z_note_handler') ? 'z_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh' . ' ' . shellescape(join([s:main_dir, s:ext])),
            \ 'options': join([
            \   s:fzf_options,
            \   '--query=' . s:get_visual_selection(),
            \   '--expect=' . s:expect_visual_keys,
            \ ]),
            \ },<bang>0))

