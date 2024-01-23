local plugins = {

    "dstein64/vim-startuptime",

    -- Git related plugins
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',

    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- comment
    'preservim/nerdcommenter',

    -- catpuccin theme
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

    -- ayu theme
    { "Shatur/neovim-ayu", priority = 1000 },

    {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {
	-- your configuration comes here
	-- or leave it empty to use the default settings
	-- refer to the configuration section below
      }
    },

    -- bufferline tabs at the top
    {
	'akinsho/bufferline.nvim',
	version = "*",
	dependencies = 'nvim-tree/nvim-web-devicons',
    },

    -- File explorer tree
    { "nvim-tree/nvim-tree.lua" },

    -- LSP Configuration & Plugins
    {
	'neovim/nvim-lspconfig',
	dependencies = {
	    -- Automatically install LSPs to stdpath for neovim
	    { 'williamboman/mason.nvim', config = true },
	    'williamboman/mason-lspconfig.nvim',

	    -- Useful status updates for LSP
	    { 'j-hui/fidget.nvim', opts = {} },

	    -- Additional lua configuration, makes nvim stuff amazing!
	    'folke/neodev.nvim',
	},
    },

    -- Autocompletion
    {
	'hrsh7th/nvim-cmp',
	dependencies = {
	    -- Snippet Engine & its associated nvim-cmp source
	    'L3MON4D3/LuaSnip',
	    'saadparwaiz1/cmp_luasnip',

	    -- Adds LSP completion capabilities
	    'hrsh7th/cmp-nvim-lsp',
	    'hrsh7th/cmp-path',

	    -- Adds a number of user-friendly snippets
	    'rafamadriz/friendly-snippets',
	},
    },

    -- Useful plugin to show you pending keybinds.
    -- { 'folke/which-key.nvim', opts = {} },

    -- status line at the bottom
    {
	'nvim-lualine/lualine.nvim',
	opts = {
	    options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = '|',
		section_separators = '',
	    },
	},
    },

    -- indentation guides (see :help ibl)
    {
	'lukas-reineke/indent-blankline.nvim',
	main = 'ibl',
	opts = {
	    scope = {
		show_start = true,
		show_end = true,
	    }
	},
    },

    -- Highlight, edit, and navigate code
    {
	'nvim-treesitter/nvim-treesitter',
	dependencies = {
	    'nvim-treesitter/nvim-treesitter-textobjects',
	},
	build = ':TSUpdate',
    },

    -- start page for neovim
    {
	'goolord/alpha-nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	config = function ()
	    require'alpha'.setup(require'alpha.themes.startify'.config)
	end
    },
}

-- ensure lazy.nvim is installed, call setup with above table
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)
require('lazy').setup(plugins, {})
