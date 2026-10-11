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
	if count == 0 then
		lines[1] = ctx.query == "" and "No files found" or "No matches"
	else
		local available = math.max(1, vim.api.nvim_win_get_height(ctx.win))
		local first = math.max(1, math.min(ctx.selected - math.floor(available / 2), count - available + 1))
		for index = first, math.min(count, first + available - 1) do
			lines[#lines + 1] = (index == ctx.selected and "> " or "  ") .. ctx.filtered[index]
		end
	end
	vim.bo[ctx.buf].modifiable = true
	vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
	vim.bo[ctx.buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
	if count > 0 then
		local first_item = math.max(1, math.min(ctx.selected - math.floor(math.max(1, vim.api.nvim_win_get_height(ctx.win)) / 2), count - math.max(1, vim.api.nvim_win_get_height(ctx.win)) + 1))
		local file = ctx.filtered[ctx.selected] or ""
		local match = require("find_in.filter").match(file, ctx.query)
		if match then
			for _, col in ipairs(match.positions) do
				vim.api.nvim_buf_add_highlight(ctx.buf, ns, "IncSearch", ctx.selected - first_item, col + 1, col + 2)
			end
		end
	end
	if count > 0 then
		local height = vim.api.nvim_buf_line_count(ctx.buf)
		local row = math.max(0, math.min(height - 1, math.floor(height / 2)))
		vim.api.nvim_win_set_cursor(ctx.win, { row + 1, 0 })
	end
end

return M
