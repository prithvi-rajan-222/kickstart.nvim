local function find_review_file(view, path)
  for _, file in view.files:iter() do
    if file.path == path then return file end
  end
end

local function set_cursor(winid, position)
  if not (winid and vim.api.nvim_win_is_valid(winid)) then return end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  local line = math.min(position[1], vim.api.nvim_buf_line_count(bufnr))
  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  local column = math.min(position[2], #text)

  vim.api.nvim_win_set_cursor(winid, { line, column })
end

local function setup_diffview_follow()
  local group = vim.api.nvim_create_augroup('kickstart-diffview-follow', { clear = true })
  local following = setmetatable({}, { __mode = 'k' })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    desc = 'Keep Diffview comparison panes aligned with local file navigation',
    callback = function(event)
      local view = require('diffview.lib').get_current_view()
      if not view then return end
      assert(view.set_file_by_path, 'Diffview follow requires DiffView:set_file_by_path()')
      if not (view.cur_layout and view.panel.cur_file) then return end
      if following[view] or vim.bo[event.buf].buftype ~= '' then return end

      local main = view.cur_layout:get_main_win()
      if not (main and main.id == vim.api.nvim_get_current_win()) then return end

      local target_name = vim.api.nvim_buf_get_name(event.buf)
      if target_name == '' then return end

      local target_path = vim.fs.relpath(view.adapter.ctx.toplevel, target_name)
      if target_path == view.panel.cur_file.path then return end

      local source_file = view.panel.cur_file
      local target_file = target_path and find_review_file(view, target_path) or nil
      following[view] = true

      vim.schedule(function()
        if not (vim.api.nvim_tabpage_is_valid(view.tabpage) and vim.api.nvim_get_current_tabpage() == view.tabpage) then
          following[view] = nil
          return
        end
        if not (vim.api.nvim_win_is_valid(main.id) and vim.api.nvim_win_get_buf(main.id) == event.buf) then
          following[view] = nil
          return
        end

        local position = vim.api.nvim_win_get_cursor(main.id)

        if target_file then
          view.emitter:once('file_open_post', function()
            vim.schedule(function()
              local current = view.cur_layout:get_main_win()
              set_cursor(current and current.id, position)
              following[view] = nil
            end)
          end)

          view:set_file_by_path(target_path, true, true)
          return
        end

        view.emitter:once('file_open_post', function()
          vim.schedule(function()
            following[view] = nil
            vim.cmd('tabnew ' .. vim.fn.fnameescape(target_name))
            set_cursor(vim.api.nvim_get_current_win(), position)
            vim.notify('Opened outside Diffview because this file is not part of the review', vim.log.levels.INFO)
          end)
        end)

        view:set_file(source_file, false, true)
      end)
    end,
  })
end

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
    opts = {
      default_args = {
        DiffviewOpen = { '--imply-local' },
      },
      hooks = {
        view_opened = setup_diffview_follow,
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
