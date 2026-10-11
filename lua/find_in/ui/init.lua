local M = {}
function M.open(dir)
  local buf, win = require("find_in.ui.window").open()
  local ctx = { buf = buf, win = win, dir = dir, state = require("find_in.state"), files = {}, filtered = {}, query = "", selected = 1 }
  require("find_in.ui.render").draw(ctx)
  local refresh = require("find_in.ui.keymaps").attach(ctx)
  refresh()
  -- Start in the filter field so the picker accepts a query immediately.
  vim.bo[buf].modifiable = true
  local prompt = require("find_in.config").get().ui.prompt
  vim.api.nvim_win_set_cursor(win, { 2, #prompt })
  vim.cmd.startinsert()
  return ctx
end
return M
