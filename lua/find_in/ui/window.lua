local M = {}
function M.size(value, maximum, minimum)
  local n = type(value) == "number" and value or 0.7
  if n > 0 and n <= 1 then n = math.floor(maximum * n) end
  return math.max(minimum, math.min(maximum, math.floor(n)))
end
function M.open()
  local cfg, columns, lines = require("find_in.config").get().ui, vim.o.columns, vim.o.lines
  local width = M.size(cfg.width, columns - 4, 40); local height = M.size(cfg.height, lines - 6, 10)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, { relative = "editor", style = "minimal", width = width, height = height,
    row = math.floor((lines - height) / 2) - 1, col = math.floor((columns - width) / 2), border = cfg.border,
    title = " > ", title_pos = "left", footer = "  0 | 0 / 0 ", footer_pos = "right" })
  vim.bo[buf].buftype = "nofile"; vim.bo[buf].bufhidden = "wipe"; vim.bo[buf].swapfile = false
  vim.wo[win].cursorline = true; vim.wo[win].wrap = false; vim.wo[win].signcolumn = "no"
  return buf, win
end
return M
