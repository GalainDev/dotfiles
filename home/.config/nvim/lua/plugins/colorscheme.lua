return {
  {
    'Mofiqul/vscode.nvim',
    name = 'vscode',
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = 'dark'
      require('vscode').setup({
        transparent = true,
        italic_comments = false,
        italic_inlayhints = false,
        terminal_colors = true,
      })
      vim.cmd.colorscheme('vscode')
    end,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    opts = { transparent_background = true },
  },
  {
    'folke/tokyonight.nvim',
    lazy = false,
    opts = { transparent = true },
  },
  {
    'ellisonleao/gruvbox.nvim',
    lazy = false,
    opts = { transparent_mode = true },
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    opts = { transparent = true },
  },
  {
    'Mofiqul/dracula.nvim',
    lazy = false,
    opts = { transparent_bg = true },
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    opts = {
      dark_variant = 'moon',
      styles = { transparency = true },
    },
  },
}
