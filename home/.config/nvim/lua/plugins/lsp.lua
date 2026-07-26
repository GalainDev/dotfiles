local servers = {
  'gopls',
  'lua_ls',
  'pyright',
  'ruff',
  'rust_analyzer',
  'ts_ls',
  'eslint',
}

return {
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    opts = {},
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
      end

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      vim.diagnostic.config({
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        signs = true,
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, prefix = '●' },
      })

      local group = vim.api.nvim_create_augroup('UserLspKeymaps', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(event)
          local function map(keys, func, description)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. description })
          end

          map('K', vim.lsp.buf.hover, 'Hover documentation')
          map('gd', vim.lsp.buf.definition, 'Go to definition')
          map('gD', vim.lsp.buf.declaration, 'Go to declaration')
          map('gI', vim.lsp.buf.implementation, 'Go to implementation')
          map('gr', vim.lsp.buf.references, 'Find references')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
          map('<leader>ld', vim.diagnostic.open_float, 'Line diagnostics')
          map('[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
          map(']d', vim.diagnostic.goto_next, 'Next diagnostic')
        end,
      })
    end,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = { ensure_installed = servers },
  },
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      require('luasnip.loaders.from_vscode').lazy_load()
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        }, {
          { name = 'buffer' },
        }),
      })
    end,
  },
}
