-- c_dev.lua
-- C Programming Development Environment Configuration
-- Provides build, run, and formatting keybindings for C development

local M = {}

-- Function to build C project using cmake
M.cmake_build = function()
	local build_dir = vim.fn.getcwd() .. "/build"

	-- Check if build directory exists
	if vim.fn.isdirectory(build_dir) == 0 then
		-- Create build directory and run cmake
		vim.notify("Creating build directory and running CMake...", vim.log.levels.INFO)
		vim.cmd("!mkdir -p build && cd build && cmake ..")
	end

	-- Build the project
	vim.notify("Building project...", vim.log.levels.INFO)
	vim.cmd("!cmake --build build")
end

-- Function to build and run C project
M.cmake_build_and_run = function()
	M.cmake_build()

	-- Find executable in build directory
	local executable = vim.fn.input("Executable name (in build/): ", "app")
	local exe_path = vim.fn.getcwd() .. "/build/" .. executable

	if vim.fn.filereadable(exe_path) == 1 then
		vim.notify("Running " .. executable .. "...", vim.log.levels.INFO)
		vim.cmd("!cd build && ./" .. executable)
	else
		vim.notify("Executable not found: " .. exe_path, vim.log.levels.ERROR)
	end
end

-- Function to compile single C file with gcc
M.compile_single_file = function()
	local file = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")

	vim.notify("Compiling " .. vim.fn.expand("%:t") .. "...", vim.log.levels.INFO)
	vim.cmd("!gcc -Wall -Wextra -g -o " .. output .. " " .. file)
end

-- Function to compile and run single C file
M.compile_and_run_single = function()
	local file = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")

	vim.notify("Compiling and running " .. vim.fn.expand("%:t") .. "...", vim.log.levels.INFO)
	vim.cmd("!gcc -Wall -Wextra -g -o " .. output .. " " .. file .. " && " .. output)
end

-- Function to format C file with clang-format
M.format_c_file = function()
	local file = vim.fn.expand("%:p")
	vim.notify("Formatting with clang-format...", vim.log.levels.INFO)
	vim.cmd("!clang-format -i " .. file)
	vim.cmd("e!") -- Reload the file
end

-- Function to run current executable with arguments
M.run_with_args = function()
	local executable = vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/build/app", "file")
	local args = vim.fn.input("Arguments: ")

	if vim.fn.filereadable(executable) == 1 then
		vim.notify("Running " .. executable .. "...", vim.log.levels.INFO)
		vim.cmd("!" .. executable .. " " .. args)
	else
		vim.notify("Executable not found: " .. executable, vim.log.levels.ERROR)
	end
end

-- Function to clean build directory
M.clean_build = function()
	vim.notify("Cleaning build directory...", vim.log.levels.INFO)
	vim.cmd("!rm -rf build")
end

-- Set up autocommand for C files
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "c", "cpp" },
	callback = function()
		local map = vim.keymap.set
		local opts = { buffer = true, silent = true }

		-- Build keybindings
		map("n", "<leader>cb", M.cmake_build, vim.tbl_extend("force", opts, { desc = "[C] CMake build" }))
		map("n", "<leader>cr", M.cmake_build_and_run, vim.tbl_extend("force", opts, { desc = "[C] Build and run" }))
		map("n", "<leader>cc", M.compile_single_file, vim.tbl_extend("force", opts, { desc = "[C] Compile file" }))
		map(
			"n",
			"<leader>cx",
			M.compile_and_run_single,
			vim.tbl_extend("force", opts, { desc = "[C] Compile and run" })
		)

		-- Run keybindings
		map("n", "<leader>cR", M.run_with_args, vim.tbl_extend("force", opts, { desc = "[C] Run with args" }))

		-- Formatting
		map("n", "<leader>cf", M.format_c_file, vim.tbl_extend("force", opts, { desc = "[C] Format file" }))

		-- Clean
		map("n", "<leader>cC", M.clean_build, vim.tbl_extend("force", opts, { desc = "[C] Clean build" }))

		-- Add helpful comments about debugging
		-- Debug with <F5> (already configured in DAP)
		-- Set breakpoint with <leader>db (already configured in DAP)
	end,
})

return M
