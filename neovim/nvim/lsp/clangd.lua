-- clangd.lua
-- C/C++ language server configuration

return {
  cmd = { "clangd", "--compile-commands-dir=build" },
  filetypes = { "c", "cpp" },
  root_markers = { "CMakeLists.txt", "build/compile_commands.json" },
}
