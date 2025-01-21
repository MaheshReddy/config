return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        'hrsh7th/cmp-nvim-lsp',
-- optional `vim.uv` typings for lazydev
        { "Bilal2453/luvit-meta", lazy = true },
        "mfussenegger/nvim-jdtls",
    },

    config = function()
        local lspconfig = require("lspconfig")
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local mason_tool_installer = require("mason-tool-installer")

        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local default_capabilities = vim.lsp.protocol.make_client_capabilities()
        default_capabilities = vim.tbl_deep_extend(
            "force",
            default_capabilities,
            cmp_nvim_lsp.default_capabilities()
        )


        local server_configs = {
            -- place language server names and their configuration here as a key-value pair
            lua_ls = {
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = "Replace",
                        },
                        diagnostics = {
                            disable = {
                                "missing-fields"
                            }
                        },
                    },
                },
            },
        }

        mason.setup()

        local mason_ensure_installed = vim.tbl_keys(server_configs or {})
        vim.list_extend(
            mason_ensure_installed,
            {
                -- place other packages you want to install but not configure with mason here
                -- e.g. language servers not configured with nvim-lspconfig, linters, formatters, etc.
              "stylua",
              "jdtls",
              "pylsp",
            }
        )
        mason_tool_installer.setup({
            ensure_installed = mason_ensure_installed
        })

        mason_lspconfig.setup({
            handlers = {
                function(server_name)
                    local server_config = server_configs[server_name] or {}
                    server_config.capabilities = vim.tbl_deep_extend(
                        "force",
                        default_capabilities,
                        server_config.capabilities or {}
                    )
                    lspconfig[server_name].setup(server_config)
                end,
                ['jdtls'] = function() end,
                ['pylsp'] = function() end,
            },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("lsp-attach-keybinds", { clear = true }),
            callback = function(e)
                local keymap = function(keys, func)
                    vim.keymap.set("n", keys, func, { buffer = e.buf })
                end
                local builtin = require("telescope.builtin")

                keymap("gd", builtin.lsp_definitions)
                keymap("gD", vim.lsp.buf.declaration)
                keymap("gr", builtin.lsp_references)
                keymap("gI", builtin.lsp_implementations)
                keymap("<leader>D", builtin.lsp_type_definitions)
                keymap("<leader>ds", builtin.lsp_document_symbols)
                keymap("<leader>ws", builtin.lsp_dynamic_workspace_symbols)
                keymap("<leader>rn", vim.lsp.buf.rename)
                keymap("<leader>ca", vim.lsp.buf.code_action)
                keymap("K", vim.lsp.buf.hover)
            end
        })
    end
}



-- [[ Configure LSP ]]
 --  This function gets run when an LSP connects to a particular buffer.
-- local on_attach = function(_, bufnr)
--   -- NOTE: Remember that lua is a real programming language, and as such it is possible
--   -- to define small helper and utility functions so you don't have to repeat yourself
--   -- many times.
--   --
--   -- In this case, we create a function that lets us more easily define mappings specific
--   -- for LSP related items. It sets the mode, buffer and description for us each time.
--   local nmap = function(keys, func, desc)
--     if desc then
--       desc = 'LSP: ' .. desc
--     end
--
--     vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
--   end
--
--   nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
--   nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
--
--   nmap('gI', vim.lsp.buf.definition, '[G]oto [D]efinition')
--   nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
--   nmap('gd', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
--   nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
--   nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
--   nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
--
--   -- See `:help K` for why this keymap
--   nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
--   nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
--
--   -- Lesser used LSP functionality
--   nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
--   nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
--   nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
--   nmap('<leader>wl', function()
--     print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--   end, '[W]orkspace [L]ist Folders')
--
--   -- Create a command `:Format` local to the LSP buffer
--   vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
--     vim.lsp.buf.format()
--   end, { desc = 'Format current buffer with LSP' })
-- end
--
-- -- Setup neovim lua configuration
-- require('neodev').setup()
--
-- -- Enable the following language servers
-- --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
-- --
-- --  Add any additional override configuration in the following tables. They will be passed to
-- --  the `settings` field of the server config. You must look up that documentation yourself.
-- --
-- --  If you want to override the default filetypes that your language server will attach to you can
-- --  define the property 'filetypes' to the map in question.
-- local servers = {
--   clangd = {}, -- c/c#
--   solargraph = {}, -- ruby
--   -- jdtls =  {}, For java configured nvim-jdtls in lazy.lua
--   -- gopls = {},
--   -- pyright = {},
--   -- rust_analyzer = {},
--   -- tsserver = {},
--   -- html = { filetypes = { 'html', 'twig', 'hbs'} },
--   marksman = {}, -- markdown
--   -- jsonls = {}, These guys fail because they need NPM to install
--   -- bashls = {}, These guys fail because they need NPM to install
--
--   lua_ls = {
--     Lua = {
--       workspace = { checkThirdParty = false },
--       telemetry = { enable = false },
--     },
--   },
-- }
--
-- -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
--
-- -- Ensure the servers above are installed
-- local mason_lspconfig = require 'mason-lspconfig'
--
-- mason_lspconfig.setup {
--   ensure_installed = vim.tbl_keys(servers),
-- }
--
-- mason_lspconfig.setup_handlers {
--   function(server_name)
--     require('lspconfig')[server_name].setup {
--       capabilities = capabilities,
--       on_attach = on_attach,
--       settings = servers[server_name],
--       filetypes = (servers[server_name] or {}).filetypes,
--     }
--   end
-- }
--
-- -- Configure LSP through rust-tools.nvim plugin.
-- -- rust-tools will configure and enable certain LSP features for us.
-- -- See https://github.com/simrat39/rust-tools.nvim#configuration
-- local opts = {
--   tools = {
--     runnables = {
--       use_telescope = true,
--     },
--     inlay_hints = {
--       auto = true,
--       show_parameter_hints = false,
--       parameter_hints_prefix = "",
--       other_hints_prefix = "",
--     },
--   },
--
--   -- all the opts to send to nvim-lspconfig
--   -- these override the defaults set by rust-tools.nvim
--   -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
--   server = {
--     -- on_attach is a callback called when the language server attachs to the buffer
--     on_attach = on_attach,
--     settings = {
--       -- to enable rust-analyzer settings visit:
--       -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
--       ["rust-analyzer"] = {
--         -- enable clippy on save
--         checkOnSave = {
--           command = "clippy",
--         },
--       },
--     },
--   },
-- }
--
-- require("rust-tools").setup(opts)
