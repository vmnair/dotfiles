-- lsp-config.lua
-- Mason & mason-lspconfig is also setup here
-- Need to setup in the order of: mason.nvim, mason-lspconfig.nvim followed by
-- nvim-lspconfig

return {

  {
    "williamboman/mason-lspconfig.nvim",
    dependency = { "mason" },
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = false,
        automatic_enable = false,
        handlers = {},
        ensure_installed = {
          "gopls",
          "lua_ls",
          "clangd",
          "bashls",
          "cmake",
          "texlab",
          "marksman",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local map = vim.keymap.set
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Lua language server configuration
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              -- get the language server to recognize the `vim` global
              globals = { "vim" },
            },
          },
        },
      })
      vim.lsp.enable('lua_ls')
      -- clangd language server configuration
      -- We will check if CMakeLists.txt is present or build/compile_commands
      -- to determine the root directory
      local function clangd_custom_root_dir(fname)
        return vim.fs.root(fname, "CMakeLists.txt")
            or vim.fs.root(fname, "build/compile_commands.json")
      end
      vim.lsp.config('clangd', {
        capabilities = capabilities,
        cmd = { "clangd", "--compile-commands-dir=build" },
        filetypes = { "c", "cpp" },
        root_dir = clangd_custom_root_dir,
      })
      vim.lsp.enable('clangd')

      -- gopls language server configuration with auto-formatting
      vim.lsp.config('gopls', {
        capabilities = capabilities,
        on_attach = function(_, bufnr)
          -- Enable formatting on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = true })
            end,
          })
        end,
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = function(fname)
          return vim.fs.root(fname, { "go.work", "go.mod", ".git" })
        end,
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          },
        },
      })
      vim.lsp.enable('gopls')

      -- cmake language server configuration
      vim.lsp.config('cmake', {
        capabilities = capabilities,
        filetypes = { "cmake", "CMakeLists.txt" },
      })
      vim.lsp.enable('cmake')

      -- bash language server configuration
      vim.lsp.config('bashls', {
        capabilities = capabilities,
        filetypes = { "sh", "bash", "zsh", "zshrc", "proj" },
      })
      vim.lsp.enable('bashls')

      -- texlab language server configuration (LaTeX)
      vim.lsp.config('texlab', {
        capabilities = capabilities,
        settings = {
          texlab = {
            build = {
              executable = "latexmk",
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
              onSave = true,
            },
            forwardSearch = {
              executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
              args = { "-g", "%l", "%p", "%f" },
            },
          },
        },
      })
      vim.lsp.enable('texlab')

      -- marksman language server (markdown) - commented out
      -- vim.lsp.config('marksman', {
      --   capabilities = capabilities,
      --   settings = {},
      -- })
      -- vim.lsp.enable('marksman')
      -- Diagnostic floating window should have rounded borders
      vim.diagnostic.config({
        float = {
          -- What are the other options for border?
          border = "double",
        },
      })
      -- Global mappings
      --map("n", "<leader>o", vim.diagnostic.open_float, { desc = "Open diagnostics in a floating window" })
      map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Show diagnostics in a location list" })
      map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
      map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })

      -- Create an autocommand when the lsp server attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
          -- Buffer local mappings.
          map("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Go to declaration" })
          map("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Show hover information" })
          map("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
          map("n", "gi", vim.lsp.buf.implementation, { buffer = ev.buf, desc = "Go to implementation" })
          map("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Go to references" })
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Actions" })
          vim.keymap.set("n", "gf", function()
            vim.lsp.buf.format({ async = true })
          end, { buffer = ev.buf, desc = "Format code" })
        end,
      })
    end,
  },
  -- This is for the diagnostic signs
  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.HINT] = "⚑",
        [vim.diagnostic.severity.INFO] = "»",
      },
    },
  }),
}
