-- Reads colors out of a Ghostty theme or config file.
--
-- Only the color keys are understood; every other Ghostty setting in the file
-- is ignored, so a full `ghostty/config` can be pointed at just as well as a
-- standalone theme file.

local M = {}

---@class simpleterminal.Colors
---@field palette table<integer, string> ANSI colors 0-15, sparse.
---@field background string?
---@field foreground string?
---@field cursor string? From `cursor-color`.
---@field cursor_text string? From `cursor-text`.
---@field selection_background string?
---@field selection_foreground string?

---Ghostty accepts colors with or without a leading `#`, plus named colors.
---@param value string
---@return string
local function normalize(value)
  value = vim.trim(value)
  if value:match("^%x%x%x%x%x%x$") then
    return "#" .. value
  end
  return value
end

local keys = {
  ["background"] = "background",
  ["foreground"] = "foreground",
  ["cursor-color"] = "cursor",
  ["cursor-text"] = "cursor_text",
  ["selection-background"] = "selection_background",
  ["selection-foreground"] = "selection_foreground",
}

---Parse a Ghostty theme file.
---@param path string Path to the file. `~` is expanded.
---@return simpleterminal.Colors? colors nil when the file cannot be read.
---@return string? err
function M.parse(path)
  local expanded = vim.fn.expand(path)

  local file = io.open(expanded, "r")
  if not file then
    return nil, ("simpleterminal: cannot read %s"):format(expanded)
  end

  ---@type simpleterminal.Colors
  local colors = { palette = {} }

  for line in file:lines() do
    local trimmed = vim.trim(line)
    -- A leading `#` is a comment; inside a value it is a color prefix.
    if trimmed ~= "" and not trimmed:match("^#") then
      local key, value = trimmed:match("^([%w%-_]+)%s*=%s*(.+)$")
      if key then
        key = key:lower()
        if key == "palette" then
          local index, color = value:match("^(%d+)%s*=%s*(.+)$")
          local n = tonumber(index)
          if n and n >= 0 and n <= 15 then
            colors.palette[n] = normalize(color)
          end
        elseif keys[key] then
          colors[keys[key]] = normalize(value)
        end
      end
    end
  end

  file:close()

  return colors
end

---Parse a Ghostty theme file, reporting failures with `vim.notify`.
---@param path string
---@return simpleterminal.Colors? colors nil when the file cannot be read.
function M.load(path)
  local colors, err = M.parse(path)
  if not colors then
    vim.notify(err or "simpleterminal: failed to load theme", vim.log.levels.ERROR)
    return nil
  end
  return colors
end

return M
