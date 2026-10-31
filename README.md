# folder-notes.yazi

[![Yazi](https://img.shields.io/badge/Yazi-%E2%89%A5%2026.8.15-blue)](https://github.com/sxyazi/yazi)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A [Yazi](https://github.com/sxyazi/yazi) plugin that shows a **note / description for each folder** (files work too), and lets you add, edit and remove those notes without leaving Yazi.

English | [简体中文](README.zh-CN.md)

```
  Downloads ▏installers, temp files     - 2026-10-30 20:51
  Pictures  ▏screenshots, wallpapers    - 2026-10-30 17:54
  Projects                              - 2026-10-30 17:54
  ...

  ccjjxl@arch:~/Pictures (screenshots, wallpapers)
```

## Features

- **Inline notes** — the note is shown right after the folder name in the file list (default),
  so you can see what every directory is for at a glance.
- **Optional linemode column** — or show notes in a dedicated column on the right instead.
- **Status bar** — the full note of the hovered item, in case the inline one is truncated.
- **Header** — the note of the current directory, so you always know where you are.
- **Add / edit / delete** with a single key; an empty input deletes the note.
- **Plain-text notes file** — hand-editable, comments and ordering are preserved when the
  plugin saves a note. Auto-reloads when the file changes (on directory load).
- **Theme aware** — style and prefix are configurable from `theme.toml`.
- **Toggle** — hide all notes temporarily with one key.

## Requirements

- Yazi **26.8.15** or newer.

## Installation

### Via `ya pkg`

```bash
ya pkg add ccjjxl/folder-notes
```

### Manually

```bash
git clone https://github.com/ccjjxl/folder-notes.yazi.git \
  ~/.config/yazi/plugins/folder-notes.yazi
```

Or, if you want to hack on it, symlink a clone/checkout instead:

```bash
mkdir -p ~/.config/yazi/plugins
ln -sfn /path/to/folder-notes.yazi ~/.config/yazi/plugins/folder-notes.yazi
```

Then add the plugin to `~/.config/yazi/init.lua`:

```lua
require("folder-notes"):setup()
```

### Key bindings

`~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "M"
run  = "plugin folder-notes -- set"
desc = "Set/edit the note of the hovered item"

[[mgr.prepend_keymap]]
on   = [ "g", "M" ]
run  = "plugin folder-notes -- set-cwd"
desc = "Set/edit the note of the current directory"

[[mgr.prepend_keymap]]
on   = "<C-n>"
run  = "plugin folder-notes -- toggle"
desc = "Toggle folder notes"
```

## Usage

| Key | Action |
| --- | --- |
| `M` | Edit the note of the hovered item. Submit an empty value to delete it. |
| `g M` | Edit the note of the current directory (useful right after entering it). |
| `<C-n>` | Show / hide all notes temporarily. |

When the input box opens, it is pre-filled with the existing note, so you can append to it
or clear it. Notes are saved to disk immediately and the UI is refreshed.

Notes work for **files too** — nothing stops you from annotating a README or an important
archive.

## Notes file

Default location: `~/.config/yazi/folder-notes.conf` (change it with the `file` option).

```conf
# Lines starting with # are comments, blank lines are ignored.
~/Downloads        = installers and temp files, clean up regularly
/data/Developments = development projects, grouped by language/purpose
/mnt/usb/backup    = external drive, backup on the 1st of every month
```

Rules:

- One entry per line: `path = note`. The **first** `=` splits the line, the rest is the note,
  so notes can contain `=`, spaces, punctuation, unicode, etc.
- Paths may be absolute or start with `~/` (expanded to your home directory).
  A trailing `/` is optional and ignored.
- Paths are literal — no globbing, no Lua patterns.
- Notes are single-line; newlines are turned into spaces when saving.
- Saving only touches the matching line: comments, ordering and unrelated entries are kept.
- Notes are keyed by the **absolute path**, so they do not follow a folder that is moved or
  renamed; a symlinked folder has its own note.

## Configuration

All options are optional:

```lua
require("folder-notes"):setup {
	file = "~/.config/yazi/folder-notes.conf", -- notes file
	inline = true,                             -- show notes after the file name
	inline_width = 0,                          -- max width of inline notes (0 = only Yazi's natural truncation)
	linemode = false,                          -- also show notes in a dedicated right-hand column
	linemode_width = 20,                       -- max width of the linemode column
	status = true,                             -- show the hovered item's note in the status bar
	status_width = 80,                         -- max width in the status bar
	header = true,                             -- show the current directory's note in the header
	header_width = 48,                         -- max width in the header
	shown = true,                              -- start with notes visible
	order = 1600,                              -- sort weight for the linemode/header children
}
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `file` | string | `~/.config/yazi/folder-notes.conf` | Notes file. `~/` is expanded. |
| `inline` | boolean | `true` | Show the note right after the name in the list. |
| `inline_width` | integer | `0` | Max width (cells) of inline notes. `0` = don't pre-truncate; Yazi truncates to fit the pane. |
| `linemode` | boolean | `false` | Additionally render notes in a separate right-hand linemode column. |
| `linemode_width` | integer | `20` | Max width (cells) of the linemode column. |
| `status` | boolean | `true` | Show the hovered item's note in the status bar. |
| `status_width` | integer | `80` | Max width in the status bar. |
| `header` | boolean | `true` | Show the current directory's note in the header. |
| `header_width` | integer | `48` | Max width in the header. |
| `shown` | boolean | `true` | Whether notes are visible on startup. |
| `order` | integer | `1600` | Sort weight of the linemode/header children (change it if another plugin collides). |

## Commands

| Command | Description |
| --- | --- |
| `plugin folder-notes` | Toggle notes on/off (same as `-- toggle`). |
| `plugin folder-notes -- set` | Set / edit the note of the hovered item. Empty input deletes it. |
| `plugin folder-notes -- set-cwd` | Set / edit the note of the current directory. |
| `plugin folder-notes -- delete` | Delete the note of the hovered item. |
| `plugin folder-notes -- reload` | Reload the notes file from disk. |
| `plugin folder-notes -- edit` | Open the notes file in `$EDITOR`. |

The notes file is also reloaded automatically after every directory load, so external edits
show up as soon as you navigate.

## Theme

`~/.config/yazi/theme.toml`:

```toml
[folder-notes]
# Style of the note text (dark gray + italic by default).
note = { fg = "darkgray", italic = true }
# Prefix rendered before the note. Set to "" to render the note as-is.
prefix = "▏"
```

## Tips

- **Keep notes short.** The inline note shares space with the file name, so a label like
  `存档项目` / `backup` is usually enough; longer texts still survive in the status bar and
  header.
- **Narrow panes?** Pressing `<C-n>` hides all notes instantly. You can also set
  `inline = false` (status bar + header only), or use `linemode = true, inline = false` for
  one aligned column, or give the current pane more room via `mgr.ratio`.
- **Which path to annotate?** `M` annotates the hovered child (e.g. while listing a parent
  folder), `g M` annotates the folder you are currently inside.
- **Version your notes.** `folder-notes.conf` is a plain text file — commit it with your
  dotfiles.

## How it works

The plugin is a thin layer on top of Yazi components:

- It registers children on `Entity` (inline notes), `Linemode` (optional column), `Status`
  and `Header`, so it never patches Yazi's built-in components.
- Notes are read/written with plain Lua `io`; no external commands are spawned.
- Yazi runs plugin entry points in a separate Lua state from the one that renders the UI.
  Shared state (the loaded notes and the visibility flag) is therefore updated through
  `ya.sync()` blocks that run in the main state, followed by `ui.render()`.
- The notes file is re-read on the `load` pub/sub event, which gives you external-edit
  reloads for free.

## Development

```bash
git clone https://github.com/ccjjxl/folder-notes.yazi.git
ln -sfn "$PWD/folder-notes.yazi" ~/.config/yazi/plugins/folder-notes.yazi
```

Yazi caches plugin code at startup, so restart Yazi (or use
`plugin folder-notes -- reload` for the notes file only) after editing `main.lua`.

## License

[MIT](LICENSE)
