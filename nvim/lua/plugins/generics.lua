return {
   -- NOTE: First, some plugins that don't require any configuration
   -- This is extension of built in nvim java lsp. Provides additional wrapprs like
  -- organize_imports, extract_variables, for more info read the github readme.
   'mfussenegger/nvim-jdtls',
   -- Git related plugins, ability to run Git commands within nvim
   'tpope/vim-fugitive',

   'simrat39/rust-tools.nvim',
   'nvim-neotest/nvim-nio',
   {
     "epwalsh/obsidian.nvim",
     version = "*", -- recommended, use latest release instead of latest commit
     lazy = true,
     ft = "markdown",
     -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
     -- event = {
     --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
     --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
     --   "BufReadPre path/to/my-vault/**.md",
     --   "BufNewFile path/to/my-vault/**.md",
     -- },
     dependencies = {
       -- Required.
       "nvim-lua/plenary.nvim",

       -- see below for full list of optional dependencies 👇
     },
     opts = {
       workspaces = {
         {
           name = "personal",
           path = "~/ob_vaults/personal",
         },
         {
           name = "work",
           path = "~/ob_vaults/work",
         },
       },

       -- see below for full list of options 👇
     },
   },
   -- NOTE: This is where your plugins related to LSP can be installed.
   --  The configuration is done below. Search for lspconfig to find it below.
   -- {
   --   -- LSP Configuration & Plugins
   --   'neovim/nvim-lspconfig',
   --   dependencies = {
   --     -- Automatically install LSPs to stdpath for neovim
   --     { 'williamboman/mason.nvim', config = true },
   --     'williamboman/mason-lspconfig.nvim',
   --
   --     -- Useful status updates for LSP
   --     -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
   --     { 'j-hui/fidget.nvim',       tag = 'legacy', opts = {} },
   --
   --     -- Additional lua configuration, makes nvim stuff amazing!
   --     'folke/neodev.nvim',
   --   },
   -- },
   -- Useful plugin to show you pending keybinds.
   { 'folke/which-key.nvim',  version = '3.3.0' },
   {
     -- Adds git related signs to the gutter, as well as utilities for managing changes
     'lewis6991/gitsigns.nvim',
     opts = {
       -- See `:help gitsigns.txt`
       signs = {
         add = { text = '+' },
         change = { text = '~' },
         delete = { text = '_' },
         topdelete = { text = '‾' },
         changedelete = { text = '~' },
       },
       on_attach = function(bufnr)
         vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })

         -- don't override the built-in and fugitive keymaps
         local gs = package.loaded.gitsigns
         vim.keymap.set({ 'n', 'v' }, ']c', function()
           if vim.wo.diff then return ']c' end
           vim.schedule(function() gs.next_hunk() end)
           return '<Ignore>'
         end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
         vim.keymap.set({ 'n', 'v' }, '[c', function()
           if vim.wo.diff then return '[c' end
           vim.schedule(function() gs.prev_hunk() end)
           return '<Ignore>'
         end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
       end,
     },
   },

   {
     -- Theme inspired by Atom
     'navarasu/onedark.nvim',
     priority = 1000,
     config = function()
       vim.cmd.colorscheme 'onedark'
     end,
   },
    {
      -- Set lualine as statusline
      'nvim-lualine/lualine.nvim',
      -- See `:help lualine.txt`
      config = function()
        local function oc_status()
          local ok, oc = pcall(require, 'config.opencode')
          if not ok then return '' end
          local s = oc.status()
          if s == 'busy' then return '[OC: thinking...]' end
          if s == 'idle' then return '[OC: ready]' end
          return '' -- 'off' — show nothing
        end

        require('lualine').setup({
          options = {
            icons_enabled = false,
            theme = 'onedark',
            component_separators = '|',
            section_separators = '',
          },
          sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = { 'filename' },
            lualine_x = { oc_status, 'encoding', 'fileformat', 'filetype' },
            lualine_y = { 'progress' },
            lualine_z = { 'location' },
          },
        })
      end,
   },

   {
     -- Add indentation guides even on blank lines
     'lukas-reineke/indent-blankline.nvim',
     main = "ibl",
     -- Enable `lukas-reineke/indent-blankline.nvim`
     -- See `:help indent_blankline.txt`
     opts = {
     },
   },

   -- "gc" to comment visual regions/lines
   { 'numToStr/Comment.nvim', opts = {} },

   -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
   --       These are some example plugins that I've included in the kickstart repository.
   --       Uncomment any of the lines below to enable them.
   --require 'kickstart.plugins.autoformat',
   --require 'kickstart.plugins.debug',

   -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
   --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
   --    up-to-date with whatever is in the kickstart repo.
   --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
   --
   --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
   -- { import = 'custom.plugins' },
 }
