 -- [[ Configure Telescope ]]
 -- See `:help telescope` and `:help telescope.setup()`
 require('telescope').setup {
   defaults = {
     layout_strategy = "vertical",
     file_previewer = require('telescope.previewers').vim_buffer_cat.new,
     mappings = {
       i = {
         ['<C-u>'] = false,
         ['<C-d>'] = false,
        -- Open in horizontal split
        ["<C-x>"] = require('telescope.actions').select_horizontal,

        -- Open in vertical split
        ["<C-v>"] = require('telescope.actions').select_vertical,

        -- Open in a new tab
        ["<C-t>"] = require('telescope.actions').select_tab,
       },
      n = {
        -- Open in horizontal split
        ["<C-x>"] = require('telescope.actions').select_horizontal,

        -- Open in vertical split
        ["<C-v>"] = require('telescope.actions').select_vertical,

        -- Open in a new tab
        ["<C-t>"] = require('telescope.actions').select_tab,
      },
     },
     layout_config = {
      preview_height = 0.7,
      vertical = {
        size = {
          width = "95%",
          height = "95%",
        },
      },
    },
   },
 }

 -- Enable telescope fzf native, if installed
 pcall(require('telescope').load_extension, 'fzf')
 pcall(require('telescope').load_extension, 'live_grep_args')

