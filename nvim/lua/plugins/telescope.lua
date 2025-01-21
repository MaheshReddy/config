 -- [[ Configure Telescope ]]
 -- See `:help telescope` and `:help telescope.setup()`
return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        local keymap = function(keys, func)
            vim.keymap.set("n", keys, func, {})
        end

        require("telescope").setup({
   defaults = {
     layout_strategy = "vertical",
     mappings = {
       i = {
         ['<C-u>'] = false,
         ['<C-d>'] = false,
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
 })
        local builtin = require("telescope.builtin")

        keymap("<leader>sf", builtin.find_files)
        keymap("<leader>sn", function()
            builtin.find_files {
                cwd = vim.fn.stdpath "config"
            }
        end)
        keymap("<leader><leader>", builtin.buffers)
        keymap("<leader>s/", builtin.live_grep)
        keymap("<leader>/", function()
            builtin.current_buffer_fuzzy_find(
                require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                }
            )
        end)
    end
}
