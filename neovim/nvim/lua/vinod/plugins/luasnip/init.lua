-- luasnip/init.lua

return {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "v2.*",
    event = "VeryLazy",
    build = "make install_jsregexp",

    config = function()
        require("vinod.plugins.luasnip.snips") -- Custom snippets
        local ls = require("luasnip")
        -- To trigger frindly snippets
        require("luasnip.loaders.from_vscode").lazy_load()

        -- Use an absolute path or ensure the relative path is correct
        local snippet_path = vim.fn.stdpath("config") .. "/lua/vinod/plugins/luasnip/snips.lua"
        -- reload snippets module
        local function reload_snippet(path)
            local file = io.open(path, "r")
            if file then
                file:close() -- Close file
                -- remove snips module from cache
                package.loaded["vinod.plugins.luasnip.snips"] = nil
                -- clear the existing snippets table
                ls.snippets = {}
                -- Reload module.
                local ok, module = pcall(require, "vinod.plugins.luasnip.snips")
                if not ok then
                    require("noice").notify(
                        "Reloading Snippets Failed.",
                        "warn",
                        { title = "Reloading Snippets Failed" }
                    )
                    return nil
                else
                    ls.snippets = require("luasnip").snippets
                    require("noice").notify("Snippet Reloaded!", "info", { title = "Snippets Reload Notification" })
                    return module
                end
            else
                require("noice").notify("Snippet file NOT found!", "info", { title = "Error: Snippet file not found" })
                return nil
            end
        end

        local function reload()
            reload_snippet(snippet_path)
        end
        --reload_snippet(snippet_path)

        --keymaps
        vim.keymap.set({ "n", "i", "v" }, "<leader>rs", reload, {
            noremap = true,
            silent = true,
            desc = "Reload snippets",
        })
        vim.keymap.set({ "i" }, "<C-K>", function()
            ls.expand()
        end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-L>", function()
            ls.jump(1)
        end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-J>", function()
            ls.jump(-1)
        end, { silent = true })

        vim.keymap.set({ "i", "s" }, "<C-E>", function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, { silent = true })
    end,
}
