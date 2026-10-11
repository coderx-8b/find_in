local M = {}
local function file() return require("find_in.config").get().persistence.file end
function M.read()
  if not require("find_in.config").get().persistence.enabled then return nil end
  local f = io.open(file(), "r"); if not f then return nil end
  local data = f:read("*a"); f:close()
  local ok, decoded = pcall(vim.json.decode, data)
  if ok and type(decoded) == "table" and type(decoded.abs) == "string" then return decoded end
end
function M.write(dir)
  if not require("find_in.config").get().persistence.enabled then return true end
  local path = file(); vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f, err = io.open(path, "w"); if not f then return nil, err end
  f:write(vim.json.encode(dir)); f:close(); return true
end
function M.clear()
  local path = file(); if vim.fn.filereadable(path) == 1 then vim.fn.delete(path) end
end
return M
