local M = {}
local ns = vim.api.nvim_create_namespace("find_in")
function M.draw(ctx)
  if not vim.api.nvim_buf_is_valid(ctx.buf) then return end
  local width = vim.api.nvim_win_get_width(ctx.win)
  local cached = ctx.state.cached and require("find_in.path").format(ctx.state.cached.abs) or "none"
  local lines = { "[Find In] " .. require("find_in.path").format(ctx.dir.abs) .. "    [Cached: " .. cached .. "]",
    require("find_in.config").get().ui.prompt .. ctx.query, string.rep("─", math.max(1, width - 2)) }
  local first = #lines + 1
  if #ctx.filtered == 0 then lines[#lines + 1] = "  No files found in " .. require("find_in.path").format(ctx.dir.abs)
  else
    for _, file in ipairs(ctx.filtered) do lines[#lines + 1] = "  " .. file end
  end
  local last = #lines
  lines[#lines + 1] = string.rep("─", math.max(1, width - 2))
  lines[#lines + 1] = "<CR> open │ <C-v> vsplit │ <C-c> cached │ <C-p> path │ <C-.> cwd │ q close"
  lines[#lines + 1] = string.format("%d files (filtered from %d)", #ctx.filtered, #ctx.files)
  vim.bo[ctx.buf].modifiable = true; vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines); vim.bo[ctx.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)
  for row = first - 1, last - 1 do
    local text = lines[row + 1]; local slash = text:match("^%s*().*/")
    if slash then vim.api.nvim_buf_add_highlight(ctx.buf, ns, "Comment", row, 0, #text - #text:match("[^/]+$") - 1) end
  end
  vim.api.nvim_win_set_cursor(ctx.win, { math.max(first, math.min(last, first + ctx.selected - 1)), 0 })
end
return M
