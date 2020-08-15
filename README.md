# Vim Zettelkasten
*an interpretation and implementation of the Zettelkasten technique.*

**If you don't know what a [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten), I recommend you look it up. However, the general ideas are:**
1. Have notes which are atomic, very well thought out, short, and concise.
1. Have connections between notes, these are very important.
1. Remove the intrinsic meaning of hierarchies (This package does this by allowing you to have an infinite amount.)
1. Facilitate the realization of connections between seemingly distinct ideas.
1. A one stop shop for all of your notes and ideas.

**Goals**
- The goal of this implementation is to provide a very fast and intuitive infrastructure for creating, editing, and viewing your notes.

**Notes**
- This package assumes you are using `$HOME/notes` for your notes.
- Only tested on Linux, should work on macOS, probably won't work on Windows.
- This uses $'\f' characters to separate items and may be an issue.
- Configurable options are: `z_main_dir`, `z_default_extension`, `z_window_direction`, `z_window_width`, `z_window_command`, `z_preview_direction`, `z_wrap_preview_text`, `z_show_preview`, `z_use_ignore_files`, `z_include_hidden`, `z_preview_width`
- Sorts by date created so the most recent note will be instantly accessible.
- The goal is to have the markdown function best in the terminal but still have it look decent in markdown format in the browser.
