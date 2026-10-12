# find_in.nvim

A self-contained Neovim file finder using asynchronous `rg --files` and a native floating window. Requires Neovim 0.11+ and ripgrep (`rg`).

```lua
require("find_in").setup({})
```

Run `:FindIn` to search the current working directory. Use `:FindIn path` to search a path relative to `$HOME`, or an absolute path. `:FindInCached`, `:FindInSetDir`, `:FindInCwd`, and `:FindInResetCache` manage the persistent directory bookmark. Inside the picker, `<C-a>` opens a chooser for the last 10 paths added; choose “Add directory…” to search a new path and add it to the recent paths list. This does not change the bookmarked directory; use `<C-d>` to bookmark the current directory. `<C-c>` switches directly to the bookmarked path. `require("find_in")` exposes `open`, `open_cached`, `set_dir`, `open_cwd`, `reset_cache`, `get_active_dir`, and `get_cached_dir`.

The picker opens as a single floating list. Type in normal mode to filter; matches are ranked by how tightly and how early the query matches. Prefix a query with `'` for an exact substring, `^` for a prefix match, or `*` to force fuzzy matching; append `$` for a suffix match. `<C-u>` clears the query and Backspace removes its last character. Use `<C-n>`/`<C-p>` (or arrows) to navigate, Enter to open, `q`/Escape to close, and the border shows the query, active directory, and match counts. Vertical/horizontal splits, tabs, cached/CWD switching, bookmarking, and rescanning are also available.

See `:help find_in` or [doc/find_in.txt](doc/find_in.txt) for configuration and mappings.

## Updating a local copy

To install or update this checkout as a native Neovim package, run:

```sh
./install-local.sh
```

The script syncs the plugin to `stdpath("data")/site/pack/local/start/find_in` (by default, `~/.local/share/nvim/site/pack/local/start/find_in`). It uses `XDG_DATA_HOME` when set and requires `rsync`. Restart Neovim after syncing. To use a different plugin directory, pass it as the first argument:

```sh
./install-local.sh /path/to/nvim/site/pack/local/start/find_in
```
