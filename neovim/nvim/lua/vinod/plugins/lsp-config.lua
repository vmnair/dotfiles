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
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      -- Lua Lsp setup
      lspconfig.lua_ls.setup({
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
      -- clangd lsp setup
      -- We will check if CMakeLists.text is present or build/compile_commands
      -- to determine the root directory
      local function clangd_custom_root_dir(fname)
        return util.root_pattern("CMakeLists.txt")(fname)
            or util.root_pattern("build/compile_commands.json")(fname)
      end
      lspconfig.clangd.setup({
        capabilities = capabilities,
        cmd = { "clangd", "--compile-commands-dir=build" },
        filetypes = { "c", "cpp" },
        root_dir = clangd_custom_root_dir,
      })

      -- gopls lsp setup
      lspconfig.gopls.setup({
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
        root_dir = util.root_pattern("go.work", "go.mod", ".git"),
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

      -- bash scripts LSP
      lspconfig.cmake.setup({
        capabilities = capabilities,
        filetypes = { "cmake", "CMakeLists.txt" },
      })

      -- bash scripts LSP
      lspconfig.bashls.setup({
        capabilities = capabilities,
        filetypes = { "sh", "bash", "zsh", "zshrc", "proj" },
      })

      -- texlab configuration
      lspconfig.texlab.setup({
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
      -- configure marksman language server
      -- lspconfig.marksman.setup({
      -- 	settings = {},
      -- })
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
