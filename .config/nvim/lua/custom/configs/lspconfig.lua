local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = {
    "html",
    "cssls",
}

-- attach all servers that don't have specific settings
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- rust-analyzer
lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"rust"},
  root_dir = lspconfig.util.root_pattern("Cargo.toml")
})

-- clangd
lspconfig.clangd.setup({
  filetypes = {"c", "cpp", "h", "hpp"},
  on_attach = on_attach,
  capabilities = capabilities
})

lspconfig.pyright.setup ({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = {"pyright-langserver", "--stdio"},
    filetypes = {"python"},
    single_file_support = true,
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = false,
                typeCheckingMode = "on",
            },
        },
    },
})


