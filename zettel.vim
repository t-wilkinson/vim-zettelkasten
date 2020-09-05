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
let s:main_dir = get(g:, 'z_main_dir', $HOME . '/notes') . '/'
let s:ext = get(g:, 'z_default_extension', '.md')

let s:height = {
            \ 'tag': 2,
            \ 'link': 3,
            \ }

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

"============================== Testing Function ===========================
function! s:test()
    function! s:test_time()
        return strftime("%Y-%W-%w %H:%M:%S")
    endfunction
    function! s:test_new(h, tags)
        call s:handler(extend([a:h, s:new_note_key], a:tags))
        let zettel = s:test_time() . " " . a:h . "some content"
        sleep 1
        return zettel
    endfunction

    let h1 = "#THIRD" | let h2 = "#SECOND" | let h3 = "#asdf" | let h4 = "#FOURTH" | let h5 = "#TEsting" | let h6 = "#Delete"
    " sleep because lowest unit for filename are seconds
    let t1 = s:test_new(h1, [])
    let t2 = s:test_new(h2, [t1])
    let t3 = s:test_new(h3, [t1])
    let t4 = s:test_new(h4, [t1,t2,t3])
    call s:handler(["", s:delete_note_key, t1, t2, t3, t4])

    echo "done"
endfunction
command! Test call s:test()
map <leader>t :write! <bar> source /home/trey/.vim/plugin/zettel/zettel.vim <bar> Test<CR>

"============================ Helper Functions ==============================

function! s:file_title(filebody)
    return s:trim_title(a:filebody[0])
endfunction

function! s:trim_title(title)
    let title = a:title[1:]
    return trim(title)
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

function! s:file_basename(filename)
    return matchlist(a:filename, '\d*'.s:ext.'$')[0]
endfunction

"============================== Handler Function ===========================

" Integrate python in these functions where it will help
function! s:handler(lines) abort

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

    " debugging
    let g:local = l:
    let g:script = s:

    " 'a:lines' :: [query, keypress, ...previewbodies]
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

function! s:new_note(req) abort
    let f_path = s:main_dir . strftime("%Y%W%u%H%M%S") . s:ext " $HOME/notes/YYYYWWDHHMMSS.md
    let f_title = substitute(a:req.query, '^#\?', '#', '')
    let f_tags = s:to_filetags(a:req.previewbodies)
    let f_body = [f_title]
    call writefile(f_body, f_path)

    let cmd = get(s:commands, a:req.keypress, s:default_command)
    execute cmd f_path
endfunction

function! s:to_filetags(previewbodies)
    " Convert each 'previewbody' title to a 'filetag'
    let f_tags = []
    for [_, f_body] in a:previewbodies
        call add(f_tags, s:trim_title(f_body[0]))
    endfor

    " awkward '@' if len(filef_tags) == 0
    if len(f_tags) == 0
        let f_tags = ''
    else
        let f_tags = '@' . join(f_tags, ' @')
    endif

    return f_tags
endfunction

function! s:delete_note(req) abort
    let basenames = map(copy(a:req.previewbodies), 'v:val[0]')
    let choice = confirm("Delete " . join(basenames, ', ') . "?", "&Yes\n&No", 1)
    if choice == 2 | return | endif

    " Delete selected files and their buffers (if the are loaded)
    for basename in basenames
        let bufinfo = getbufinfo(basename)
        if !empty(bufinfo)
            if !bufinfo[0].changed && bufinfo[0].loaded
                execute "bdelete" bufinfo[0].name
            endif
        endif
        call delete(s:main_dir . basename)
    endfor

    let filetitles = map(copy(a:req.previewbodies), 's:file_title(v:val)')
    let join_titles = join(filetitles, '\|')
    " Remove all tags
    for filename in glob(s:main_dir . "*" . s:ext, 0, 1, 1)
        let filebody = readfile(filename)
        call map(filebody, s:remove_tag(join_titles))
        call writefile(filebody, filename)
    endfor
    redraw!
endfunction

function! s:remove_tags(req) abort
    let buf_basename = s:file_basename(bufname("%"))
    let buf_filename = s:main_dir . buf_basename
    let buf_filebody = readfile(buf_filename)
    let buf_title = s:file_title(buf_filebody)

    for [basename, filebody] in a:req.previewbodies
        if len(filebody) == 0 | continue | endif
        let title = s:file_title(filebody)

        call map(filebody, s:remove_tag(buf_title))
        call writefile(filebody, s:main_dir . basename)

        call map(buf_filebody, s:remove_tag(title))
        call writefile(buf_filebody, buf_filename)

        call s:redraw_file(s:main_dir . basename)
    endfor

    call s:redraw_file(buf_filename)
endfunction

" Remove all `@title`
function! s:remove_tag(basename)
    return {key,val -> substitute(val,
                \ '\s*@'.a:title,
                \ '\1',
                \ 'g')}
endfunction

function! s:rename_note(req) abort
    write
    let buf_replacement = input("New name: ")
    let buf_basename = s:file_basename(bufname("%"))
    let buf_title = s:trim_title(getline(1))

    " Replace all links refering to 'buf_bufname' with 'buf_replacement'
    for [basename, filebody] in a:req.previewbodies
        let title = s:trim_title(filebody[0])
        if len(filebody) == 0 | continue | endif
        " Use 'buf_basename' as it's more solid
        let RenameTags = {key,val -> substitute(val,
                    \ '\(\s*\)@'.title,
                    \ '\1@'.buf_replacement,
                    \ 'g')}
        call map(filebody, RenameTags)
        call writefile(filebody, s:main_dir . basename)
        call s:redraw_file(s:main_dir . basename)
    endfor

    " Replace all 'buf_title' with 'buf_replacement' in current buffer
    let buf_filename = s:main_dir . buf_basename
    let buf_filebody = readfile(buf_filename)
    call map(buf_filebody, 'substitute(v:val, buf_title, buf_replacement, "")')
    call writefile(buf_filebody, buf_filename)
    call s:redraw_file(buf_filename)
endfunction

function! s:tag_note(req) abort
    write
    let buf_tags = getline(2)
    let tags = s:to_filetags(a:req.previewbodies)
    " tags are seperated with ' @'
    let tags = trim(buf_tags.' '.tags)
    let tags = split(tags, '@')
    let tags = map(tags, 'trim(v:val)')
    let tags = uniq(sort(tags))
    call setline(2, '@' . join(tags, ' @'))
    write
endfunction

"=========================== Keymap ========================================

" unusable/iffy/usuable
" a c e m n p u w y
" j k l
" d l r t z
" b f g h o q r s v

" t=tag → tag zettels
let s:tag_note_key = get(g:, 'z_tag_note_key', 'ctrl-t')
" r=remove link → unlink buffer with selection list
let s:remove_tags_key = get(g:, 'z_remove_tag_key', 'ctrl-r')
" d=delete → delete all selected notes, asks user for confirmation
let s:delete_note_key = get(g:, 'z_delete_note_key', 'ctrl-d')
" c=change → change(rename) the header of selected files to 'input()'
let s:rename_notes_key = get(g:, 'z_rename_notes_key', 'ctrl-c')
" z=zettel → create a new zettel
let s:new_note_key = get(g:, 'z_new_note_key', 'ctrl-z')

let s:default_command = 'edit'
let s:commands = get(g:, 'z_commands',
            \ {'ctrl-s': 'split',
            \ 'ctrl-v': 'vertical split',
            \ 'ctrl-t': 'tabedit',
            \ })

let s:create_note_window = get(g:, 'z_create_note_window', 'edit ')

let s:actions = {
            \ s:tag_note_key: function("s:tag_note"),
            \ s:remove_tags_key: function("s:remove_tags"),
            \ s:delete_note_key: function("s:delete_note"),
            \ s:rename_notes_key: function("s:rename_note"),
            \ s:new_note_key: function("s:new_note"),
            \ }
let s:keymap = extend(copy(s:commands), s:actions)

" FZF expects a comma separated string.
let s:expect_keys = join(keys(s:keymap) + get(g:, 'z_expect_keys', []), ',')



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
            \   '--tiebreak=' . 'begin,length' ,
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
        " link [0]=match [1]=scheme [2]=www [3]=rest [4]=resource
        let link = matchlist(reg, '\v^(\w+)://(www\.)?(.{-})/(.{-})(/)?$')
        let link[3:4] = map(link[3:4], "tr(v:val, '/-_+', ':   ')")
        let link = s:create_link(join(link[3:4], ':'), reg)
        call setreg('+', link)
    catch /^Vim\%((\a\+)\)\=:E684/
    endtry
endfunction

function! s:create_link(title, filename)
    return '[' . a:title . '](' . a:filename . ')'
endfunction

command! ToMarkdownLink call s:clean_http_link()
