# Specification: `find_in.nvim`

A **self-contained** Neovim plugin for fast recursive file discovery with an interactive floating UI inspired by `mini.files`. Powered by **ripgrep (`rg --files`)** asynchronously, it requires **zero external Lua picker dependencies**.

By default, the plugin initializes its search root to **the directory where Neovim is running** (`vim.fn.getcwd()`), while providing instant keymaps and commands to switch searching between the **launch CWD**, a **cached folder**, or **any typed folder relative to `$HOME`**.

---

## 1. Design Philosophy & Goals

1. **Self-Contained (Zero External Lua Dependencies)**:
   - Does not require Telescope, fzf-lua, or Snacks.
   - Implements its own native, highly responsive floating window UI using core Neovim Lua APIs (`nvim_open_win`, buffers, extmarks, highlights).
   - The only external requirement is `ripgrep` (`rg`) for multi-threaded file listing.
2. **Aesthetics & Ergonomics Inspired by `mini.files`**:
   - Clean, centered floating window with subtle borders and clear path indicators.
   - Buffer-local, intuitive Vim keybindings (`j`/`k`, `<CR>`, `q`, `<C-v>`, `<C-s>`).
   - Integrated live filtering for instantaneous item narrowing.
   - Optional file icons (auto-detects `mini.icons` or `nvim-web-devicons` if available, falls back gracefully to plain text).
3. **Frictionless Path Switching**:
   - **Default**: Opens immediately in the directory where Neovim is running (`getcwd()`).
   - **In-UI Keymaps**: Switch search root dynamically while inside the UI (e.g., `<C-c>` for cached folder, `<C-a>` to add or choose a path, `<C-.>` to return to CWD) without closing and reopening.
   - **Persistent Cache**: Remembers custom folders across invocations and Neovim sessions.

---

## 2. Core Functional Requirements

### 2.1 Default Launch Directory (CWD)
- On startup, the default search root is the directory where Neovim is running (`vim.fn.getcwd()`).
- If the CWD is inside `$HOME`, it is displayed relative to home (e.g., `~/Projects/my-app`).
- First-time invocation opens immediately without prompts or configuration.

### 2.2 In-UI Path Switching Keymaps
While the `find_in` floating window is open, the user can change the search root on the fly:
- **Switch to Cached Directory** (`<C-c>`): Instantly triggers ripgrep in the saved cached folder and refreshes the file list.
- **Add/Choose Directory** (`<C-a>`): Chooses a recent path or prompts for one relative to `$HOME` (with tab completion). A new path becomes active, is saved to the recent paths list, and refreshes the file list without changing the cached directory. Use `<C-d>` to bookmark the active directory.
- **Revert to Launch CWD** (`<C-.>`): Resets the search root back to `vim.fn.getcwd()`.
- **Save Current to Cache** (`<C-s>`): Saves the current active directory as the persistent cached target.
- **Refresh/Rescan** (`<C-r>`): Re-runs ripgrep to pick up newly created or deleted files.

### 2.3 Home-Relative Path Parsing
- Any directory input (command line or interactive prompt) is parsed relative to the user's home directory (`$HOME`).
- Accepts raw relative paths (`Projects/web-app`), tilde prefixes (`~/Projects/web-app`), and absolute paths.

### 2.4 Asynchronous Ripgrep Engine
- File collection runs via `rg --files` executed asynchronously using `vim.system()`.
- Guaranteed non-blocking: UI remains responsive even when indexing directories with 100,000+ files.
- If the user switches directories before a running ripgrep search finishes, the previous process is cancelled immediately to prevent race conditions.
- Respects `.gitignore` and `.ignore` files automatically.

### 2.5 Interactive Filtering
- Typing in normal mode filters the current ripgrep result set without editing the results buffer.
- Plain queries use fuzzy matching, ordered by match width and then earliest match position.
- Query modifiers follow `mini.pick`: `'text` matches an exact substring, `^text` matches a prefix, `text$` matches a suffix, and `*text` explicitly requests fuzzy matching.
- Backspace removes one character and `<C-u>` clears the query. Matching characters in the selected item are highlighted.

---

## 3. UI Design & Layout (mini.files Inspired)

```
┌── [Find In] ~/Projects/nvim_plugins/find_in ────── [Cached: ~/notes] ──┐
│ Filter: spec                                                           │
│────────────────────────────────────────────────────────────────────────│
│   lua/find_in/config.lua                                               │
│   lua/find_in/init.lua                                                 │
│ > Spec.md                                                              │
│   tests/spec_helper.lua                                                │
│                                                                        │
│                                                                        │
│                                                                        │
│────────────────────────────────────────────────────────────────────────│
│ <CR> open │ <C-v> vsplit │ <C-c> cached │ <C-a> add path │ <C-.> cwd │ q close │
└────────────────────────────────────────────── 4 files (filtered from 18) ┘
```

### 3.1 UI Elements
1. **Window Frame**:
   - Floating window centered on screen (configurable dimensions, default 70% width, 60% height).
   - Border style: `rounded` (configurable: `single`, `double`, `solid`).
2. **Title Bar**:
   - Shows active search directory formatted relative to `~`.
   - Right-aligned indicator showing the currently saved cached folder.
3. **Prompt / Border**:
   - The top border shows a caret, query, and active directory.
   - The bottom border shows the current match index, match count, and total item count.
   - Typing filters results in normal mode; `<Down>` / `<Up>` or `<C-j>` / `<C-k>` navigates items.
4. **Item List**:
   - Shows relative file paths from the active search root.
   - Directory parts are dimmed (`Comment` highlight), file names highlighted (`Function` or `Normal`).
   - File icon rendered if `mini.icons` or `nvim-web-devicons` is installed.
   - Cursor line highlights the active selection (`CursorLine`).
5. **Footer / Status Line**:
   - Left: Quick keymap hints (`<CR> open`, `<C-c> cached`, `<C-a> add path`, `<C-.> cwd`, `q close`).
   - Right: File count badge (`X files (filtered from Y)`).

---

## 4. Default Keymaps

### 4.1 In-UI Navigation & Selection

| Keymap | Action | Description |
| :--- | :--- | :--- |
| `<CR>` | Open File | Opens selected file in the current window and closes UI. |
| `<C-v>` | Split Vertical | Opens selected file in a vertical split and closes UI. |
| `<C-x>` / `<C-s>` | Split Horizontal | Opens selected file in a horizontal split and closes UI. |
| `<C-t>` | Open Tab | Opens selected file in a new tab page and closes UI. |
| `j` / `<Down>` / `<C-n>` | Cursor Down | Moves selection down one item. |
| `k` / `<Up>` | Cursor Up | Moves selection up one item. |
| `q` / `<Esc>` | Close | Closes the floating window cleanly. |

### 4.2 In-UI Path Switching Keymaps

| Keymap | Action | Description |
| :--- | :--- | :--- |
| `<C-c>` | Switch to Cached | Switches search directory to the saved cached folder. |
| `<C-a>` | Add/Choose Path | Chooses a recent path or prompts for a new path relative to `~`. |
| `<C-.>` | Switch to CWD | Reverts search directory to Neovim's working directory (`vim.fn.getcwd()`). |
| `<C-d>` | Bookmark to Cache | Sets the current active search directory as the new cached folder. |
| `<C-r>` | Rescan / Refresh | Reruns ripgrep in the active directory to refresh results. |

*Note: All keybindings are fully remappable via `setup()` configuration.*

---

## 5. Commands & Lua API

### 5.1 User Commands

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `:FindIn` | `[path]` | Opens UI in active folder (default: CWD). If path provided, sets active folder to path (relative to `~`). |
| `:FindInCached` | *None* | Opens UI in the persisted cached folder (prompts if none is set). |
| `:FindInSetDir` | `[path]` | Prompts for or sets the cached folder relative to `~`, then opens UI. |
| `:FindInCwd` | *None* | Resets active directory to Neovim's CWD and opens UI. |
| `:FindInResetCache` | *None* | Clears the saved cached folder from disk and memory. |

### 5.2 Lua API

```lua
local find_in = require("find_in")

-- Open UI in active directory (default: CWD or last selected)
find_in.open(opts)

-- Open UI in the persisted cached directory
find_in.open_cached(opts)

-- Set search directory to a path relative to ~ and open UI
find_in.set_dir(path_or_opts)

-- Reset active directory back to Neovim's cwd and open UI
find_in.open_cwd(opts)

-- Clear cached directory
find_in.reset_cache()

-- Query state
local active_dir = find_in.get_active_dir() -- { rel = "...", abs = "..." }
local cached_dir = find_in.get_cached_dir() -- { rel = "...", abs = "..." }
```

---

## 6. Architecture & File Structure

```
find_in.nvim/
├── doc/
│   └── find_in.txt             # Vimdoc documentation
├── lua/
│   └── find_in/
│       ├── init.lua            # Public API entry point
│       ├── config.lua          # Configuration schema, validation, defaults
│       ├── state.lua           # In-memory state (active dir, cached dir, process handle)
│       ├── cache.lua           # Persistent JSON storage in stdpath("state")
│       ├── path.lua            # Tilde expansion, normalization, home-relative formatting
│       ├── rg.lua              # Async ripgrep runner via vim.system() with cancel support
│       ├── filter.lua          # Pure Lua substring/fuzzy match filter & ranker
│       ├── complete.lua        # Directory autocompletion relative to $HOME
│       └── ui/
│           ├── init.lua        # UI controller (coordinates window, state, and events)
│           ├── window.lua      # Floating window creation, positioning, resizing
│           ├── render.lua      # Buffer drawing, syntax highlights, icon injection
│           └── keymaps.lua     # Buffer-local keybinding registration & dispatch
└── plugin/
    └── find_in.lua             # User command definitions & tab completion hooks
```

### Module Responsibilities:
- **`state.lua`**:
  - Initializes `active_dir` to `vim.fn.getcwd()`.
  - Tracks currently active directory vs. cached directory.
  - Stores reference to running ripgrep process object for instantaneous cancellation when switching paths.
- **`rg.lua`**:
  - Checks `vim.fn.executable("rg") == 1`.
  - Builds arguments: `rg --files [--hidden] [--follow] [-g ...]` targeting the directory.
  - Asynchronously spawns via `vim.system()`, accumulating lines into a table and passing to UI on complete.
- **`filter.lua`**:
  - Fast in-memory matching against file path list as user types in the filter input.
  - Ranks matches (exact prefix > file name match > deep path match).
- **`ui/window.lua`**:
  - Creates the floating window with calculated width/height and borders.
  - Sets window-local options (`cursorline = true`, `wrap = false`, `signcolumn = "no"`).
- **`ui/render.lua`**:
  - Formats paths with directory dimming and highlights.
  - Prepends icons if `mini.icons` or `nvim-web-devicons` is installed.
  - Renders custom header and footer badges.

---

## 7. Configuration & Defaults

```lua
require("find_in").setup({
  -- Initial search folder on Neovim startup:
  -- "cwd"    : Directory where Neovim is running (default, like mini.files)
  -- "cached" : Use the saved cached folder immediately
  -- string   : Specific path relative to $HOME (e.g. "Projects")
  initial_dir = "cwd",

  -- Persistence settings
  persistence = {
    enabled = true,
    file = vim.fn.stdpath("state") .. "/find_in/cache.json",
  },

  -- Ripgrep command settings
  ripgrep = {
    binary = "rg",              -- Name or path of ripgrep binary
    hidden = false,             -- Pass --hidden to search dotfiles
    follow_symlinks = true,      -- Pass -L/--follow
    respect_gitignore = true,    -- Respect .gitignore (false passes --no-ignore)
    globs = {                   -- Patterns passed via -g
      "!.git/*",
    },
    additional_args = {},       -- Extra CLI arguments
  },

  -- Floating Window UI Appearance
  ui = {
    width = 0.7,                -- Float width (ratio 0.0 - 1.0 or integer columns)
    height = 0.6,               -- Float height (ratio 0.0 - 1.0 or integer rows)
    border = "rounded",         -- "rounded" | "single" | "double" | "shadow"
    icons = true,               -- Use mini.icons or nvim-web-devicons if present
    prompt = "Filter: ",        -- Search prompt text
  },

  -- Buffer-local keymaps inside the floating window
  mappings = {
    -- File opening actions
    open = { "<CR>" },
    split = { "<C-x>", "<C-s>" },
    vsplit = { "<C-v>" },
    tab = { "<C-t>" },
    close = { "q", "<Esc>" },

    -- Navigation
    down = { "j", "<Down>", "<C-n>" },
    up = { "k", "<Up>" },

    -- Path switching actions
    switch_cached = "<C-c>",    -- Switch search to cached directory
    switch_path = "<C-a>",      -- Choose a recent path or enter one relative to ~
    switch_cwd = "<C-.>",       -- Revert search to Neovim launch CWD
    bookmark = "<C-d>",         -- Save current directory to cache
    refresh = "<C-r>",          -- Re-scan directory with ripgrep
  },
})
```

---

## 8. Requirements, Error Handling & Edge Cases

1. **Ripgrep Prerequisite**:
   - Requires `rg` on system `$PATH`. If missing, shows clear notification:
     `vim.notify("[find_in.nvim] 'ripgrep' (rg) is required but not found in PATH.", vim.log.levels.ERROR)`
2. **Process Cancellation on Fast Path Switch**:
   - When a user presses `<C-c>` or `<C-a>` while a scan is in progress, the active `vim.system` job is terminated immediately via `job:kill()` to eliminate stale UI updates and avoid wasting CPU.
3. **Non-Existent Directory**:
   - If user inputs an invalid directory relative to `~`, shows error notification and keeps previous valid search path intact.
4. **Empty Directories / Zero Results**:
   - Displays a clean inline placeholder (`No files found in <path>`) rather than an empty or broken window.
5. **Cross-Platform Path Support**:
   - Properly normalizes `/` on Linux/macOS and `\` on Windows.

---

## 9. Testing & Quality Assurance Plan

1. **Unit Tests (mini.test / Plenary)**:
   - `path.lua`: Home-relative parsing, `~` expansions, trailing slash normalization.
   - `cache.lua`: Read/write `cache.json`, graceful handling of corrupted JSON.
   - `filter.lua`: Fuzzy and substring filtering accuracy, ranking order, empty search string handling.
   - `rg.lua`: Command generation with varied flags (`--hidden`, `--follow`, globs).
2. **UI & Integration Tests**:
   - Floating window spawn, dimensions, and buffer cleanup on close.
   - Mocking `rg` output and verifying async rendering and live filtering.
   - Path switching keymaps (`<C-c>`, `<C-a>`, `<C-.>`) properly refresh buffer contents.
   - Process cancellation when switching directories while scan is running.
