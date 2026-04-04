-- init.lua
-- Vinod Nair MD
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=30s

require("vinod.config.lazy")
require("vinod.config.options")
require("vinod.config.util")
require("vinod.config.autocmds")
require("vinod.config.aliases")
require("vinod.config.c_dev")
require("vinod.config.lsp")
-- require("vinod.config.mappings") Called from lazy.lua

-- Dev plugins must be on rtp before any code that requires their modules
vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/dev-plugins/todo-manager.nvim")
vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/dev-plugins/readwise.nvim")

require("vinod.config.todo_commands")

vim.defer_fn(function()
	require("fzf-lua").register_ui_select(function(ui_opts, items)
		local prompt = ui_opts and ui_opts.prompt or "Select"
		prompt = prompt:gsub("[:%s>]+$", "")

		-- Calculate width from longest item + padding
		local max_width = #prompt + 4
		for i, item in ipairs(items) do
			local text = ui_opts.format_item and ui_opts.format_item(item) or tostring(item)
			local line_len = #tostring(i) + 2 + #text
			if line_len > max_width then
				max_width = line_len
			end
		end
		max_width = max_width + 6

		-- Height: items + prompt line + info line + border padding
		local height = #items + 4

		return {
			winopts = {
				title = " " .. prompt .. " ",
				height = height,
				width = max_width,
				row = 0.5,
				col = 0.5,
			},
			prompt = "> ",
			fzf_opts = { ["--border"] = "none" },
		}
	end)
end, 0)
