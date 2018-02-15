
-- Get parent directory.
local function dirname(path)
  return path:match('(.+)/.+')
end

-- Resolve a relative path.
local function resolve(caller, path)
  local dir = dirname(caller)
  if path:sub(1, 2) == './' then
    if dir == nil then
      return path:sub(3) end
    return dir .. path:sub(2)
  else
    local path, i = path:gsub('../', '')
    while i > 0 do
      if dir == nil then return end
      dir = dirname(dir)
      i = i - 1
    end
    if dir == nil then
      return path end
    return dir .. '/' .. path
  end
end

-- The relative path loader.
local function relative(name)
  if name:sub(1, 1) == '.' then
    local level = 3

    -- Loop past any C functions to get to the real caller.
    -- This avoids pcall(require, "path") getting "=C" as the source.
    repeat
      caller = debug.getinfo(level, "S").source
      level = level + 1
    until caller ~= "=[C]"

    -- The caller must be inside the working directory.
    if caller:sub(1, 3) == '@./' then
      local path = resolve(caller:sub(4), name)
      if path then return path end
      error('module \'' .. name .. '\' not found', 2)
    end
  end
  return name
end

-- Resolve relative paths before `require`.
local _require = require
_G.require = function(name)
  return _require(relative(name))
end
