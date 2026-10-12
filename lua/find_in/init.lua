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
	local function set_default_highlight()
		vim.api.nvim_set_hl(0, "FindInMatch", { default = true, link = "IncSearch" })
	end
	set_default_highlight()
	local group = vim.api.nvim_create_augroup("FindInHighlights", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = set_default_highlight,
	})
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
function M.open_buffers()
	local buffers = vim.api.nvim_list_bufs()
	local entries, seen = {}, {}
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buf) and (vim.bo[buf].buflisted or vim.bo[buf].buftype == "help") then
			local name = vim.api.nvim_buf_get_name(buf)
			local label = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
			if seen[label] then label = label .. "  (" .. buf .. ")" end
			seen[label] = true
			entries[#entries + 1] = { label = label, bufnr = buf }
		end
	end
	table.sort(entries, function(a, b) return a.label:lower() < b.label:lower() end)
	return require("find_in.ui").open_buffers(entries)
end
function M.open_help_tags()
	-- Empty-prefix help completion is intentionally a short list in Neovim.
	-- Read every runtime doc tag file so Vim's built-in help topics are included
	-- alongside Neovim's help and any other runtime documentation.
	local tags, seen = {}, {}
	local tag_files = vim.fn.globpath(vim.o.runtimepath, "doc/tags", false, true)
	for _, path in ipairs(tag_files) do
		for line in io.lines(path) do
			local tag = line:match("^([^\t]+)\t")
			if tag and not seen[tag] then
				seen[tag] = true
				tags[#tags + 1] = tag
			end
		end
	end
	-- Keep completion results too, for help topics that are supplied by
	-- Neovim but do not have a conventional doc/tags entry.
	for _, tag in ipairs(vim.fn.getcompletion("", "help")) do
		if not seen[tag] then
			seen[tag] = true
			tags[#tags + 1] = tag
		end
	end
	local man_pages, api_topics = {}, {}
	-- Help tags use names such as `nvim_get_current_buf`, while Neovim's Lua
	-- API exposes them as `vim.api.nvim_get_current_buf()`. Add the Lua-facing
	-- names as searchable aliases and keep their help targets for opening.
	for name, value in pairs(vim.api) do
		if type(value) == "function" and name:match("^nvim_") then
			local label = "vim.api." .. name .. "()"
			if not seen[label] then
				seen[label] = true
				api_topics[label] = name
				tags[#tags + 1] = label
			end
		end
	end
	-- `:Man` pages are not part of Neovim's help completion. Use the system
	-- whatis index to add the installed manual entries when available.
	local pipe = io.popen("man -k . 2>/dev/null")
	if pipe then
		for line in pipe:lines() do
			local names, section = line:match("^(.-)%s+%(([^()]*)%)%s+%-")
			if names and section then
				for name in names:gmatch("[^,]+") do
					name = vim.trim(name)
					local label = name .. "(" .. section .. ")"
					if not seen[label] then
						seen[label] = true
						man_pages[label] = { name = name, section = section }
						tags[#tags + 1] = label
					end
				end
			end
		end
		pipe:close()
	end
	table.sort(tags, function(a, b) return a:lower() < b:lower() end)
	return require("find_in.ui").open_help_tags(tags, man_pages, api_topics)
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
		require("find_in.cache").add_path(dir)
		s.paths = { dir }
		for _, item in ipairs(require("find_in.cache").read_paths()) do
			local recent = require("find_in.path").parse(item.abs)
			if recent and recent.abs ~= dir.abs then s.paths[#s.paths + 1] = recent end
		end
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
	s.cached, s.paths = nil, {}
end
function M.get_active_dir()
	return state().active
end
function M.get_cached_dir()
	return state().cached
end
return M
