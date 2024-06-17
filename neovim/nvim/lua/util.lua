-- util.lua
-- Utility functions

local util = {}
-- Function to check operating system
-- Would return Windows, Linux, macOS or Unknown

-- Autocommands
-- highlight on yank
local yank_group = vim.api.nvim_create_augroup('YankHighlight', {clear = true})

-- Create a autocommand within the augroup to highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank {higroup = "CurSearch", timeout = 200 }
    end,
    desc = "Briefly highlight yanked text"
})


-- Check to see if a directory exists
local function directory_exists(path)
    -- try to open a directory as if it is a file.
    local file = io.open(path, "r")
    if file then
        -- Attempt to read  from the directory, this will fail.
        local block = file:read(1)
        file:close()
        if block == nil then
            -- successfully opened, but unable to read (is directory
            return true
        else
            -- could open and read, like a file, so not a directory
            return false
        end
    else
        -- Couldn't open or read
        return false
    end
end

function util.GetOS()
    if os.getenv("OS") ~= nil and os.getenv("OS"):match("Windows") then
        return "Windows"
    elseif os.getenv("HOME") ~= nil then
        if os.getenv("XDG_CURRENT_DESKTOP") ~= nil then
            return "Linux"
        else
            return "macOS"
        end
    else
        error("Unknown operating system", 1)
        return "Unknown"
    end
end

-- Zathura PDF Viewer
-- Open Zathura
local function open_zathura(file_path)
    -- Using vim.cmd to execute Zathura command in the background
    vim.cmd("!zathura " .. vim.fn.shellescape(file_path) .. " &")
end

vim.api.nvim_create_user_command("OpenZathura", function(input)
    open_zathura(input.args)
end, { nargs = 1, desc = "Open Zathura" })

-- C compilation
-- Return the program name or nil
local function compile_c_program_with_cmake()
    -- See if CMakeLists.txt file & build/ directory exists
    local match = nil
    local file, err = io.open("CMakeLists.txt", "r")
    if not file then
        print("Error opening file: " .. err)
        return
    else
        -- find the target name
        local pattern = "add_executable%s*%((%S+)"
        for line in file:lines() do
            match = line:match(pattern)
            if match then
                break -- stop reading file.
            end
        end
        file:close()
    end
    -- if so switch to build/directory
    if not directory_exists("build") then
        os.execute("mkdir build")
    end
    -- Change to the build directory and run CMake commands, silencing output
    -- os.execute("cd build && cmake .. > /dev/null 2>&1 && cmake --build . > /dev/null 2>&1")
    -- TODO: Check if this works as commented
    -- This will supress the build messages, but will show errors
    os.execute("cd build && cmake .. > /dev/null && cmake --build . 2>&1 >/dev/null")
    -- print("Compiled program: " .. match)

    return match
end

local function compile_and_run_c_program_with_cmake()
    local prog_name = compile_c_program_with_cmake()
    return prog_name
end

vim.api.nvim_create_user_command("CMakeCompileCProgram", function()
    local prog_name = compile_c_program_with_cmake()
    print("Compiled -> " .. prog_name)
end, { desc = "Compile C Program with CMake" })

vim.api.nvim_create_user_command("CMakeCompileRunCProgram", function()
    -- Get target name from CMakeLists.txt
    local prog_name = compile_and_run_c_program_with_cmake()
    --local cmd = "./build/" .. prog_name .. "; echo 'Press Enter to exit'; read"
    local cmd = "./build/" .. prog_name

    -- open a new buffer in horizontal split with 10 line of height
    vim.cmd("10new")
    -- get the buffer id of the new buffer
    local buf_id = vim.api.nvim_get_current_buf()

    -- Goto insert mode automatically
    vim.api.nvim_buf_attach(buf_id, false, {
        on_lines = function()
            -- Check to see if we are in normal mode, if so switch to insert mode
            if vim.api.nvim_get_mode().mode ~= "i" then
                vim.cmd("startinsert")
            end
            return false -- detach the callback after switching to insert mode
        end,
    })

    -- Start a terminal in the current buffer
    vim.fn.termopen(cmd, {
        on_exit = function(_, exit_code, _)
            print("Program exited with code " .. exit_code)
        end,
    })

    -- Start a terminal in the current buffer
    --vim.fn.termopen(cmd)
end, { desc = "Compile & run C Program with CMake" })

-- Keybindings
vim.keymap.set("n", "<leader>cr", "<cmd>CMakeCompileRunCProgram<cr>", { desc = "Compile + run a C program" })
vim.keymap.set("n", "<leader>cc", "<cmd>CMakeCompileCProgram<cr>", { desc = "Compile + run a C program" })

return util
