local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = {
  "html",
  "cssls",
  "jedi_language_server"
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


