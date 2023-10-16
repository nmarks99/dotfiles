local cmp = require "plugins.configs.cmp"
local options = {
  mapping = {
    ["<C-k>"] = cmp.mapping.select_prev_item(),
    ["<C-j>"] = cmp.mapping.select_next_item(),
  }
}
return options
