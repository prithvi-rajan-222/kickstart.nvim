-- ctrl+h/j/k/l across nvim splits and terminal-multiplexer panes.
--
-- Inside Rex (REX_SESSION is set): move between nvim windows, and at the edge
-- ask Rex to focus the neighbouring pane. Rex's init.lua passes ctrl+h/j/k/l to
-- nvim when nvim is in front, so both halves are needed.
-- Elsewhere: fall back to vim-tmux-navigator, as before.
local M = {}

local directions = { h = 'left', j = 'down', k = 'up', l = 'right' }
local tmux_commands = { h = 'TmuxNavigateLeft', j = 'TmuxNavigateDown', k = 'TmuxNavigateUp', l = 'TmuxNavigateRight' }

-- Rex puts its CLI on PATH in its own terminals; Versions/Current survives updates.
local function rex_cli()
  local found = vim.fn.exepath 'rex'
  if found ~= '' then return found end
  return vim.fn.expand '~/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex'
end

function M.navigate(key)
  if not vim.env.REX_SESSION then
    vim.cmd(tmux_commands[key])
    return
  end
  local win = vim.fn.winnr()
  vim.cmd('wincmd ' .. key)
  if vim.fn.winnr() == win then vim.fn.jobstart { rex_cli(), 'do', 'pane.focus', 'direction=' .. directions[key] } end
end

return M
