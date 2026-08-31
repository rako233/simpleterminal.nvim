-- Registers the :SimpleTerminal command. Loading this file does not create any
-- mappings and does not require the main module, so the plugin costs nothing
-- until the command is run or `setup()` is called.

if vim.g.loaded_simpleterminal then
  return
end
vim.g.loaded_simpleterminal = true

local actions = { toggle = true, open = true, close = true }

vim.api.nvim_create_user_command("SimpleTerminal", function(opts)
  local action = opts.args ~= "" and opts.args or "toggle"

  if not actions[action] then
    vim.notify(("SimpleTerminal: unknown action '%s'"):format(action), vim.log.levels.ERROR)
    return
  end

  require("simpleterminal")[action]()
end, {
  nargs = "?",
  complete = function(arg_lead)
    return vim.tbl_filter(function(action)
      return action:find(arg_lead, 1, true) == 1
    end, vim.tbl_keys(actions))
  end,
  desc = "Toggle (or open/close) the floating terminal",
})
