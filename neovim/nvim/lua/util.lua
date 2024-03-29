-- util.lua
-- Utility functions


-- Zathura PDF Viewer
-- Open Zathura
local function open_zathura(file_path)
    -- Using vim.cmd to execute Zathura command in the background
    vim.cmd("!zathura " .. vim.fn.shellescape(file_path) .. " &")
end


vim.api.nvim_create_user_command("OpenZathura", function(input)
    open_zathura(input.args)
end, {nargs = 1, desc = "Open Zathura"})
