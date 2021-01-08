# Vim Zettelkasten
*a vim and [fzf](https://github.com/junegunn/fzf) implementation of a [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten).*

The general ideas are:
1. Have notes which are atomic, very well thought out, deep, short, and concise.
1. Have notes analyze connections.
1. Remove meaning of hierarchies in notes by forming a directed graph structure.
1. Facilitate the realization of connections between seemingly distinct ideas.
1. A one stop shop for all of your notes, ideas, todos, etc.
1. Provide a fast and intuitive infrastructure for creating, editing, viewing, and recalling your notes.
1. Have notes function like your brain.
1. Provide 'low-level' interface to searching notes to adapt to the user, not the other way around.

## File Format
The program expects the first line of the file to have 'tags', each of which start with an `@` and are preceeded by a space (or begin the line). An example:
```
@Tag1 @Tag2 @Tag with spaces @...
Rest of file text here...
```

## Functionality
The program then provides functionality as follows:
| Command | Description |
| ----- | ---- |
| `<c-o>` |  Create a new file |
| `<c-t>` |  Take selected files, user input, and tag each selected file with user input |
| `<c-r>` | Take selected files, interpret user input as a tag, and remove tag wherever referred in selected files |
| `<c-d>` | Delete all selected files |

## Use
The command is `:Zettel` (and `:ZettelVisual` which uses the visual selection as search text). The program uses fzf to search the notes directory and defaults on literal (non-fuzzy) searching. This enables one, for example, to search `@Book` to find all notes which tag `Book`. How to search for a specific book? How about `@Book @Hyper focus @Chris Bailey` (I just copied the first line of a random note). Note to include spaces in the search use `\ `.

## Notes
- Configurable options are: `z_main_dir`, `z_default_extension`, `z_window_direction`, `z_window_width`, `z_window_command`, `z_preview_direction`, `z_wrap_preview_text`, `z_show_preview`, `z_use_ignore_files`, `z_include_hidden`, `z_preview_width`
- I use this program for just about everything. Notes on books, thoughts, todo lists, tracking resources, and plenty more.

## Possible updates
- Have an option to select a random note (maybe using `sort -R` or `shuf`).
