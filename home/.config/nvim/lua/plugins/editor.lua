return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = { 'neovim-treesitter/treesitter-parser-registry' },
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter').setup({})
      require('nvim-treesitter').install({
          'bash',
          'css',
          'go',
          'html',
          'javascript',
          'json',
          'lua',
          'markdown',
          'python',
          'regex',
          'rust',
          'tsx',
          'typescript',
          'vim',
          'yaml',
      })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'css', 'go', 'html', 'javascript', 'json', 'lua', 'python', 'rust', 'tsx', 'typescript', 'yaml' },
        callback = function()
          vim.treesitter.start()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      indent = { char = '│' },
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
      },
    },
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gc', mode = { 'n', 'x' }, desc = 'Toggle comment' },
    },
    opts = {},
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },
}
