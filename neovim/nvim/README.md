# Neovim Setup

## Contents

1. Directory Structure
   The folder structure should be that `$XDG_CONFIG_HOME` should have an
   `nvim` folder which will contain a `init.lua` file, which is in the
   neovim `runtimepath`.

- `$XDG_CONFIG_HOME`
- `nvim`
- `init.lua`

2. `init.lua`, The Initialization File

3. `lazy.nvim` Setup

4. Plugins

- [x] [markdown-preview](https://github.com/iamcco/markdown-preview.nvim)
- [x] [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim)
- [x] [live-preview](https://github.com/brianhuster/live-preview.nvim)
- [x] [showkeys](https://github.com/nvzone/showkeys)
- [x] [mason-nvim](https://github.com/mason-org/mason.nvim)
- [x] [mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim)
- [x] [zk-nvim](https://github.com/zk-org/zk-nvim)
  - Install _zk cli_ with brew,
  ```bash
  brew install zk
  ```

5. Miscellenous

- [x] [Use Neovim as the man pager reader (manpager)](https://www.visualmode.dev/a-better-man-page-viewer)

  ```bash
   export MANPAGER="nvim +Man!"
  ```

```

```

