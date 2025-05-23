# nvim-inplace-preview

A Neovim plugin that shows transformed/processed versions of your code in-place using external tools. Perfect for previewing simplified code, formatted output, compiled results, or any other transformation.

## Features

- Toggle between original and transformed code views in the same buffer
- Configurable external transformation tools
- Preserves original code - preview is temporary and read-only
- Customizable keybindings
- Statusline integration
- Works with any external command that can process text

## Installation

### Using vim-plug

Add to your `init.vim`:

```vim
Plug 'yourusername/nvim-inplace-preview'
