return {

    -- NOTE: First, some plugins that don't require any configuration

    -- Git related plugins
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',

    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',


    -- buffer line for files at the top
    {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons'
    },

    { "nvim-tree/nvim-tree.lua" },

    {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
	-- Automatically install LSPs to stdpath for neovim
	{ 'williamboman/mason.nvim', config = true },
	'williamboman/mason-lspconfig.nvim',

	-- Useful status updates for LSP
	-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
	{ 'j-hui/fidget.nvim', opts = {} },

	-- Additional lua configuration, makes nvim stuff amazing!
	'folke/neodev.nvim',
    },
    },

    {
    -- Autocompletion
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
    { 'folke/which-key.nvim', opts = {} },

    {
    -- Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
	vim.cmd.colorscheme 'onedark'
    end,
    },

    {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
	options = {
	    icons_enabled = false,
	    theme = 'onedark',
	    component_separators = '|',
	    section_separators = '',
	},
    },
    },

    {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- See `:help ibl`
    main = 'ibl',
    opts = {
	scope = {
	    show_start = true,
	    show_end = true,
	}
    },
    },

    {
    'numToStr/Comment.nvim',
    opts = {}
    },

    {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
	'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    },
}
