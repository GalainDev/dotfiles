return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>lf',
        function() require('conform').format({ async = true, lsp_format = 'fallback' }) end,
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        css = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        python = { 'ruff_format' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        go = { 'goimports', 'gofmt' },
      },
      format_on_save = { timeout_ms = 1500, lsp_format = 'fallback' },
    },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'eslint_d', 'prettierd', 'ruff', 'stylua' },
      run_on_start = true,
    },
  },
}
