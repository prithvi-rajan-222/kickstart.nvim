-- ctrl+h/j/k/l across nvim splits and terminal-multiplexer panes.
--
-- Inside Rex (REX_SESSION is set): move between nvim windows, and at the edge
-- ask the Rex server to focus the neighbouring pane. `rex focus` works without
-- the app's Remote Control setting, which `rex do pane.focus` needs.
-- Rex's init.lua passes ctrl+h/j/k/l to nvim when nvim is in front, so both
-- halves are needed.
-- Elsewhere: fall back to vim-tmux-navigator, as before.

local directions = { h = 'left', j = 'down', k = 'up', l = 'right' }
local tmux_commands = { h = 'TmuxNavigateLeft', j = 'TmuxNavigateDown', k = 'TmuxNavigateUp', l = 'TmuxNavigateRight' }

-- Rex puts its CLI on PATH in its own terminals; Versions/Current survives updates.
local function rex_cli()
  local found = vim.fn.exepath 'rex'
  if found ~= '' then return found end
  return vim.fn.expand '~/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex'
end

local function navigate(key)
  if not vim.env.REX_SESSION then
    vim.cmd(tmux_commands[key])
    return
  end
  local win = vim.fn.winnr()
  vim.cmd('wincmd ' .. key)
  if vim.fn.winnr() == win then vim.fn.jobstart { rex_cli(), 'focus', directions[key] } end
end

---@module 'lazy'
---@type LazySpec
return {
  'christoomey/vim-tmux-navigator',
  init = function()
    vim.g.tmux_navigator_disable_when_zoomed = 1
    -- Keep the plugin's own <C-h/j/k/l> maps from replacing the keys below.
    vim.g.tmux_navigator_no_mappings = 1
  end,
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
    'TmuxNavigatorProcessList',
  },
  keys = {
    { '<c-h>', function() navigate 'h' end, desc = 'Move focus left (nvim, Rex or tmux)' },
    { '<c-j>', function() navigate 'j' end, desc = 'Move focus down (nvim, Rex or tmux)' },
    { '<c-k>', function() navigate 'k' end, desc = 'Move focus up (nvim, Rex or tmux)' },
    { '<c-l>', function() navigate 'l' end, desc = 'Move focus right (nvim, Rex or tmux)' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>', desc = 'Move focus to previous pane (tmux)' },
  },
}
