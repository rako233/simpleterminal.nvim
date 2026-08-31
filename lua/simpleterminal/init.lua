-- simpleterminal.nvim
-- A single floating terminal you can toggle in and out of view.
--
-- The terminal buffer and its shell process are created once and reused, so
-- toggling the window away and back drops you into the same session.

local M = {}

---@class simpleterminal.Config
---@field width number Fraction of the screen when <= 1, absolute columns when > 1.
---@field height number Fraction of the screen when <= 1, absolute rows when > 1.
---@field border string|string[] Any value accepted by `nvim_open_win()`. See `:help nvim_open_win()`.
---@field title string? Window title. Requires a border other than "none".
---@field cmd string? Command to run. Defaults to 'shell'.
---@field start_insert boolean Enter terminal-mode when the window opens.
---@field close_on_exit boolean Close the window when the job exits, so the next open starts fresh.
---@field keymap string|false Normal-mode mapping for `toggle()`, created by `setup()`.

---@type simpleterminal.Config
local defaults = {
  width = 0.8,
  height = 0.8,
  border = "rounded",
  title = nil,
  cmd = nil,
  start_insert = true,
  close_on_exit = true,
  keymap = false,
}

---@type simpleterminal.Config
M.config = vim.deepcopy(defaults)

-- The one terminal buffer and its window. -1 means "not created yet".
local state = {
  buf = -1,
  win = -1,
}

local augroup = vim.api.nvim_create_augroup("simpleterminal", { clear = true })

---Turn a fraction-or-absolute size into a concrete, on-screen number of cells.
---@param value number
---@param total integer
---@return integer
local function resolve_size(value, total)
  local size = value <= 1 and math.floor(total * value) or math.floor(value)
  return math.max(1, math.min(size, total))
end

---@return boolean
local function win_is_open()
  return state.win ~= -1 and vim.api.nvim_win_is_valid(state.win)
end

---@return boolean
local function buf_is_valid()
  return state.buf ~= -1 and vim.api.nvim_buf_is_valid(state.buf)
end

---A centered window configuration for the current screen size.
---@return vim.api.keyset.win_config
local function win_config()
  -- Derived from options rather than `nvim_list_uis()` so this also works when
  -- no UI is attached (headless) and so it respects 'cmdheight'.
  local columns = vim.o.columns
  local lines = vim.o.lines - vim.o.cmdheight

  local width = resolve_size(M.config.width, columns)
  local height = resolve_size(M.config.height, lines)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((lines - height) / 2),
    col = math.floor((columns - width) / 2),
    style = "minimal",
    border = M.config.border,
    title = M.config.title,
  }
end

---Start the shell in the current window and adopt the resulting buffer.
local function start_terminal()
  if M.config.cmd then
    vim.cmd.terminal(M.config.cmd)
  else
    vim.cmd.terminal()
  end

  -- `:terminal` converts our empty scratch buffer in place rather than opening
  -- a new one, but adopt whatever we end up in so `state.buf` cannot go stale.
  state.buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    buffer = state.buf,
    desc = "Tear down the simpleterminal buffer when its job exits",
    callback = function()
      if not M.config.close_on_exit then
        return
      end
      -- Deferred: the buffer cannot be deleted from inside its own TermClose.
      vim.schedule(function()
        M.close()
        if buf_is_valid() then
          vim.api.nvim_buf_delete(state.buf, { force = true })
        end
        state.buf = -1
      end)
    end,
  })
end

---Open the floating terminal, or focus it if it is already open.
---@return integer win The window handle.
function M.open()
  if win_is_open() then
    vim.api.nvim_set_current_win(state.win)
  else
    if not buf_is_valid() then
      state.buf = vim.api.nvim_create_buf(false, true)
    end
    state.win = vim.api.nvim_open_win(state.buf, true, win_config())
  end

  if vim.bo[state.buf].buftype ~= "terminal" then
    start_terminal()
  end

  if M.config.start_insert then
    vim.cmd.startinsert()
  end

  return state.win
end

---Hide the floating terminal. The shell keeps running.
function M.close()
  if win_is_open() then
    vim.api.nvim_win_hide(state.win)
  end
  state.win = -1
end

---Open the floating terminal if it is hidden, hide it if it is visible.
function M.toggle()
  if win_is_open() then
    M.close()
  else
    M.open()
  end
end

---@return boolean
function M.is_open()
  return win_is_open()
end

---@param opts simpleterminal.Config? Options merged over the defaults.
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if type(M.config.keymap) == "string" then
    vim.keymap.set("n", M.config.keymap, M.toggle, { desc = "Toggle floating terminal" })
  end
end

-- Keep the window centered and proportional when the editor is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  desc = "Re-center the simpleterminal window",
  callback = function()
    if win_is_open() then
      vim.api.nvim_win_set_config(state.win, win_config())
    end
  end,
})

return M
