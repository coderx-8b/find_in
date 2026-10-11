local M = {}
local ns = vim.api.nvim_create_namespace("find_in")

function M.draw(ctx)
	if not vim.api.nvim_buf_is_valid(ctx.buf) or not vim.api.nvim_win_is_valid(ctx.win) then return end
	local title = " > " .. ctx.query .. " ▏ " .. require("find_in.path").format(ctx.dir.abs) .. " "
	local total, count = #ctx.files, #ctx.filtered
	local footer = string.format(" %d | %d / %d ", count == 0 and 0 or ctx.selected, count, total)
	local cfg = vim.api.nvim_win_get_config(ctx.win)
	cfg.title, cfg.title_pos, cfg.footer, cfg.footer_pos = title, "left", footer, "right"
	vim.api.nvim_win_set_config(ctx.win, cfg)

	local lines = {}
	local first_item = 1
	if ctx.show_help then
		local maps = require("find_in.config").get().mappings
		local function keys(value)
			if type(value) == "table" then return table.concat(value, ", ") end
			return value or ""
		end
		lines = {
			"Keymaps (press " .. keys(maps.help) .. " to return)",
			keys(maps.open) .. "  Open selected file",
			keys(maps.split) .. "  Open in horizontal split",
			keys(maps.vsplit) .. "  Open in vertical split",
			keys(maps.tab) .. "  Open in new tab",
			keys(maps.close) .. "  Close picker",
			keys(maps.down) .. "  Move selection down",
			keys(maps.up) .. "  Move selection up",
			keys(maps.switch_cached) .. "  Switch to cached directory",
			keys(maps.switch_path) .. "  Choose recent / add directory",
			keys(maps.switch_cwd) .. "  Switch to working directory",
			keys(maps.bookmark) .. "  Bookmark current directory",
			keys(maps.refresh) .. "  Rescan files",
			"<C-u>  Clear query; <BS>  Delete last query character",
		}
	elseif count == 0 then
		lines[1] = ctx.query == "" and "No files found" or "No matches"
	else
		local available = math.max(1, vim.api.nvim_win_get_height(ctx.win))
		first_item = math.max(1, math.min(ctx.selected - math.floor(available / 2), count - available + 1))
		for index = first_item, math.min(count, first_item + available - 1) do
			lines[#lines + 1] = (index == ctx.selected and "> " or "  ") .. ctx.filtered[index]
		end
	end
	vim.bo[ctx.buf].modifiable = true
	vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
	vim.bo[ctx.buf].modifiable = false
	if vim.api.nvim_win_is_valid(ctx.win) then
		local cursor_row = count > 0 and not ctx.show_help and ctx.selected - first_item + 1 or 1
		vim.api.nvim_win_set_cursor(ctx.win, { cursor_row, 0 })
	end
	vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
	if count > 0 then
		local file = ctx.filtered[ctx.selected] or ""
		local match = require("find_in.filter").match(file, ctx.query)
		if match then
			for _, col in ipairs(match.positions) do
				vim.api.nvim_buf_add_highlight(ctx.buf, ns, "IncSearch", ctx.selected - first_item, col + 1, col + 2)
			end
		end
	end
end

return M
