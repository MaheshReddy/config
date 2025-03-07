local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

if not lspconfig.clangd.manager then  -- Check if already setup
  lspconfig.clangd.setup{
    capabilities = capabilities,
    cmd = {
      "clangd",
      "--background-index",
      "-log=verbose",
      "--pch-storage=memory",
      "--clang-tidy",
      "--all-scopes-completion",
      "--pretty",
      "--header-insertion=iwyu",
    },
    on_init = function(client)
          print("clangd started for root: " .. client.config.root_dir)
    end,
    on_attach = function(client, bufnr)
          print(string.format("Buffer %d attached to existing clangd instance", bufnr))
    end,
    on_exit = function(code, signal, client_id)
      print("LSP exited with code: " .. code .. " and signal: " .. signal)
    end,
    filetypes = {"c", "cpp", "objc", "objcpp", "header"},
    root_dir = lspconfig.util.root_pattern(
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac',
      '.git',
      vim.fn.getcwd()
    ),
    single_file_support = true,
  }
end
