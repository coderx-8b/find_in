local M = {}
local config = require("find_in.config")
local function state()
	local s = require("find_in.state")
	if not s.active then
		s.init()
	end
	return s
end
function M.setup(opts)
	config.setup(opts)
	require("find_in.state").init()
	return M
end
function M.open(opts)
	if type(opts) == "string" then
		opts = { path = opts }
	end
	opts = opts or {}
	local s = state()
	local dir = opts.path and require("find_in.path").parse(opts.path) or s.active
	if not dir then
		vim.notify("[find_in.nvim] Invalid directory", vim.log.levels.ERROR)
		return
	end
	s.active = dir
	return require("find_in.ui").open(dir)
end
function M.open_cached(opts)
	local s = state()
	if not s.cached then
		return M.set_dir(opts)
	end
	s.active = s.cached
	return M.open(opts)
end
function M.set_dir(value)
	if type(value) == "table" then
		value = value.path
	end
	local function apply(path)
		if not path or path == "" then
			return
		end
		local dir, err = require("find_in.path").parse(path)
		if not dir then
			vim.notify("[find_in.nvim] " .. err, vim.log.levels.ERROR)
			return
		end
		local s = state()
		s.active, s.cached = dir, dir
		require("find_in.cache").write(dir)
		return M.open()
	end
	if value then
		return apply(value)
	end
	vim.ui.input({ prompt = "Directory relative to ~: ", completion = "dir" }, apply)
end
function M.open_cwd()
	local s = state()
	s.active = require("find_in.path").parse(vim.fn.getcwd())
	return M.open()
end
function M.reset_cache()
	require("find_in.cache").clear()
	local s = state()
	s.cached = nil
end
function M.get_active_dir()
	return state().active
end
function M.get_cached_dir()
	return state().cached
end
return M
