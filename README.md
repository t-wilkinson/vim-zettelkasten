# Vim Zettelkasten
*a vim implementation of a [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten).*

The general ideas are:
1. Have notes which are atomic, very well thought out, short, and concise.
1. Have connections between notes, these are very important.
1. Remove the intrinsic meaning of hierarchies, achieved in this implementation through the graph structure tags form.
1. Facilitate the realization of connections between seemingly distinct ideas.
1. A one stop shop for all of your notes and ideas.
1. Provide a fast and intuitive infrastructure for creating, editing, and viewing your notes.
1. Organize your notes like your brain

## File Format
The program expects the first line of the file to have 'tags' (which can have spaces), each of which start with an `@`. Note that also to be recognized as a tag, the `@` must be at the start of the line or be preceeded by a space. An example:
```
@Tag1 @Tag2 @Tag with spaces @...
Rest of file text here...
```

## Functionality
| Key | Description |
| ----- | ---- |
| `<c-o>` |  Create a new file |
| `<c-t>` |  Take selected files, user input, and tag each selected file with user input |
| `<c-r>` | Take selected files, interpret user input as a tag, and remove tag wherever referred in selected files |
| `<c-d>` | Delete all selected files |

## Notes
- Configurable options are: `z_main_dir`, `z_default_extension`, `z_window_direction`, `z_window_width`, `z_window_command`, `z_preview_direction`, `z_wrap_preview_text`, `z_show_preview`, `z_use_ignore_files`, `z_include_hidden`, `z_preview_width`
