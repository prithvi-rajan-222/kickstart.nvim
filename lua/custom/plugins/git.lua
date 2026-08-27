local function start_branch_review()
  local target = 'origin/HEAD'
  local result = vim.system({ 'git', 'merge-base', target, 'HEAD' }, { text = true }):wait()

  assert(result.code == 0, result.stderr)

  require('gitsigns').change_base(vim.trim(result.stdout), true)
  vim.cmd('CodeDiff ' .. target .. '...')
end

local function start_working_tree_review()
  require('gitsigns').reset_base(true)
  vim.cmd 'CodeDiff'
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
    'esmuellert/codediff.nvim',
    version = '*',
    cmd = 'CodeDiff',
    keys = {
      { '<leader>go', start_working_tree_review, desc = 'Git review working tree' },
      { '<leader>gv', start_branch_review, desc = 'Git review branch' },
      { '<leader>gl', '<cmd>CodeDiff history HEAD~20 %<cr>', desc = 'Git log current file' },
      { '<leader>gL', '<cmd>CodeDiff history<cr>', desc = 'Git log repository' },
    },
    init = function()
      local group = vim.api.nvim_create_augroup('codediff_gitsigns_base', { clear = true })

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeDiffClose',
        callback = function() require('gitsigns').reset_base(true) end,
      })
    end,
    opts = {
      diff = {
        layout = 'side-by-side',
      },
      explorer = {
        position = 'left',
        hidden = false,
        initial_focus = 'modified',
        view_mode = 'list',
      },
      keymaps = {
        view = {
          quit = { 'q', '<leader>gq' },
          toggle_explorer = '<leader>ge',
          focus_explorer = '<leader>gf',
        },
      },
    },
  },

  {
    'folke/which-key.nvim',
    opts = function(_, opts)
      opts.spec = vim.tbl_filter(function(mapping) return mapping[1] ~= '<leader>h' end, opts.spec)
      table.insert(opts.spec, { '<leader>g', group = '[G]it', mode = { 'n', 'v' } })
    end,
  },
}
