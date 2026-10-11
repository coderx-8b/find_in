local M = {}
function M.open(dir)
  local buf, win = require("find_in.ui.window").open()
  local ctx = { buf = buf, win = win, dir = dir, state = require("find_in.state"), files = {}, filtered = {}, query = "", selected = 1 }
  require("find_in.ui.render").draw(ctx)
  local refresh = require("find_in.ui.keymaps").attach(ctx)
  refresh()
  -- Focus the filter field immediately so the picker accepts a query on open.
  vim.bo[buf].modifiable = true
  local prompt = require("find_in.config").get().ui.prompt
  -- Cursor columns are zero-based and must point at an existing character.
  -- Starting insert at the last prompt character places input after it.
  local prompt_col = math.max(0, #prompt - 1)
  vim.api.nvim_win_set_cursor(win, { 1, prompt_col })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_get_current_win() == win then
      -- A scan may have redrawn the picker before this scheduled callback.
      -- Re-enable edits after that redraw and immediately before entering insert.
      vim.bo[buf].modifiable = true
      vim.api.nvim_win_set_cursor(win, { 1, prompt_col })
      vim.cmd.startinsert({ bang = true })
    end
  end)
  return ctx
end
return M
