# FZF-Lua Optimization TODOs

## Priority 1 - Critical Fixes

### [ ] 1. Fix Keymap Structure
**Current Issue**: Keymaps are defined outside the plugin return table
**Fix**: Move all `vim.api.nvim_set_keymap` calls inside the `config = function()` block
**Impact**: Ensures keymaps are properly loaded with the plugin

### [ ] 2. Modernize Keymap API
**Current Issue**: Using old `vim.api.nvim_set_keymap` API
**Fix**: Replace with `vim.keymap.set` for better ergonomics
**Impact**: Cleaner syntax and better maintainability

## Priority 2 - Performance Optimizations

### [ ] 3. Add File Exclusions
**Current Issue**: No exclusions for common directories (node_modules, .git, etc.)
**Fix**: Add `find_opts`, `rg_opts`, and `fd_opts` with exclusions
**Impact**: Faster file searching, less noise in results

### [ ] 4. Optimize Ripgrep Settings
**Current Issue**: Basic ripgrep configuration
**Fix**: Add `--hidden --follow` with smart exclusions
**Impact**: Better search performance and more comprehensive results

### [ ] 5. Enhance FZF Options
**Current Issue**: Basic fzf configuration
**Fix**: Add optimized fzf_opts for better UI and performance
**Impact**: Better user experience and faster searching

## Priority 3 - Feature Enhancements

### [ ] 6. Add LSP Integration
**Current Issue**: No LSP symbol searching
**Fix**: Add keymaps for lsp_document_symbols, lsp_workspace_symbols, etc.
**Impact**: Better code navigation capabilities

### [ ] 7. Add Visual Selection Grep
**Current Issue**: No visual selection search capability
**Fix**: Add `fzf.grep_visual` keymap
**Impact**: Can search for visually selected text

### [ ] 8. Add Git Operations
**Current Issue**: Only has git_status
**Fix**: Add git_commits, git_branches keymaps
**Impact**: Better git workflow integration

### [ ] 9. Add File Type Searches
**Current Issue**: No quick file type filtering
**Fix**: Add Lua, JS, and other file type specific searches
**Impact**: Faster access to specific file types

### [ ] 10. Add TODO/Comment Search
**Current Issue**: No way to find TODOs/FIXMEs
**Fix**: Add grep search for TODO|FIXME|HACK|NOTE patterns
**Impact**: Better code maintenance workflow

## Priority 4 - UI/UX Improvements

### [ ] 11. Optimize Preview Window
**Current Issue**: Basic preview configuration
**Fix**: Better preview window sizing and bat integration
**Impact**: Better file preview experience

### [ ] 12. Enhance Window Options
**Current Issue**: Fixed window size
**Fix**: Dynamic sizing based on screen size
**Impact**: Better adaptation to different screen sizes

### [ ] 13. Improve Color Scheme
**Current Issue**: Basic highlighting
**Fix**: Better integration with your theme
**Impact**: More consistent visual experience

## Priority 5 - Advanced Features

### [ ] 14. Add Session-Aware Oldfiles
**Current Issue**: Basic oldfiles functionality
**Fix**: Include current session files
**Impact**: More relevant recent file suggestions

### [ ] 15. Enhance Quickfix Integration
**Current Issue**: Basic quickfix support
**Fix**: Better quickfix formatting with icons
**Impact**: Better error/search result management

## Implementation Order Recommendation:

1. **Start with Priority 1** - Fix the keymap structure first
2. **Add Priority 2** - Performance improvements for immediate benefits
3. **Gradually add Priority 3** - Feature enhancements based on your workflow
4. **Polish with Priority 4 & 5** - UI improvements and advanced features

Would you like to tackle these one by one, starting with the critical fixes?