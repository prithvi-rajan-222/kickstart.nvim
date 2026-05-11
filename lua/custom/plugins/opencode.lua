---@module 'lazy'
---@type LazySpec
return {
  {
    'nickjvandyke/opencode.nvim',
    version = '*',
    dependencies = {
      {
        'folke/snacks.nvim',
        optional = true,
        opts = {
          input = {},
          picker = {
            actions = {
              opencode_send = function(...)
                return require('opencode').snacks_picker_send(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      vim.o.autoread = true

      local autoread_group = vim.api.nvim_create_augroup('custom-opencode-autoread', { clear = true })

      local function checktime()
        if vim.fn.getcmdwintype() ~= '' then return end
        vim.cmd.checktime()
      end

      vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermLeave' }, {
        group = autoread_group,
        callback = checktime,
        desc = 'Reload externally changed files',
      })

      vim.api.nvim_create_autocmd('FileChangedShellPost', {
        group = autoread_group,
        callback = function(args)
          vim.notify('Reloaded externally changed file: ' .. vim.fn.fnamemodify(args.file, ':~:.'))
        end,
        desc = 'Notify when autoread reloads a file',
      })

      local timer = vim.uv.new_timer()
      if timer then
        timer:start(1000, 1000, vim.schedule_wrap(checktime))
        vim.api.nvim_create_autocmd('VimLeavePre', {
          group = autoread_group,
          callback = function()
            if not timer:is_closing() then timer:close() end
          end,
          desc = 'Stop opencode autoread timer',
        })
      end

      vim.g.opencode_opts = {
        -- Leave empty for now; defaults are good.
      }

      vim.keymap.set({ 'n', 'x' }, '<leader>oa', function()
        require('opencode').ask('@this: ', { submit = true })
      end, { desc = 'Opencode ask' })

      vim.keymap.set({ 'n', 'x' }, '<leader>os', function()
        require('opencode').select()
      end, { desc = 'Opencode select action' })

      vim.keymap.set({ 'n', 't' }, '<leader>ot', function()
        require('opencode').toggle()
      end, { desc = 'Opencode toggle' })

      vim.keymap.set({ 'n', 'x' }, '<leader>oo', function()
        return require('opencode').operator('@this ')
      end, { desc = 'Opencode add context', expr = true })
    end,
  },
}
