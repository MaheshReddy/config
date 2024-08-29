require('options')
require('plugins.lazy')
require('plugins.telescope')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.completion')
require('keymaps')
-- inspired from https://github.com/agalea91/dotfiles/blob/main/nvim/lua/workflows.lua
 -- [[ Setting options ]]

 -- [[ Highlight on yank ]]
 -- See `:help vim.highlight.on_yank()`
 local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
 vim.api.nvim_create_autocmd('TextYankPost', {
   callback = function()
     vim.highlight.on_yank()
   end,
   group = highlight_group,
   pattern = '*',
 })

--
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
