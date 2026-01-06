-- lua_ls.lua
-- Lua language server configuration

return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	-- Nested lists indicate equal priority.
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
	-- Settings send to specific server
	settings = {
		Lua = {
			diagnostics = {
				-- globals = { "vim" }, -- Accept 'vim' as a global keyword.
			},
		},
	},
}
