local M = {}
function M.scan(dir, callback)
  local cfg, state = require("find_in.config").get().ripgrep, require("find_in.state")
  state.cancel(); local id = state.scan_id
  if vim.fn.executable(cfg.binary) ~= 1 then
    vim.notify("[find_in.nvim] 'ripgrep' (rg) is required but not found in PATH.", vim.log.levels.ERROR); callback({}); return
  end
  local args = { cfg.binary, "--files" }
  if cfg.hidden then args[#args + 1] = "--hidden" end
  if cfg.follow_symlinks then args[#args + 1] = "--follow" end
  if not cfg.respect_gitignore then args[#args + 1] = "--no-ignore" end
  for _, glob in ipairs(cfg.globs or {}) do args[#args + 1] = "-g"; args[#args + 1] = glob end
  vim.list_extend(args, cfg.additional_args or {}); args[#args + 1] = dir.abs
  local ok, proc = pcall(vim.system, args, { text = true }, function(result)
    vim.schedule(function()
      if id ~= state.scan_id then return end
      state.process = nil
      local files = {}; for line in (result.stdout or ""):gmatch("[^\r\n]+") do
        if line:sub(1, #dir.abs + 1) == dir.abs .. "/" then line = line:sub(#dir.abs + 2) end
        files[#files + 1] = line
      end
      table.sort(files); callback(files, result.code ~= 0 and result.stderr or nil)
    end)
  end)
  if ok then state.process = proc else callback({}, tostring(proc)) end
end
return M
