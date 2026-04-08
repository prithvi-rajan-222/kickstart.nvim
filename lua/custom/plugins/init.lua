-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.relativenumber = true

-- [[ Custom Keymaps ]]
vim.keymap.set('n', '<leader>cd', vim.cmd.Ex)
vim.g.tmux_navigator_disable_when_zoomed = 1
vim.keymap.set('i', '<Tab>', '<Tab>', { noremap = true })
vim.keymap.set('n', '<leader>b', ':!./compile.sh<CR>')
vim.keymap.set('n', '<leader>r', ':!./A < input.txt<CR>')

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  group = vim.api.nvim_create_augroup('custom-kickstart-overrides', { clear = true }),
  callback = function()
    local extra_servers = {
      clangd = {},
      pyrefly = {},
      sourcekit = {
        cmd = { 'xcrun', 'sourcekit-lsp' },
      },
      tailwindcss = {},
      ts_ls = {},
    }

    for name, config in pairs(extra_servers) do
      vim.lsp.config(name, config)
      vim.lsp.enable(name)
    end

    local ok_conform, conform = pcall(require, 'conform')
    if ok_conform then
      conform.setup {
        notify_on_error = false,
        format_on_save = function(bufnr)
          local disable_filetypes = { c = true, cpp = true }
          if disable_filetypes[vim.bo[bufnr].filetype] then return nil end

          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end,
        formatters_by_ft = {
          css = { 'prettier' },
          html = { 'prettier' },
          javascript = { 'prettier' },
          javascriptreact = { 'prettier' },
          json = { 'prettier' },
          lua = { 'stylua' },
          typescript = { 'prettier' },
          typescriptreact = { 'prettier' },
        },
      }
    end

    local ok_treesitter, treesitter = pcall(require, 'nvim-treesitter')
    if ok_treesitter then
      treesitter.install { 'javascript', 'jsdoc', 'tsx', 'typescript' }
    end
  end,
})

---@module 'lazy'
---@type LazySpec
return {
  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.gitsigns',

  {
    'windwp/nvim-ts-autotag',
    lazy = false,
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        ['html'] = {
          enable_close = false,
        },
      },
    },
  },

  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
  { -- Git plugin
    'tpope/vim-fugitive',
  },
}
