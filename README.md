# Vim Zettelkasten
*a vim and [fzf](https://github.com/junegunn/fzf) implementation of a [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten).*

The general ideas are:
1. Quickly add notes and reduce decision fatigue. Achieved by forming a graph structure like your brain.
1. Have notes which are atomic, well thought out, deep, concise, and analyze connections.
1. Facilitate the realization of connections between seemingly distinct ideas.
1. Provide a fast and intuitive infrastructure for creating, editing, viewing, and recalling your notes.
1. Provide 'low-level' interface to searching notes to *adapt to the user*, not the other way around.
1. Generic enough to work for all of your notes, ideas, todos, etc.
1. Use text-based, markdown format so you have full freedom with your ideas.
1. Easily search for and find what you want.

## File Format
The program expects the first line of the file to have 'tags', each of which start with an `@` and are directly preceeded by a variable amount of non space characters, then a space (unless it begin the line). An example:
```
@Tag1 @Tag2 @Tag with spaces 0@Tag3 1@Tag4 abc@Tag5 abc@Tag6 0@Tag4 0@Tag with spaces
Rest of file text here...
```

You may notice there are no titles, like maybe `# My title`. I find titles ambiguous and it is often difficult to find a semantic and intuitive title. A simple unique tag often works just as well.

## Functionality
The program then provides functionality as follows:
| Command | Description |
| ----- | ---- |
| tab   | Select a file which some operations act on |
| `<c-o>` | Create a new file |
| `<c-t>` | Take selected files, user input, and tag each selected file with user input |
| `<c-r>` | Take selected files, interpret user input as a tag, and remove tag wherever referred in selected files |
| `<c-d>` | Delete all selected files |

## Use
The primary command is `:Zettel` (and `:ZettelVisual` which uses the visual selection as search text). The program uses fzf to search the notes directory and defaults on literal (non-fuzzy) searching. This enables one, for example, to search `@Book` to find all notes which tag `Book`. How to search for a specific book? How about `@Book @Hyperfocus @Chris\ Bailey` (notice the `\ ` which searches for a literal space, as normally a space breaks up the search in fzf). I hope you find similar use as well.

## Notes
- Configurable options are: `z_main_dir`, `z_default_extension`, `z_window_direction`, `z_window_width`, `z_window_command`, `z_preview_direction`, `z_wrap_preview_text`, `z_show_preview`, `z_use_ignore_files`, `z_include_hidden`, `z_preview_width`
- I recommend choosing tags in relation to how you actually want to *search for notes*, nothing more.
- I use this program for just about everything. Notes on books, thoughts, todo lists, tracking resources, and plenty more.

## Possible updates
- Have an option to select a random note (maybe using `sort -R` or `shuf`).

## Permissions
Do what ever you want with this code.
