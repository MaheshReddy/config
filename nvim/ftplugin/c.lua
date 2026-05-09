-- clangd configuration using vim.lsp.config (nvim 0.11+)
vim.lsp.config.clangd = {
    cmd = {
        "clangd",
        "--background-index",
        "--pch-storage=memory",
        "--clang-tidy",
        "--all-scopes-completion",
        "--pretty",
        "--header-insertion=iwyu",
    },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = {
        ".clangd",
        ".clang-tidy",
        ".clang-format",
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac",
        ".git",
    },
    single_file_support = true,
}

vim.lsp.enable("clangd")
