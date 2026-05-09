return {
    "neovim/nvim-lspconfig",
    dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        { "Bilal2453/luvit-meta", lazy = true },
        "mfussenegger/nvim-jdtls",
    },

    config = function()
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        -- Shared capabilities available to ftplugin files via vim.g.lsp_capabilities
        local default_capabilities = vim.lsp.protocol.make_client_capabilities()
        default_capabilities = vim.tbl_deep_extend(
            "force",
            default_capabilities,
            cmp_nvim_lsp.default_capabilities()
        )
        -- Store globally so ftplugin files can access it
        vim.g.lsp_capabilities = default_capabilities

        -- LSP keybindings when attached to buffer
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("lsp-attach-keybinds", { clear = true }),
            callback = function(e)
                local keymap = function(keys, func)
                    vim.keymap.set("n", keys, func, { buffer = e.buf })
                end
                local builtin = require("telescope.builtin")

                keymap("gd", builtin.lsp_definitions)
                keymap("gD", vim.lsp.buf.declaration)
                keymap("gr", vim.lsp.buf.references)
                keymap("gI", builtin.lsp_implementations)
                keymap("<leader>D", builtin.lsp_type_definitions)
                keymap("<leader>ds", builtin.lsp_document_symbols)
                keymap("<leader>ws", builtin.lsp_dynamic_workspace_symbols)
                keymap("<leader>rn", vim.lsp.buf.rename)
                keymap("<leader>ca", vim.lsp.buf.code_action)
                keymap("<leader>cs", vim.lsp.buf.incoming_calls)
                keymap("K", vim.lsp.buf.hover)
            end
        })

        -- :LspKeys — floating cheatsheet
        vim.api.nvim_create_user_command("LspKeys", function()
            local lines = {
                " LSP Keybindings (leader = Space)",
                " ─────────────────────────────────",
                " Navigation",
                "   gd        Go to definition",
                "   gD        Go to declaration",
                "   gr        References",
                "   gI        Go to implementation",
                "   <Space>D  Type definition",
                "",
                " Search",
                "   <Space>ds Document symbols",
                "   <Space>ws Workspace symbols",
                "   <Space>cs Incoming calls",
                "",
                " Actions",
                "   K         Hover docs",
                "   <Space>rn Rename symbol",
                "   <Space>ca Code actions",
                "",
                " Diagnostics",
                "   [d        Previous diagnostic",
                "   ]d        Next diagnostic",
                "   <Space>e  Float diagnostic",
            }
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
            local width = 40
            local height = #lines
            vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width = width,
                height = height,
                col = math.floor((vim.o.columns - width) / 2),
                row = math.floor((vim.o.lines - height) / 2),
                style = "minimal",
                border = "rounded",
                title = " LSP Keys ",
                title_pos = "center",
            })
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
            vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf })
        end, {})
    end
}
