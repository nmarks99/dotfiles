local M = {}

M.nvimtree = {
  n = {
    -- toggle
    ["<Bslash>n"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
  }
}

M.crates = {
  n = {
    ["<leader>rcu"] = {
      function ()
        require('crates').upgrade_all_crates()
      end,
      "update rust crates"
    }
  }
}

M.comment = {

  -- toggle comment in both modes
  n = {
    ["++"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "Toggle comment",
    },
  },

}

M.tabufline = {

  n = {
    -- cycle through buffers
    ["<A-.>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },

    ["<A-,>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },

    -- close buffer + hide terminal buffer
    ["<A-x>"] = {
      function()
        require("nvchad_ui.tabufline").close_buffer()
      end,
      "Close buffer",
    },
  },
}


return M
