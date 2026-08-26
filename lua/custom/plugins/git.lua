local function start_branch_review()
  local target = 'origin/HEAD'
  local result = vim.system({ 'git', 'merge-base', target, 'HEAD' }, { text = true }):wait()

  assert(result.code == 0, result.stderr)

  require('gitsigns').change_base(vim.trim(result.stdout), true)
  vim.cmd('DiffviewOpen ' .. target .. '...HEAD')
end

local function close_review()
  require('gitsigns').reset_base(true)
  vim.cmd 'DiffviewClose'
end

---@module 'lazy'
---@type LazySpec
return {
  {
    'lewis6991/gitsigns.nvim',
    opts = function(_, opts)
      opts.attach_to_untracked = true

      opts.on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end

        map('n', ']g', function() gitsigns.nav_hunk 'next' end, 'Git next hunk')
        map('n', '[g', function() gitsigns.nav_hunk 'prev' end, 'Git previous hunk')

        map('n', '<leader>gp', gitsigns.preview_hunk, 'Git preview hunk')
        map('n', '<leader>gi', gitsigns.preview_hunk_inline, 'Git preview hunk inline')
        map('n', '<leader>gd', gitsigns.diffthis, 'Git diff current file')
        map('n', '<leader>gD', function() gitsigns.diffthis '@' end, 'Git diff current file against HEAD')
        map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, 'Git blame line')

        map('n', '<leader>gs', gitsigns.stage_hunk, 'Git stage hunk')
        map('n', '<leader>gr', gitsigns.reset_hunk, 'Git reset hunk')
        map('n', '<leader>gS', gitsigns.stage_buffer, 'Git stage buffer')
        map('n', '<leader>gR', gitsigns.reset_buffer, 'Git reset buffer')

        map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Git stage selected hunk')
        map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Git reset selected hunk')

        map({ 'o', 'x' }, 'ig', gitsigns.select_hunk, 'Git hunk')
      end
    end,
  },

  {
    'dlyongemallo/diffview-plus.nvim',
    version = '*',
    main = 'diffview',
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFocusFiles',
      'DiffviewFileHistory',
    },
    keys = {
      { '<leader>go', '<cmd>DiffviewOpen<cr>', desc = 'Git review working tree' },
      { '<leader>gv', start_branch_review, desc = 'Git review branch' },
      { '<leader>gq', close_review, desc = 'Git close review' },
      { '<leader>gf', '<cmd>DiffviewFocusFiles<cr>', desc = 'Git focus changed files' },
      { '<leader>gl', '<cmd>DiffviewFileHistory %<cr>', desc = 'Git log current file' },
      { '<leader>gL', '<cmd>DiffviewFileHistory<cr>', desc = 'Git log repository' },
    },
    opts = function()
      local actions = require('diffview.config').actions

      return {
        default_args = {
          DiffviewOpen = { '--imply-local' },
        },
        keymaps = {
          file_panel = {
            { 'n', 'j', false },
            { 'n', 'k', false },
            { 'n', 'n', actions.next_entry, { desc = 'Next file' } },
            { 'n', 'e', actions.prev_entry, { desc = 'Previous file' } },
          },
        },
      }
    end,
  },

  {
    'folke/which-key.nvim',
    opts = function(_, opts)
      opts.spec = vim.tbl_filter(function(mapping) return mapping[1] ~= '<leader>h' end, opts.spec)
      table.insert(opts.spec, { '<leader>g', group = '[G]it', mode = { 'n', 'v' } })
    end,
  },
}
