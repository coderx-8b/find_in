local path = require("find_in.path")
local M = { process = nil, scan_id = 0 }
function M.init()
	local cwd = path.parse(vim.fn.getcwd())
	local cached = require("find_in.cache").read()
	M.cwd = cwd
	M.cached = cached and path.parse(cached.abs) or nil
	M.paths = {}
	for _, item in ipairs(require("find_in.cache").read_paths()) do
		local dir = path.parse(item.abs)
		if dir then M.paths[#M.paths + 1] = dir end
	end
	local initial = require("find_in.config").get().initial_dir
	M.active = type(initial) == "string" and initial ~= "cwd" and path.parse(initial)
		or (initial == "cached" and M.cached or cwd)
	if not M.active then
		M.active = cwd
	end
end
function M.set_active(dir)
	M.active = dir
end
function M.cancel()
	M.scan_id = M.scan_id + 1
	if M.process then
		pcall(function()
			M.process:kill(15)
		end)
		M.process = nil
	end
end
return M
