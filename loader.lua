local cwd = os.getenv('PWD') .. '/'

-- Get parent directory.
local function dirname(path)
  return path:match('(.+)/.+')
end

-- Resolve a relative path.
local function resolve(dir, path)
  if path:sub(1, 2) == './' then
    if dir == '.' then return path end
    return dir .. path:sub(2)
  else
    local path, i = path:gsub('../', '')
    while i > 0 do
      if dir == nil then return end
      dir = dirname(dir)
      i = i - 1
    end
    return dir .. '/' .. path
  end
end

-- Save the original `name` for load errors.
local orig_name

-- The relative path loader.
local function relative(name)
  local ch = name:sub(1, 1)
  local path = false

  -- Use ./ or ../ to resolve relative to the caller.
  if ch == '.' then
    local caller
    local level = 3

    -- Loop past any C functions to get to the real caller.
    -- This avoids pcall(require, "path") getting "=C" as the source.
    repeat
      caller = debug.getinfo(level, 'S').source
      level = level + 1
    until caller ~= '=[C]'

    -- The caller must be inside the working directory.
    if caller:sub(1, 3) == '@./' then
      path = resolve(dirname(caller:sub(2)), name)
    else
      -- You can't use relative paths outside the working directory.
      local reason = 'illegal use of relative paths'
      print('\n  ' .. reason .. ':\n  ' .. caller .. '\n')
      error()
    end

  -- Use ~/ to resolve relative to the working directory.
  elseif ch == '~' then
    path = resolve('.', '.' .. name:sub(2))
  end

  if path ~= false then
    if path ~= nil then
      orig_name = name
      return path
    end
    error('module \'' .. name .. '\' not found', 2)
  end

  return name
end

-- Resolve relative paths before `require`.
local _require = require
_G.require = function(name)
  return _require(relative(name))
end

-- Load a relative module.
local function load_module(name)
  local path = cwd .. name:sub(3)
  local fh = io.open(path, 'rb')
  if fh then
    local code = fh:read('*all'), fh:close()
    if code then
      return loadstring(code, '@' .. name)
    end
  end
end

-- Relative modules need a dedicated loader to work as intended.
table.insert(package.loaders, 2, function(name)
  if name:sub(1, 2) == './' then
    local module = load_module(name .. '.lua')
      or load_module(name .. '/init.lua')

    if module ~= nil then
      orig_name = nil
      return module
    end
    error('module \'' .. orig_name .. '\' not found', 3)
  end
end)
