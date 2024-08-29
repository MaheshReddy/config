 -- See `:help vim.keymap.set()`

 -- See `:help vim.keymap.set()`
 vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

 -- Remap for dealing with word wrap
 vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
 vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

 -- Diagnostic keymaps
 vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
 vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
 vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
 vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

 -- Telescope See `:help telescope.builtin`
 vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
 vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
 vim.keymap.set('n', '<leader>/', function()
   -- You can pass additional configuration to telescope to change theme, layout, etc.
   require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
     winblend = 10,
     previewer = false,
   })
 end, { desc = '[/] Fuzzily search in current buffer' })

 vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
 vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
 vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
 vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
 vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
 vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
 vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]resume' })
 vim.keymap.set("n", "<leader>fg", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")


 -- Obsidian workflows
-- convert note to template and remove leading white space
 vim.keymap.set("n", "<leader>on", ":ObsidianTemplate note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")

 -- search for files in full vault
vim.keymap.set("n", "<leader>os", ":Telescope find_files search_dirs={\"/Users/elireddy/Documents/ob_vaults/\"}<cr>")
vim.keymap.set("n", "<leader>oz", ":Telescope live_grep search_dirs={\"/Users/elireddy/Documents/ob_vaults/\"}<cr>")


-- Move around in tabs
 -- -- Switch to the next tab
vim.keymap.set('n', '<Tab>', ':tabnext<CR>', { noremap = true, silent = true })

-- Switch to the previous tab
vim.keymap.set('n', '<S-Tab>', ':tabprevious<CR>', { noremap = true, silent = true })

-- Move the current tab to the right
vim.keymap.set('n', '<C-l>', ':tabnext<CR>', { noremap = true, silent = true })

-- Move the current tab to the left
vim.keymap.set('n', '<C-h>', ':tabprevious<CR>', { noremap = true, silent = true })

-- Close the current tab
vim.keymap.set('n', '<leader><C-w>', ':tabclose<CR>', { noremap = true, silent = true })

