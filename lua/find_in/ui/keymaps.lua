local M = {}
local function each(keys, fn)
	if type(keys) == "string" then keys = { keys } end
	for _, key in ipairs(keys or {}) do fn(key) end
end

function M.attach(ctx)
	local maps = require("find_in.config").get().mappings
	local function redraw() require("find_in.ui.render").draw(ctx) end
	local function map(keys, fn)
		each(keys, function(key) vim.keymap.set("n", key, fn, { buffer = ctx.buf, silent = true, nowait = true }) end)
	end
	local function refresh()
		require("find_in.rg").scan(ctx.dir, function(files)
			ctx.files = files
			ctx.filtered = require("find_in.filter").apply(files, ctx.query)
			ctx.selected = math.min(math.max(ctx.selected, 1), math.max(1, #ctx.filtered))
			redraw()
		end)
	end
	local function change(dir)
		if not dir then return end
		require("find_in.state").set_active(dir)
		ctx.dir, ctx.files, ctx.filtered, ctx.selected, ctx.query = dir, {}, {}, 1, ""
		redraw(); refresh()
	end
	local function close()
		if ctx.key_ns then vim.on_key(nil, ctx.key_ns); ctx.key_ns = nil end
		if vim.api.nvim_win_is_valid(ctx.win) then vim.api.nvim_win_close(ctx.win, true) end
	end
	local function open(kind)
		local file = ctx.filtered[ctx.selected]
		if not file then return end
		local target = ctx.dir.abs .. "/" .. file
		close()
		if kind == "vsplit" then vim.cmd("vsplit") elseif kind == "split" then vim.cmd("split") elseif kind == "tab" then vim.cmd("tabnew") end
		vim.cmd.edit(vim.fn.fnameescape(target))
	end
	map(maps.close, close)
	map(maps.down, function() ctx.selected = math.min(#ctx.filtered, ctx.selected + 1); redraw() end)
	map(maps.up, function() ctx.selected = math.max(1, ctx.selected - 1); redraw() end)
	map(maps.open, function() open("open") end)
	map(maps.vsplit, function() open("vsplit") end)
	map(maps.split, function() open("split") end)
	map(maps.tab, function() open("tab") end)
	map(maps.switch_cached, function()
		local st = require("find_in.state")
		if st.cached then change(st.cached) else vim.notify("[find_in.nvim] No cached directory", vim.log.levels.WARN) end
	end)
	map(maps.switch_cwd, function() change(require("find_in.state").cwd) end)
	map(maps.bookmark, function()
		local st = require("find_in.state"); st.cached = ctx.dir; require("find_in.cache").write(ctx.dir); redraw()
	end)
	map(maps.refresh, refresh)
	map(maps.switch_path, function()
		vim.ui.input({ prompt = "Directory relative to ~: ", completion = "dir", default = "" }, function(value)
			if value and value ~= "" then
				local dir, err = require("find_in.path").parse(value)
				if dir then local st = require("find_in.state"); st.cached = dir; require("find_in.cache").write(dir); change(dir)
				else vim.notify("[find_in.nvim] " .. err, vim.log.levels.ERROR) end
			end
		end)
	end)

	-- Capture printable keys in normal mode so the picker remains a single
	-- window and filtering never edits/rebuilds the prompt as buffer text.
	ctx.key_ns = vim.api.nvim_create_namespace("find_in_input")
	local reserved = {}
	for _, value in pairs(maps) do
		each(value, function(key)
			local encoded = vim.api.nvim_replace_termcodes(key, true, true, true)
			reserved[vim.fn.keytrans(encoded)] = true
		end)
	end
	vim.on_key(function(key)
		if not vim.api.nvim_win_is_valid(ctx.win) or vim.api.nvim_get_current_win() ~= ctx.win then return end
		local trans = vim.fn.keytrans(key)
		if reserved[trans] then return end
		local changed = false
		if trans == "<BS>" or trans == "<C-h>" then
			if #ctx.query > 0 then ctx.query = vim.fn.strcharpart(ctx.query, 0, vim.fn.strchars(ctx.query) - 1); changed = true end
			if not changed then return "" end
		elseif trans == "<C-u>" then ctx.query, changed = "", true
		elseif key:byte() and key:byte() >= 32 and key:byte() ~= 127 and vim.fn.strchars(key) == 1 then
			ctx.query, changed = ctx.query .. key, true
		end
		if changed then
			ctx.filtered = require("find_in.filter").apply(ctx.files, ctx.query)
			ctx.selected = 1
			vim.schedule(redraw)
			return ""
		end
	end, ctx.key_ns)
	return refresh
end

return M
