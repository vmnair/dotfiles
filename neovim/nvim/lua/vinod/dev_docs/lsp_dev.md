# LSP Configuration Development Notes

## Migration Summary (December 2024)

Migrated from deprecated `require("lspconfig").server.setup()` to Neovim 0.11's native `vim.lsp.config()`.

### What Was Deprecated

- The **old API**: `require("lspconfig").lua_ls.setup({...})`
- Will be removed in nvim-lspconfig v3.0.0

### What's Still Used

- **nvim-lspconfig plugin**: Still required as a data source for server configs
- **mason-lspconfig**: Uses `automatic_enable` to call `vim.lsp.enable()` automatically

### Key Insight

nvim-lspconfig is NOT removed - it provides default configurations in its `lsp/` directory. The deprecation was only about the old setup API, not the plugin itself.

## Architecture

```
mason.nvim              → Installs language servers
        ↓
mason-lspconfig.nvim    → automatic_enable = true (calls vim.lsp.enable)
        ↓
nvim-lspconfig          → Provides default configs (data source)
        ↓
nvim/lsp/*.lua          → Your overrides (merged with defaults)
        ↓
lua/vinod/config/lsp.lua → Global capabilities, keymaps, diagnostics
```

## File Structure

```
nvim/
  lsp/                              # Server config overrides
    bashls.lua
    clangd.lua
    gopls.lua
    lua_ls.lua
  lua/vinod/
    config/
      lsp.lua                       # Capabilities, keymaps, diagnostics
    plugins/
      lsp-config.lua                # Mason + mason-lspconfig setup
```

## How It Works

### 1. Server Config Files (`lsp/*.lua`)

Each file returns a configuration table. **Must include** `cmd`, `filetypes`, and `root_markers`:

```lua
-- lsp/lua_ls.lua
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git" },
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
}
```

Required fields:
- `cmd` - Command to start server (array)
- `filetypes` - File types to attach to (array)
- `root_markers` - Files that identify project root (array)
- `settings` - Server-specific settings (optional)

### 2. Main Config (`lua/vinod/config/lsp.lua`)

- Sets global capabilities from blink.cmp via `vim.lsp.config("*", {...})`
- Configures diagnostics display
- Sets up LspAttach keymaps

**Note**: Does NOT call `vim.lsp.enable()` - mason-lspconfig handles this.

### 3. Plugin Config (`lua/vinod/plugins/lsp-config.lua`)

```lua
{
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",  -- Required for config data
  },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "gopls", "lua_ls", ... },
      automatic_enable = true,  -- Calls vim.lsp.enable() for installed servers
    })
  end,
}
```

## Adding a New Language Server

1. Install via Mason: `:MasonInstall <server_name>`

2. Create config file `lsp/<server_name>.lua`:
   ```lua
   return {
     cmd = { "server-command" },
     filetypes = { "filetype" },
     root_markers = { ".git" },
     settings = { ... },
   }
   ```

3. Add to `ensure_installed` in `lua/vinod/plugins/lsp-config.lua`

4. Restart Neovim - mason-lspconfig will auto-enable it

## Key Differences from Old Approach

| Old (lspconfig) | New (native vim.lsp) |
|-----------------|----------------------|
| `lspconfig.server.setup({...})` | `vim.lsp.config("server", {...})` |
| `root_dir = lspconfig.util.root_pattern(...)` | `root_markers = { "file1", "file2" }` |
| `capabilities` passed to each server | `vim.lsp.config("*", { capabilities = ... })` globally |
| `on_attach` per server | Use `LspAttach` autocommand |
| `:LspInfo` command | `:checkhealth lsp` or `:lua =vim.lsp.get_clients()` |

## Active Servers

| Language | Server | Config File |
|----------|--------|-------------|
| Lua | lua_ls | `lsp/lua_ls.lua` |
| Go | gopls | `lsp/gopls.lua` |
| C/C++ | clangd | `lsp/clangd.lua` |
| Bash | bashls | `lsp/bashls.lua` |
| Python | pyright | `lsp/pyright.lua` |
| Markdown | marksman | `lsp/marksman.lua` |
| CMake | cmake | `lsp/cmake.lua` |
| LaTeX | texlab | `lsp/texlab.lua` |

## Formatting

Go formatting is handled by **none-ls** (not gopls):
- gofumpt (stricter formatting)
- goimports_reviser (import organization)
- golines (line wrapping)

Other formatters also via none-ls: stylua (Lua), clang_format (C).

## Useful Commands

| Command | Description |
|---------|-------------|
| `:checkhealth lsp` | Full LSP health check |
| `:lua =vim.lsp.get_clients()` | List active LSP clients |
| `:LspLog` | View LSP logs |
| `:LspRestart` | Restart LSP clients |

**Note**: `:LspInfo` was provided by nvim-lspconfig's old API and is no longer available.

## Keymaps (set in LspAttach)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `K` | Hover information |
| `gf` | Format buffer |
| `<leader>ca` | Code actions |
| `[d` / `]d` | Prev/next diagnostic |
| `<leader>ql` | Diagnostics to location list |

## Troubleshooting

### LSP not attaching

1. Check server is installed: `:Mason`
2. Check health: `:checkhealth lsp`
3. Verify config file exists in `lsp/<server>.lua`
4. Ensure `cmd`, `filetypes`, `root_markers` are all specified

### Load order issues

- `vim.lsp.config("*", ...)` must run before servers start
- mason-lspconfig's `automatic_enable` handles server startup timing
- blink.cmp capabilities are set in `lua/vinod/config/lsp.lua` (loaded early)
