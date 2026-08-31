# simpleterminal.nvim

One floating terminal, toggled in and out of view.

The terminal buffer and its shell are created on first use and then reused, so
hiding the window and bringing it back drops you into the same session with its
scrollback intact. Hiding does not kill the shell.

Requires Neovim 0.10+.

## Install

With Neovim's built-in `vim.pack` (0.12+):

```lua
vim.pack.add({ "https://github.com/rako233/simpleterminal.nvim" })
require("simpleterminal").setup({ keymap = "<leader>ut" })
```
From a local checkout, without a plugin manager:

```lua
vim.opt.runtimepath:prepend(vim.fn.expand("~/Projects/simpleterminal"))
require("simpleterminal").setup({ keymap = "<leader>ut" })
```

`setup()` is optional — `:SimpleTerminal` works without it. Call it to change
defaults or to have the plugin create a mapping.

## Usage

| | |
| --- | --- |
| `:SimpleTerminal` | Toggle the terminal |
| `:SimpleTerminal open` | Open, or focus it if already visible |
| `:SimpleTerminal close` | Hide it, leaving the shell running |

```lua
local term = require("simpleterminal")
term.toggle()
term.open()      -- returns the window handle
term.close()
term.is_open()
```

## Configuration

Defaults:

```lua
require("simpleterminal").setup({
  width = 0.8,          -- fraction of the screen when <= 1, absolute columns when > 1
  height = 0.8,         -- likewise for rows; excludes 'cmdheight'
  border = "rounded",   -- any nvim_open_win() border
  title = nil,          -- needs a border other than "none"
  cmd = nil,            -- command to run; nil means 'shell'
  start_insert = true,  -- enter terminal-mode on open
  close_on_exit = true, -- on `exit`, close the window and start fresh next time
  colors = nil,         -- colors for this terminal only; nil follows the colorscheme
  keymap = false,       -- lhs for toggle(), created by setup() only
})
```

## Colors

`colors` paints only this terminal, leaving the rest of the editor on your
colorscheme. It takes a Ghostty theme, read straight from the file:

```lua
require("simpleterminal").setup({
  colors = require("simpleterminal.ghostty").load("~/.config/ghostty/themes/mytheme"),
})
```

A full `ghostty/config` works too — non-color keys are ignored. The keys read
are `palette = N=#rrggbb` (0-15), `background`, `foreground`, `cursor-color`,
`cursor-text`, `selection-background` and `selection-foreground`.

Ghostty's `cell-foreground` and `cell-background` keywords are resolved against
the theme's own `foreground`/`background`. A color Neovim cannot parse warns and
is skipped rather than aborting `setup()`.

Or hand it a table directly:

```lua
colors = {
  palette = { [1] = "#c01c28", [4] = "#1e78e4" },  -- sparse is fine
  background = "#1c1c1f",
  foreground = "#ffffff",
  cursor = "#ffffff",
  cursor_text = "#1c1c1f",
  selection_background = "#ffffff",
  selection_foreground = "#1c1c1f",
}
```

Scoping: the 16 ANSI colors are set as buffer-local `b:terminal_color_x`, and
the window colors go through `'winhighlight'`, so no other terminal or window
is affected. Needs `'termguicolors'`; `setup()` warns if it is off.

The highlight groups are `SimpleTerminalNormal`, `SimpleTerminalBorder`,
`SimpleTerminalTitle`, `SimpleTerminalCursor` and `SimpleTerminalSelection`,
redefined after `:colorscheme`, so you can override them yourself.

The plugin never maps a key on its own — only `setup()` does, and only when
`keymap` is a string.

See `:help simpleterminal` for the full reference.

## Notes

A window sized as a fraction is re-centered on `VimResized`. Sizes are derived
from `'columns'`/`'lines'` rather than `nvim_list_uis()`, so it also behaves
with no UI attached.

## License

MIT
