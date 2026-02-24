local function contains(table, value)
    for _, table_value in ipairs(table) do
        if table_value == value then
            return true
        end
    end

    return false
end

-- helper function for finding a filename in a directory which matches
-- the specified pattern
local function find_file(directory, pattern)
    local filename_found = ''
    local pfile = io.popen('ls "' .. directory .. '"')

    if (pfile == nil) then
        return ''
    end

    for filename in pfile:lines() do
        if (string.find(filename, pattern) ~= nil) then
            filename_found = filename
            break
        end
    end

    return filename_found
end

-- gathers all of the bemol-generated files and adds them to the LSP workspace
local function bemol()
    local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
    local ws_folders_lsp = {}
    if bemol_dir then
        local file = io.open(bemol_dir .. "/ws_root_folders", "r")
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line)
            end
            file:close()
        end

        for _, line in ipairs(ws_folders_lsp) do
            if not contains(vim.lsp.buf.list_workspace_folders(), line) then
                vim.lsp.buf.add_workspace_folder(line)
            end
        end
    end
end

local jdtls = require("jdtls")
local jdtls_setup = require "jdtls.setup"

local home = os.getenv("HOME")
local root_markers = { ".bemol", }

-- 🔧 FIX 1: Add multiple root markers for Brazil packages and regular Java projects
local root_markers = {
    ".bemol",      -- Amazon Bemol workspace
    ".git",        -- Git repository
    "Config",      -- Brazil package
    "mvnw",        -- Maven wrapper
    "gradlew",     -- Gradle wrapper
    "pom.xml",     -- Maven project
    "build.gradle" -- Gradle project
}
local root_dir = jdtls_setup.find_root(root_markers)

-- 🔧 FIX 2: Add error handling if no root found
if not root_dir or root_dir == "" then
    vim.notify(
        "⚠️  JDTLS: No Java project root found. Looking for: " .. table.concat(root_markers, ", "),
        vim.log.levels.WARN
    )
    return  -- Don't start jdtls if no root found
end
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
local path_to_jdtls = home .."/POT/neovim/jdtls"
local os_type = vim.fn.has("macunix") and "mac" or "linux"
local path_to_config = path_to_jdtls .. "/config_" .. os_type
local path_to_lombok = path_to_jdtls .. "/lombok.jar"
local path_to_plugins = path_to_jdtls .. "/plugins/"
-- the eclipse jar is suffixed with a bunch of version nonsense, so we find it by pattern matching
local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")

if path_to_jar == path_to_plugins then  -- find_file returned empty string
    vim.notify(
        "❌ JDTLS: Could not find equinox launcher jar in " .. path_to_plugins,
        vim.log.levels.ERROR
    )
    return
end

if vim.fn.filereadable(path_to_jar) == 0 then
    vim.notify("JDTLS: launcher jar not found at" .. path_to_jar .. "\n Installl jdtls at that path.", vim.log.levels.ERROR)
    return
end
local config = {
    cmd = {
        -- assumes the java binary is in your PATH and at least java17;
        -- if not, specify the full path to the binary
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xmx1g",
        "-javaagent:" .. path_to_lombok,
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        "-jar",
        path_to_jar,

        "-configuration",
        path_to_config,

        "-data",
        workspace_dir,
    },

    root_dir = root_dir,

    capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    },

    settings = {
        java = {
            references = {
                includeDecompiledSources = true,
            },
            eclipse = {
                downloadSources = true,
            },
            maven = {
                downloadSources = true,
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
        }
    },

    -- run our bemol function when the LSP attaches to the buffer
    on_attach = function(client, bufnr)
        bemol()
        vim.notify("JDTLS attached to the " .. vim.api.nvim_buf_get_name(bufnr) .. "\n Project root:" .. root_dir, vim.log.levels.INFO)
    end,
}
-- LSP extensions for Neovim and eclipse.jdt.ls more help jdtls
vim.notify("🚀 Starting JDTLS for project: " .. project_name, vim.log.levels.INFO)
jdtls.start_or_attach(config)
