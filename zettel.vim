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
let s:main_dir = get(g:, 'z_main_dir', $HOME . '/tmp') . '/'
let s:ext = get(g:, 'z_default_extension', '.md')

" Default register
let s:reg = get(g:, 'z_default_register', '+')

" Window stuff
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
" u=unlink → unlink buffer with selection list
let s:unlink_key = get(g:, 'z_unlink_key', 'ctrl-u')
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
let s:keymap = extend(s:keymap, {
            \ s:new_link_key : s:create_note_window,
            \ s:delete_note_key : s:create_note_window,
            \ s:rename_notes_key : s:create_note_window,
            \ s:unlink_key : s:create_note_window,
            \ })

" FZF expects a comma separated string.
let s:expect_keys = join(keys(s:keymap) + get(g:, 'z_expect_keys', []), ',')

"============================ Helper Functions ==============================

function! s:trim_title(title)
    return trim(a:title[1:])
endfunction

function! s:create_link(title, filename)
    return '[' . a:title . '](' . a:filename . ')'
endfunction

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

" Convert human-readable 'filetime' to a machine-readable 'filename''s:ext'
function! s:time_to_basename(filetime)
    return substitute(a:filetime, '\D', '', 'g') . s:ext
endfunction

" Convert fzf-preview 'previewbody' to managable 'basename' and 'filebody'
function! s:parse_previewbody(previewbody)
    let [filetime; filebody] = a:previewbody
    let basename = s:time_to_basename(l:filetime)
    return [l:basename, l:filebody]
endfunction

" Replace all `[name]('basename')` with `name`
function! s:remove_link(basename)
    return {key,val -> substitute(val,
                \ '\[\(.\{-}\)](\(' . a:basename . '\))',
                \ '\1',
                \ 'g')}
endfunction

"============================== Handler Function ===========================

function! s:handler(lines) abort
    " debugging
    let g:local = l:
    let g:script = s:

    " 'a:lines' is a list consisting of [query, keypress, ...previewbodies]
    let query    = a:lines[0]
    let keypress = a:lines[1]
    let previewbodies = map(a:lines[2:], 'split(v:val, "")')
    let cmd = get(s:keymap, keypress, 'edit')

    " Create a new note using 'query' when fzf can't find 'query'
    if empty(previewbodies)
        let filename = s:main_dir . strftime("%Y%W%u%H%M%S") . s:ext " YYYYWWDHHMMSS
        let startswithhash = (match(query, '^#') != -1) ? "" : "#"
        call writefile([startswithhash . query, repeat('_', 80)], filename)
        execute cmd filename

    " Replace all references to current buffer title with user replacement
    elseif keypress ==? s:rename_notes_key
        let buf_replacement = input("New name: ")
        let buf_name = bufname("%")
        let buf_basename = matchlist(buf_name, '\d*' . s:ext . '$')[0]
        let buf_title = s:trim_title(getline(1))

        " Replace all 'buf_title' with 'buf_replacement' in current buffer
        let buf_filebody = readfile(buf_name)
        call map(buf_filebody, 'substitute(v:val, buf_title, buf_replacement, "")')
        call writefile(buf_filebody, buf_name)
        call s:redraw_file(buf_name)

        " Replace all links refering to 'buf_name' with 'buf_replacement'
        for previewbody in previewbodies
            let [basename, filebody] = s:parse_previewbody(previewbody)
            if len(filebody) == 0 | continue | endif
            " Use 'buf_basename' as it's more solid
            let Regex = {key,val -> substitute(val,
                        \ '\[.\{-}\]('.buf_basename.')',
                        \ '['.buf_replacement.']('.buf_basename.')',
                        \ 'g')}
            call map(filebody, Regex)
            call writefile(filebody, s:main_dir . basename)
            call s:redraw_file(s:main_dir . basename)
        endfor

    " Delete all selected files and remove links to them (don't touch modified buffers)
    elseif keypress ==? s:delete_note_key
        let basenames = map(copy(previewbodies), 's:time_to_basename(v:val[0])')
        let titles = map(copy(previewbodies), 's:trim_title(v:val[1])')
        let join_basenames = join(basenames, '\|')

        let choice = confirm("Delete " . join(basenames, ', ') . "?", "&Yes\n&Cancel", 1)
        if choice == 2
            return
        endif

        " Replace all '[name]("basename")' with 'name' in all notes
        for filename in glob(s:main_dir . "*" . s:ext, 0, 1, 1)
            let Regex = s:remove_link(join_basenames)
            let Filter = {key,val -> -1 == match(val, '> \[.\{-}\]('.join_basenames.')')}

            let filebody = readfile(filename)
            let filebody = filter(filebody, Filter)
            let filebody = map(filebody, Regex)
            call writefile(filebody, filename)
        endfor

        " Finally delete selected files and their buffers (if the are loaded)
        for basename in basenames
            let bufinfo = getbufinfo(basename)
            if !empty(bufinfo)
                if !bufinfo[0].changed && bufinfo[0].loaded
                    execute "bdelete" bufinfo[0].name
                endif
            endif
            call delete(s:main_dir . basename)
        endfor

    elseif keypress ==? s:unlink_key
        let buf_name = bufname("%")
        let buf_filebody = readfile(buf_name)
        let buf_basename = matchlist(buf_name, '\v(\d*'.s:ext.')')[1]

        for previewbody in previewbodies
            let [basename, filebody] = s:parse_previewbody(previewbody)
            if len(filebody) == 0 | continue | endif
            let title = s:trim_title(filebody[0])

            " Remove links in 'filebody' to 'basename'
            function! s:remove_links(filebody, basename, filename)
                " '-1 == match(...)' to keep lines that don't match regex
                let Filter = {key,val -> -1 == match(val, '> \[.\{-}\]('.a:basename.')')}
                let f_filebody = filter(a:filebody, Filter)
                call map(f_filebody, s:remove_link(a:basename))
                call writefile(f_filebody, a:filename)
            endfunction

            call s:remove_links(filebody, buf_basename, s:main_dir . basename)
            call s:remove_links(buf_filebody, basename, buf_name)
            call s:redraw_file(s:main_dir . basename)
        endfor

        call s:redraw_file(buf_name)

    " Create a link from current file to all files referencing title
    elseif keypress ==? s:new_link_key
        " get buffer title+basename and create a link
        let buf_name = bufname("%")
        let buf_title = s:trim_title(getline(1))
        let buf_basename = matchlist(buf_name, '\v(\d*'.s:ext.')')[1]
        let buf_link = s:create_link(buf_title, buf_basename)

        for previewbody in previewbodies
            let [basename, filebody] = s:parse_previewbody(previewbody)
            if len(filebody) == 0 | continue | endif
            let title = s:trim_title(filebody[0])

            " Add links in 'filebody' to 'buf_basename'
            let HasBufname = {key,val -> match(val, buf_basename)}
            if -1 == max(map(copy(filebody), HasBufname))
                " there are no references to 'buf_basename' append link at bottom
                call add(filebody, '> ' . buf_link)
            else
                " Make all references to 'buf_title' a link iff. it is not already a link
                let Regex = {key,val -> substitute(val, '\[\@<!'.buf_title.'\]\@!', buf_link, 'g')}
                let filebody[1:] = map(filebody[1:], Regex)
            endif
            call writefile(filebody, s:main_dir . basename)
            call s:redraw_file(s:main_dir . basename)

            if basename == buf_basename
                continue
            endif
            " Place link in current buffer (or set register if only one file selected)
            let filelink = s:create_link(title, basename)
            " Add link to 'buf_basename' but don't duplicate links
            if search(basename, 'cnw') == 0
                if len(previewbodies) == 1
                    let @" = filelink
                    let @* = filelink
                    let @+ = filelink
                else
                    call append("$", '> ' . filelink)
                endif
            endif
        endfor
        redraw!
        write

    " Execute cmd for each file files
    else
        for previewbody in previewbodies
            execute cmd s:main_dir . s:time_to_basename(previewbody[0])
        endfor
    endif

endfunction

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

" Calling this function will initialize query with visual selection
command! -range -nargs=* -bang ZV
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


" Clean http/s link for mardown
function! s:clean_http_link()
    try " may fail
        let reg = getreg(s:reg)
        " link [0]=match [1]=scheme [2]=rest [3]=resource
        let link = matchlist(reg, '\v^(\w+)://(.{-})/(.{-})(/)?$')
        let link[2:3] = map(link[2:3], "tr(v:val, '/-_', ':  ')")
        let link = s:create_link(join(link[1:3], ':'), reg)
        call setreg('+', link)
    catch /^Vim\%((\a\+)\)\=:E684/
    endtry
endfunction

command! ToMarkdownLink call s:clean_http_link()
