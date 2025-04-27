# Neovim Setup

## Contents

1. Directory Structure
   The folder structure should be that `$XDG_CONFIG_HOME` should have an `nvim` folder which will contain a `init.lua` file, which is in the neovim `runtimepath`.

- `$XDG_CONFIG_HOME`
- `nvim`
- `init.lua`

2. `init.lua`, The Initialization File

3. `lazy.nvim` Setup

4. Plugins

- [x] markdown-preview
- [x] live-preview
- [x] render-markdown

5. Miscellenous

- [x] [Use Neovim as the man pager reader (manpager)](https://www.visualmode.dev/a-better-man-page-viewer)
  ```bash
  export MANPAGER="nvim +Man!"
  ```
