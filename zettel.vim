" NOTE: This uses '\f' characters to separate items. Let me know if this is an issue.
"============================== Utility functions =============================

" XXX: fnameescape vs. shellescape: for vim's consumption vs. the shell's
" consumption

function! s:single_quote(str)
    return "'" . a:str . "'"
endfunction

"============================= Dependencies ================================

if !executable('fd')
    echoerr '`fd` is not installed. See https://github.com/sharkdp/fd for installation instructions.'
    finish
endif

if !executable('bat')
    echoerr '`bat` is not installed. See https://github.com/sharkdp/bat for installation instructions.'
    finish
endif

"============================== User settings ==============================


if exists('g:nv_search_paths')
    echoerr "`g:nv_search_paths` is a single `g:main_dir`. You'll thank me later"
    finish
endif

" File stuff. Use a single, non-nested directory to store all files
let s:script_dir = expand('<sfile>:h')
let s:main_dir = get(g:, 'nv_main_dir', $HOME . "/tmp/")

let s:ext = get(g:, 'nv_default_extension', '.md')
let s:pattern = '^\d*'

let s:window_direction = get(g:, 'nv_window_direction', 'down')
let s:window_width = get(g:, 'nv_window_width', '40%')
let s:window_command = get(g:, 'nv_window_command', '')

" Valid options are ['up', 'down', 'right', 'left']. Default is 'right'. No colon for
" this command since it's first in the list.
let s:preview_direction = get(g:, 'nv_preview_direction', 'right')

let s:wrap_text = get(g:, 'nv_wrap_preview_text', 0) ? 'wrap' : ''

" Show preview unless user set it to be hidden
let s:show_preview = get(g:, 'nv_show_preview', 1) ? '' : 'hidden'

" Respect .*ignore files unless user has chosen not to
let s:use_ignore_files = get(g:, 'nv_use_ignore_files', 1) ? '' : '--no-ignore'

" Skip hidden files and folders unless user chooses to include them
let s:include_hidden = get(g:, 'nv_include_hidden', 0) ? '--hidden' : ''

" How wide to make preview window. 72 characters is default.
let s:preview_width = exists('g:nv_preview_width') ? string(float2nr(str2float(g:nv_preview_width) / 100.0 * &columns)) : ''

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
let s:new_link_key = get(g:, 'nv_new_link_key', 'ctrl-l')
" d=delete → delete all selected notes, asks user for confirmation
let s:delete_note_key = get(g:, 'nv_delete_note_key', 'ctrl-d')
" r=rename → rename the header of selected files to 'input()'
let s:rename_notes_key = get(g:, 'nv_rename_notes_key', 'ctrl-r')

let s:keymap = get(g:, 'nv_keymap',
            \ {'ctrl-s': 'split',
            \ 'ctrl-v': 'vertical split',
            \ 'ctrl-t': 'tabedit',
            \ })

let s:create_note_window = get(g:, 'nv_create_note_window', 'edit ')
" Use `extend` in case user overrides default keys
let s:keymap = extend(s:keymap, {
            \ s:new_link_key : s:create_note_window,
            \ s:delete_note_key : s:create_note_window,
            \ s:rename_notes_key : s:create_note_window,
            \ })

" FZF expects a comma separated string.
let s:expect_normal_keys = join(keys(s:keymap) + get(g:, 'nv_expect_keys', []), ',')
let s:expect_visual_keys = join(keys(s:keymap) + get(g:, 'nv_expect_keys', []), ',')

"============================ Helper Functions ==============================

function! s:get_visual_selection() abort
  try
    let a_save = @a
    silent! normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

function! s:trim_title(title)
    return trim(a:title[1:])
endfunction

function! s:make_link_to(file, filebody)
    let title = a:filebody[0]
    let trimmedtitle = s:trim_title(title)
    return s:create_link(trimmedtitle, a:file)
endfunction

function! s:create_link(title, filename)
    return '[' . a:title . '](' . a:filename . ')'
endfunction

" function! s:uid_to_file(uid)
"     return fnameescape(s:main_dir . a:uid . s:ext)
"     " return s:uid_to_file(matchstr(a:lines, s:pattern))
" endfunction

" Create new file with time based unique id
function! s:new_file(query)
    let filename = s:uid_to_file(strftime("%Y%W%u%H%M%S")) " YYYYWWDHHMMSS
    let hashash = (match(a:query, '^#') != -1) ? "" : "#"
    call writefile([hashash . a:query], filename)
    return filename
endfunction

function! s:update_file(filename, ...)
    let curwinid = get(a:, 1, win_getid())
    let winid = bufwinid(bufname(a:filename))
    if winid != -1
        call win_gotoid(winid)
        edit
        call win_gotoid(curwinid)
    endif
endfunction

function! s:file_basename(filebody)
    return substitute(a:filebody, '\D', '', 'g') . s:ext
endfunction

function! s:lines_to_file(lines)
    return s:main_dir . s:file_basename(a:lines[0])
endfunction

"============================== Handler Function ===========================

function! s:handler(lines) abort
    " Expect at least 2 elements, `query` and `keypress`, which may be empty strings.
    let query    = a:lines[0]
    let keypress = a:lines[1]
    let files = map(a:lines[2:], 'split(v:val, "")')
    let cmd = get(s:keymap, keypress, 'edit')
    let lines = a:lines

    " Creating a new note, even if one of the params are empty.
    if empty(l:files)
        let new_file = s:new_file(query)
        execute "edit" new_file

    " Rename file and all links to it
    elseif keypress ==? s:rename_notes_key
        " let re_replacement = input("Replacement: ")
        " let re_filename = s:lines_to_file(l:files[0])
        " let re_filename_base = s:file_basename(re_filename)
        " let re_filebody = readfile(re_filename)
        " let re_title = s:trim_title(re_filebody[0])

"         for filename in glob(s:main_dir . "*" . s:ext, 0, 1, 1)
"             let filebody = readfile(filename)
"             call map(filebody, 'substitute(v:val, "\\[".re_title."\\]", "\\[".re_replacement."\\]", "")')
"             call writefile(filebody, filename)
"             call s:update_file(filename)
"         endfor

"         " Update file with replacement
"         call map(re_filebody, 'substitute(v:val, re_title, re_replacement, "")')
"         call writefile(re_filebody, re_filename)
"         call s:update_file(re_filename)

    " Delete note/s (does not delete modified buffers)
    elseif keypress ==? s:delete_note_key
        let filenames = map(l:files, 's:lines_to_file(v:val)')
        " make sure the user is sure about this
        let choice = confirm("Delete " . join(filenames, ', ') . "?", "&Yes\n&Cancel", 1)
        if choice == 2
            return
        endif

        " glob on all files
        " read each file
        " regex like so "s/\[\(.\{-}\)]($file)/\1/g"
        " done
        for filename in filenames
            " Delete buffer if it exists
            let bufinfo_list = getbufinfo(filename)
            if !empty(bufinfo_list)
                if !bufinfo_list[0].changed && bufinfo_list[0].loaded
                    execute "bdelete" bufinfo_list[0].name
                endif
            endif
            call delete(filename)
        endfor

    " create a link from current file to all files referencing title
    elseif keypress ==? s:new_link_key
        let bufname = bufname("%")
        if match(bufname, s:main_dir . '.\{-}' . s:ext) == -1
            echoerr "File name must match '" . s:main_dir . ".\{-}" . s:ext . "'."
            return
        endif
        " get buffer title+basename and create a link
        let buf_title = s:trim_title(getline(1))
        let buf_basename = matchlist(bufname, '\v(\d*'.s:ext.')')[1]
        let buf_link = s:create_link(buf_title, buf_basename)

        for filebody in l:files
            " get meta info
            let [filename; filebody] = filebody
            let basename = s:file_basename(filename)
            let title = s:trim_title(filebody[0])

            " Place link in current filebody (don't link pre-existing link)
            let filebody[1:] = map(filebody[1:], "substitute(v:val, '\\[\\@<!'.buf_title.'\\]\\@!', buf_link, 'g')")
            call writefile(filebody, s:main_dir . basename)
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

    let g:test = l:
    let g:script = s:

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
            \ 'sink*': function(exists('*NV_note_handler') ? 'NV_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh' . ' ' . shellescape(s:main_dir) . ' ' . s:ext,
            \ 'options': join([
            \   s:fzf_options,
            \   '--expect=' . s:expect_normal_keys,
            \ ]),
            \ },<bang>0))

command! -range -nargs=* -bang ZV
            \ call fzf#run(
            \ fzf#wrap({
            \ 'sink*': function(exists('*NV_note_handler') ? 'NV_note_handler' : '<sid>handler'),
            \ 'window': s:window_command,
            \ s:window_direction: s:window_width,
            \ 'source': s:script_dir . '/source.sh' . ' ' . shellescape(join([s:main_dir, s:ext])),
            \ 'options': join([
            \   s:fzf_options,
            \   '--query=' . s:get_visual_selection(),
            \   '--expect=' . s:expect_visual_keys,
            \ ]),
            \ },<bang>0))




""============================ Create zettel link ===========================

"" Links cells together adding a '[title](file.md)' to the cell and a matching one to itself
"" This function will not add redundant tags
"" Saves each file as it shouldn't do any destructive operations
"" Allows toggling in fzf to add links from current file to multiple l:files (and backlinks)
"function! s:make_link(keypress, files, curfile)
"    " initialize
"    write
"    let curfilebody = readfile(s:main_dir . a:curfile)
"    let extfiles = a:files[2:]
"    let curwinid = win_getid()
"    let bottomlink = a:keypress == s:make_link_at_bottom_key

"    for extfile in extfiles
"        let extfile = matchstr(extfile, s:pattern) . s:ext
"        let extfilebody = readfile(s:main_dir . extfile)

"        " make link in curfile
"        if match(join(curfilebody), extfile) == -1
"            let curlink = s:make_link_to(extfile, extfilebody)
"            if bottomlink
"                call append(line("$"), "- " . curlink)
"            else
"                let @" = curlink
"                let @* = curlink
"                let @+ = curlink
"            endif
"        endif

"        " make link in extfile
"        if match(join(extfilebody), a:curfile) == -1
"            let extlink = "- " . s:make_link_to(a:curfile, curfilebody)
"            call writefile(add(extfilebody, extlink), s:main_dir . extfile)
"            " update if file is open in active buffer
"            call s:update_file(s:main_dir . extfile, curwinid)
"        endif
"    endfor
"    write
"    redraw!
"    if !bottomlink
"        let curpos = getcurpos()
"        call cursor(curpos[1], curpos[2]+1)
"    endif
"endfunction

"     " Create a new note, with links to all selected entries
"     elseif keypress ==? s:create_link_note_key
"         " Get inputs from user
"         " let new_title = input("TITLE: ")
"         " let regex = fnameescape(input("REGEX: "))
"         let new_title = query
"         let regex = query

"         " Get title and create file
"         let new_filename_full = s:new_file(new_title)
"         let new_lines = readfile(new_filename_full)

"         " Creating a link from 'new_filename_full'
"         let new_filename = s:file_basename(new_filename_full)
"         let new_title_link = s:create_link(new_title, new_filename)

"         " Replace every user-given regex with 'title_link'
"         for filebody in l:files
"             let filename = s:lines_to_file(filebody)
"             let filebody = readfile(filename)

"             " Create link from file to new_file
"             let filebody = map(filebody, "substitute(v:val, regex, new_title_link, 'g')")
"             call writefile(filebody, filename)
"             call s:update_file(filename)

"             " Append link from new_file to file
"             let filetitle = trim(filebody[0][1:])
"             call add(new_lines, "- " . s:create_link(filetitle, s:file_basename(filename)))
"         endfor
"         " Finalize
"         call writefile(new_lines, new_filename_full)

"     " Create link either at bottom of page or at cursor. This is the gold.
"     elseif keypress ==? s:make_link_at_bottom_key || keypress ==? s:make_link_at_cursor_key
"         call s:make_link(keypress, a:lines, expand("%:t"))
