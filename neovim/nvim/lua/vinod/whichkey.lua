-- whichkey.lua config file.

local stats_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

local setup = {
  plugins = {
    marks = true, -- shows list of marks on ` and '
    registers = true, -- shows registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true,
      suggestions = 20,
    },
  },

  -- Presets plugin, adds help for default keybindings in Neovim
  -- No actual keybindings are created
  presets = {
    operators = false,
    motions = true,
    text_objects = true,
    windows = true,
    nav = true,
    z = true,
    g = true,
  },
}
  local opts = {}
  local mappings = {}

  which_key.setup(setup)
