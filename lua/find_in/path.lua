local M = {}
local uv = vim.uv or vim.loop

local function normalize(path)
  path = path:gsub("\\", "/"):gsub("/+", "/")
  if path == "" then return "." end
  if #path > 1 then path = path:gsub("/$", "") end
  return path
end

function M.home() return normalize(vim.env.HOME or vim.fn.expand("~")) end
function M.parse(path, base)
  if type(path) ~= "string" or path == "" then return nil, "path is empty" end
  path = path:gsub("\\", "/")
  local home = M.home()
  if path == "~" then path = home elseif path:sub(1, 2) == "~/" then path = home .. "/" .. path:sub(3)
  elseif not path:match("^/") and not path:match("^%a:/") then path = (base or home) .. "/" .. path end
  path = normalize(vim.fn.fnamemodify(path, ":p"))
  local st = uv.fs_stat(path)
  if not st or st.type ~= "directory" then return nil, "not a directory: " .. path end
  return { abs = path, rel = M.format(path) }
end

function M.format(path)
  path = normalize(path)
  local home = M.home()
  if path == home then return "~" end
  if path:sub(1, #home + 1) == home .. "/" then return "~/" .. path:sub(#home + 2) end
  return path
end
return M
