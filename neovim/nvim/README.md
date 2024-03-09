
% !TEX TS-program = pdflatex 
% !TEX encoding = UTF-8 Unicode

\documentclass[11pt,a4paper,english]{article}

\usepackage{dirtree}

\begin{document}

# Neovim setup

## Contents
1. Directory structure
The folder structure should be that `$XDG_CONFIG_HOME` should have a `nvim` 
folder which will contain `init.lua` file, which is in the neovim `runtimepath`.

\dirtree{%
.1 $XDG_CONFIG_HOME. 
.2 nvim.
.3 init.lua.
}

2. `init.lua`, the initialization file.

3. `lazy.nvim` setup

3. Plugin management

4. PDF Processing

\end{document}


