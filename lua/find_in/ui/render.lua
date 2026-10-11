local M = {}
local ns = vim.api.nvim_create_namespace("find_in")
function M.draw(ctx)
	if not vim.api.nvim_buf_is_valid(ctx.buf) then
		return
	end
	local filtering = vim.api.nvim_get_current_buf() == ctx.buf and vim.fn.mode():match("^i") ~= nil
	local width = vim.api.nvim_win_get_width(ctx.win)
	local cached = ctx.state.cached and require("find_in.path").format(ctx.state.cached.abs) or "none"
	local lines = {
		require("find_in.config").get().ui.prompt .. ctx.query,
		"[Find In] " .. require("find_in.path").format(ctx.dir.abs) .. "    [Cached: " .. cached .. "]",
		string.rep("─", math.max(1, width - 2)),
	}
	local first = #lines + 1
	if #ctx.filtered == 0 then
		lines[#lines + 1] = "  No files found in " .. require("find_in.path").format(ctx.dir.abs)
	else
		for _, file in ipairs(ctx.filtered) do
			lines[#lines + 1] = "  " .. file
		end
	end
	local last = #lines
	lines[#lines + 1] = string.rep("─", math.max(1, width - 2))
	lines[#lines + 1] = "<CR> open │ <C-v> vsplit │ <C-c> cached │ <C-p> path │ <C-.> cwd │ q close"
	lines[#lines + 1] = string.format("%d files (filtered from %d)", #ctx.filtered, #ctx.files)
	-- Keep the buffer writable for the whole time the filter is in insert mode.
	-- Async scans and TextChangedI both redraw this buffer; turning modifiable
	-- off at the end of a redraw makes the next typed character fail with E21.
	vim.bo[ctx.buf].modifiable = true
	vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
	vim.bo[ctx.buf].modifiable = filtering
	vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
	for row = first - 1, last - 1 do
		local text = lines[row + 1]
		local slash = text:match("^%s*().*/")
		if slash then
			vim.api.nvim_buf_add_highlight(ctx.buf, ns, "Comment", row, 0, #text - #text:match("[^/]+$") - 1)
		end
	end
	if filtering then
		local prompt = require("find_in.config").get().ui.prompt
		vim.api.nvim_win_set_cursor(ctx.win, { 1, math.max(0, #prompt + #ctx.query - 1) })
	else
		vim.api.nvim_win_set_cursor(ctx.win, { math.max(first, math.min(last, first + ctx.selected - 1)), 0 })
	end
end
return M
