-- plugin/todo-manager.lua
-- Auto-loaded when rtp includes this plugin

if vim.g.todo_manager_loaded then
	return
end
vim.g.todo_manager_loaded = true

-- Commands are loaded via require("todo-manager.commands") in init.lua
-- because rtp:prepend in init.lua runs after Neovim's plugin/ scan
