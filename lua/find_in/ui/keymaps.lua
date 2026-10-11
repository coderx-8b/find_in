local M = {}
local function each(keys, fn)
	if type(keys) == "string" then keys = { keys } end
	for _, key in ipairs(keys or {}) do fn(key) end
end

function M.attach(ctx)
	local maps = require("find_in.config").get().mappings
	local function redraw() require("find_in.ui.render").draw(ctx) end
	local function map(keys, fn)
		each(keys, function(key) vim.keymap.set("n", key, fn, { buffer = ctx.buf, silent = true, nowait = true, noremap = true }) end)
	end
	local function add_to_query(value)
		ctx.query = ctx.query .. value
		ctx.filtered = require("find_in.filter").apply(ctx.files, ctx.query)
		ctx.selected = 1
		redraw()
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
	-- Buffer-local nonrecursive mappings take printable keys before any global
	-- normal-mode mapping can consume them. Action mappings below replace these
	-- handlers for their configured keys.
	for byte = 32, 126 do
		local char = string.char(byte)
		map(char, function() add_to_query(char) end)
	end

	map(maps.close, close)
	map(maps.help, function() ctx.show_help = not ctx.show_help; redraw() end)
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
		local st = require("find_in.state"); st.cached = ctx.dir; require("find_in.cache").add_path(ctx.dir)
		st.paths = {}
		for _, item in ipairs(require("find_in.cache").read_paths()) do
			local dir = require("find_in.path").parse(item.abs)
			if dir then st.paths[#st.paths + 1] = dir end
		end
		redraw()
	end)
	map(maps.refresh, refresh)
	map(maps.switch_path, function()
		local path = require("find_in.path")
		local st = require("find_in.state")
		local choices = {}
		for _, item in ipairs(require("find_in.cache").read_paths()) do
			local dir = path.parse(item.abs)
			if dir then choices[#choices + 1] = dir end
		end
		local add = { add_new = true }
		choices[#choices + 1] = add
		local choice_buf, choice_win = require("find_in.ui.window").open({
			title = " Switch directory ", footer = "  Ctrl-N/P move · Enter choose · Esc close  ",
		})
		local selected = 1
		local function close_choices()
			if vim.api.nvim_win_is_valid(choice_win) then vim.api.nvim_win_close(choice_win, true) end
		end
		local function draw_choices()
			if not vim.api.nvim_buf_is_valid(choice_buf) then return end
			local lines = {}
			for i, item in ipairs(choices) do
				local label = item.add_new and "+ Add directory…" or path.format(item.abs)
				lines[i] = (i == selected and "> " or "  ") .. label
			end
			vim.bo[choice_buf].modifiable = true
			vim.api.nvim_buf_set_lines(choice_buf, 0, -1, false, lines)
			vim.bo[choice_buf].modifiable = false
			if vim.api.nvim_win_is_valid(choice_win) then
				vim.api.nvim_win_set_cursor(choice_win, { selected, 0 })
			end
		end
		local function choose()
			local item = choices[selected]
			close_choices()
			local function apply(value)
				if not value or value == "" then return end
				local dir, err = path.parse(value)
				if not dir then vim.notify("[find_in.nvim] " .. err, vim.log.levels.ERROR); return end
				require("find_in.cache").add_path(dir)
				st.paths = { dir }
				for _, recent in ipairs(require("find_in.cache").read_paths()) do
					local parsed = path.parse(recent.abs)
					if parsed and parsed.abs ~= dir.abs then st.paths[#st.paths + 1] = parsed end
				end
				change(dir)
			end
			if not item then return end
			if item.add_new then
				vim.ui.input({ prompt = "Directory relative to ~: ", completion = "dir", default = "" }, apply)
			else
				st.cached = item
				require("find_in.cache").write(item)
				change(item)
			end
		end
		local function bind(keys, fn)
			for _, key in ipairs(keys) do
				vim.keymap.set("n", key, fn, { buffer = choice_buf, silent = true, nowait = true })
			end
		end
		bind({ "<C-n>", "<Down>" }, function() selected = math.min(#choices, selected + 1); draw_choices() end)
		bind({ "<C-p>", "<Up>" }, function() selected = math.max(1, selected - 1); draw_choices() end)
		bind({ "<CR>" }, choose)
		bind({ "q", "<Esc>" }, close_choices)
		draw_choices()
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
		-- vim.ui.input() uses Neovim's command line in the default UI. The
		-- picker window remains current while that prompt is open, so checking
		-- only the current window would steal Backspace (and typed characters)
		-- from the input prompt.
		if vim.fn.mode():sub(1, 1) ~= "n" then return end
		local trans = vim.fn.keytrans(key)
		if reserved[trans] then return end
		local changed = false
		if trans == "<BS>" or trans == "<C-h>" then
			if #ctx.query > 0 then ctx.query = vim.fn.strcharpart(ctx.query, 0, vim.fn.strchars(ctx.query) - 1); changed = true end
			if not changed then return "" end
		elseif trans == "<C-u>" then ctx.query, changed = "", true
		elseif key:byte() and key:byte() >= 128 and vim.fn.strchars(key) == 1 then
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
