local M = {}

M.defaults = {
  initial_dir = "cwd",
  persistence = { enabled = true, file = nil },
  ripgrep = {
    binary = "rg", hidden = false, follow_symlinks = true,
    respect_gitignore = true, globs = { "!.git/*" }, additional_args = {},
  },
  ui = { width = 0.7, height = 0.6, border = "rounded", icons = true, prompt = "Filter: " },
  mappings = {
    open = { "<CR>", "l" }, split = { "<C-x>", "<C-s>" }, vsplit = { "<C-v>" }, tab = { "<C-t>" },
    close = { "q", "<Esc>" }, down = { "j", "<Down>", "<C-n>" }, up = { "k", "<Up>" },
    switch_cached = "<C-c>", switch_path = "<C-p>", switch_cwd = "<C-.>", bookmark = "<C-d>", refresh = "<C-r>",
  },
}

local function merge(dst, src)
  for k, v in pairs(src or {}) do
    if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) else dst[k] = v end
  end
  return dst
end

function M.setup(opts)
  local config = merge(vim.deepcopy(M.defaults), opts or {})
  if not config.persistence.file then config.persistence.file = vim.fn.stdpath("state") .. "/find_in/cache.json" end
  M.options = config
  return config
end

function M.get() return M.options or M.setup() end
return M
