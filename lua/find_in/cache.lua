local M = {}
local function file() return require("find_in.config").get().persistence.file end
function M.read()
  if not require("find_in.config").get().persistence.enabled then return nil end
  local f = io.open(file(), "r"); if not f then return nil end
  local data = f:read("*a"); f:close()
  local ok, decoded = pcall(vim.json.decode, data)
  if ok and type(decoded) == "table" and type(decoded.abs) == "string" then return decoded end
end
function M.read_paths()
  local data = M.read()
  if not data or type(data.paths) ~= "table" then return {} end
  local paths = {}
  for _, item in ipairs(data.paths) do
    if type(item) == "table" and type(item.abs) == "string" then
      paths[#paths + 1] = item
      if #paths == 10 then break end
    end
  end
  return paths
end
function M.write(dir)
  if not require("find_in.config").get().persistence.enabled then return true end
  if type(dir.paths) ~= "table" then
    local current = M.read()
    if current and type(current.paths) == "table" then dir.paths = current.paths end
  end
  local path = file(); vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f, err = io.open(path, "w"); if not f then return nil, err end
  f:write(vim.json.encode(dir)); f:close(); return true
end
function M.add_path(dir)
  local data = M.read() or {}
  local paths = {}
  for _, item in ipairs(data.paths or {}) do
    if type(item) == "table" and type(item.abs) == "string" and item.abs ~= dir.abs then
      paths[#paths + 1] = item
    end
  end
  table.insert(paths, 1, dir)
  while #paths > 10 do table.remove(paths) end
  data.paths = paths
  data.abs, data.rel = dir.abs, dir.rel
  return M.write(data)
end
function M.clear()
  local path = file(); if vim.fn.filereadable(path) == 1 then vim.fn.delete(path) end
end
return M
