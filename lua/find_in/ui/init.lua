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
  vim.api.nvim_win_set_cursor(win, { 2, #prompt })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_get_current_win() == win then
      vim.cmd.startinsert()
    end
  end)
  return ctx
end
return M
