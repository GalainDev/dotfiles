vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })

-- Match the left/down/up/right home-row layout used by AeroSpace, WezTerm,
-- herdr, and tmux. h retains Vim's repeat-find action.
local movement_modes = { 'n', 'x', 'o' }
vim.keymap.set(movement_modes, 'h', ';', { desc = 'Repeat character find' })
vim.keymap.set(movement_modes, 'j', 'h', { desc = 'Move left' })
vim.keymap.set(movement_modes, 'k', 'j', { desc = 'Move down' })
vim.keymap.set(movement_modes, 'l', 'k', { desc = 'Move up' })
vim.keymap.set(movement_modes, ';', 'l', { desc = 'Move right' })

-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])
