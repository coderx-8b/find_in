local M = {}
function M.complete(arglead)
  local home = require("find_in.path").home()
  local prefix = arglead:gsub("^~/?", ""):gsub("\\", "/")
  local dir, base = prefix:match("^(.*[/])([^/]*)$"); dir, base = dir or "", base or prefix
  local absdir = home .. "/" .. dir
  local entries = vim.fn.glob(absdir .. "*", false, true)
  local out = {}
  for _, entry in ipairs(entries) do
    if vim.fn.isdirectory(entry) == 1 then
      local rel = entry:gsub("^" .. vim.pesc(home) .. "/?", "")
      if rel:sub(1, #prefix) == prefix then out[#out + 1] = rel end
    end
  end
  return out
end
return M
