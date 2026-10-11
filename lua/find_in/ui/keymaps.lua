local M = {}
local function each(keys, fn)
	if type(keys) == "string" then
		keys = { keys }
	end
	for _, key in ipairs(keys or {}) do
		fn(key)
	end
end
function M.attach(ctx)
	local maps = require("find_in.config").get().mappings
	local function map(keys, fn)
		each(keys, function(key)
			vim.keymap.set("n", key, fn, { buffer = ctx.buf, silent = true, nowait = true })
		end)
	end
	local function redraw()
		require("find_in.ui.render").draw(ctx)
	end
	local function refresh()
		require("find_in.rg").scan(ctx.dir, function(files)
			ctx.files = files
			ctx.filtered = require("find_in.filter").apply(files, ctx.query)
			ctx.selected = 1
			redraw()
		end)
	end
	local function change(dir)
		if not dir then
			return
		end
		require("find_in.state").set_active(dir)
		ctx.dir = dir
		ctx.files = {}
		ctx.filtered = {}
		ctx.selected = 1
		redraw()
		refresh()
	end
	map(maps.close, function()
		if vim.api.nvim_win_is_valid(ctx.win) then
			vim.api.nvim_win_close(ctx.win, true)
		end
	end)
	map(maps.down, function()
		ctx.selected = math.min(#ctx.filtered, ctx.selected + 1)
		redraw()
	end)
	map(maps.up, function()
		ctx.selected = math.max(1, ctx.selected - 1)
		redraw()
	end)
	local function open(kind)
		local file = ctx.filtered[ctx.selected]
		if not file then
			return
		end
		local target = ctx.dir.abs .. "/" .. file
		vim.api.nvim_win_close(ctx.win, true)
		if kind == "vsplit" then
			vim.cmd("vsplit")
		elseif kind == "split" then
			vim.cmd("split")
		elseif kind == "tab" then
			vim.cmd("tabnew")
		end
		vim.cmd.edit(vim.fn.fnameescape(target))
	end
	map(maps.open, function()
		open("open")
	end)
	map(maps.vsplit, function()
		open("vsplit")
	end)
	map(maps.split, function()
		open("split")
	end)
	map(maps.tab, function()
		open("tab")
	end)
	map(maps.switch_cached, function()
		local st = require("find_in.state")
		if st.cached then
			change(st.cached)
		else
			vim.notify("[find_in.nvim] No cached directory", vim.log.levels.WARN)
		end
	end)
	map(maps.switch_cwd, function()
		change(require("find_in.state").cwd)
	end)
	map(maps.bookmark, function()
		local st = require("find_in.state")
		st.cached = ctx.dir
		require("find_in.cache").write(ctx.dir)
		redraw()
	end)
	map(maps.refresh, refresh)
	map(maps.switch_path, function()
		vim.ui.input({ prompt = "Directory relative to ~: ", completion = "dir", default = "" }, function(value)
			if value and value ~= "" then
				local dir, err = require("find_in.path").parse(value)
				if dir then
					local st = require("find_in.state")
					st.cached = dir
					require("find_in.cache").write(dir)
					change(dir)
				else
					vim.notify("[find_in.nvim] " .. err, vim.log.levels.ERROR)
				end
			end
		end)
	end)
	vim.keymap.set("n", "i", function()
		vim.api.nvim_buf_set_option(ctx.buf, "modifiable", true)
		local prompt = require("find_in.config").get().ui.prompt
		vim.api.nvim_buf_set_lines(ctx.buf, 1, 2, false, { prompt .. ctx.query })
		vim.api.nvim_win_set_cursor(ctx.win, { 2, #prompt + #ctx.query })
		vim.cmd.startinsert()
	end, { buffer = ctx.buf, silent = true })
	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = ctx.buf,
		callback = function()
			local line = vim.api.nvim_buf_get_lines(ctx.buf, 1, 2, false)[1] or ""
			local prompt = require("find_in.config").get().ui.prompt
			ctx.query = line:sub(#prompt + 1)
			ctx.filtered = require("find_in.filter").apply(ctx.files, ctx.query)
			ctx.selected = 1
			-- TextChangedI runs while Neovim is processing an insert. Defer the
			-- full-buffer redraw until that change has finished; editing the
			-- scratch buffer from inside this callback can raise text-lock errors
			-- and leave the filter line unmodifiable.
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(ctx.buf) or not vim.api.nvim_win_is_valid(ctx.win) then
					return
				end
				redraw()
				if vim.api.nvim_get_current_win() == ctx.win and vim.fn.mode():match("^i") then
					vim.bo[ctx.buf].modifiable = true
					vim.api.nvim_win_set_cursor(ctx.win, { 2, #prompt + #ctx.query })
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd("InsertLeave", {
		buffer = ctx.buf,
		callback = function()
			redraw()
		end,
	})
	return refresh
end
return M
