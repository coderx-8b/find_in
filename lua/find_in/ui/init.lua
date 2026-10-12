local M = {}
function M.open(dir)
  local buf, win = require("find_in.ui.window").open()
  local ctx = { buf = buf, win = win, dir = dir, state = require("find_in.state"), files = {}, filtered = {}, query = "", selected = 1 }
  require("find_in.ui.render").draw(ctx)
  local refresh = require("find_in.ui.keymaps").attach(ctx)
  refresh()
  return ctx
end
function M.open_buffers(entries)
  local buf, win = require("find_in.ui.window").open({ title = " > buffers ▏ ", footer = "  0 | 0 / 0 " })
  local labels, by_label = {}, {}
  for _, entry in ipairs(entries) do labels[#labels + 1] = entry.label; by_label[entry.label] = entry.bufnr end
  local ctx = { buf = buf, win = win, dir = { abs = "Buffers" }, files = labels, filtered = vim.deepcopy(labels), query = "", selected = 1, buffer_by_label = by_label, is_buffer_picker = true }
  require("find_in.ui.render").draw(ctx)
  require("find_in.ui.keymaps").attach(ctx)
  return ctx
end
return M
