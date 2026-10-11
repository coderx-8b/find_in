# find_in.nvim

A self-contained Neovim file finder using asynchronous `rg --files` and a native floating window. Requires Neovim with `vim.system()` support and ripgrep (`rg`).

```lua
require("find_in").setup({})
```

Run `:FindIn` to search the current working directory. Use `:FindIn path` to search a path relative to `$HOME`, or an absolute path. `:FindInCached`, `:FindInSetDir`, `:FindInCwd`, and `:FindInResetCache` manage the persistent directory bookmark. `require("find_in")` exposes `open`, `open_cached`, `set_dir`, `open_cwd`, `reset_cache`, `get_active_dir`, and `get_cached_dir`.

The floating picker opens with its filter field on the first line, ready for typing. Results update as you type a substring or fuzzy query; leave insert mode to return to navigation. It also supports `j`/`k`, Enter, `q`, vertical/horizontal splits, tabs, cached/CWD switching, bookmarking, and rescanning. `<C-p>` prompts for a directory, so it is not also bound to move up.

See `:help find_in` or [doc/find_in.txt](doc/find_in.txt) for configuration and mappings.
