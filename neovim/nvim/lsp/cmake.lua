-- cmake.lua
-- CMake language server configuration

return {
  cmd = { "cmake-language-server" },
  filetypes = { "cmake" },
  root_markers = { "CMakeLists.txt", "build", ".git" },
}
