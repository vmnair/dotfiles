-- util.lua
-- Utility functions

local util  = {}

-- Function to check operating system
-- Would return Windows, Linux, macOS or Unknown 
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
end, {nargs = 1, desc = "Open Zathura"})


return util
