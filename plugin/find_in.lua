if vim.g.loaded_find_in then return end
vim.g.loaded_find_in = true
local find_in = require("find_in")
vim.api.nvim_create_user_command("FindIn", function(args) if args.args ~= "" then find_in.open({ path = args.args }) else find_in.open() end end, { nargs = "?", complete = function(arglead) return require("find_in.complete").complete(arglead) end })
vim.api.nvim_create_user_command("FindInCached", function() find_in.open_cached() end, {})
vim.api.nvim_create_user_command("FindInSetDir", function(args) if args.args ~= "" then find_in.set_dir(args.args) else find_in.set_dir() end end, { nargs = "?", complete = function(arglead) return require("find_in.complete").complete(arglead) end })
vim.api.nvim_create_user_command("FindInCwd", function() find_in.open_cwd() end, {})
vim.api.nvim_create_user_command("FindInResetCache", function() find_in.reset_cache() end, {})
