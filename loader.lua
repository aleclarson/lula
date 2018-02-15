local cwd = os.getenv('PWD') .. '/'

-- Get parent directory.
local function dirname(path)
  return path:match('(.+)/.+')
end

-- Resolve a relative path.
local function resolve(caller, path)
  if path:sub(1, 2) == './' then
    return dirname(caller) .. path:sub(2)
  else
    local path, x = path:gsub('../', '')
    while x >= 0 do
      caller = dirname(caller)
      if caller == nil then
        return nil
      end
      x = x - 1
    end
    return caller .. '/' .. path
  end
end

-- Read an entire file.
local function read_file(path)
  local fh = io.open(path, 'rb')
  if fh then
    return fh:read('*all'), fh:close()
  end
end

-- The relative path loader.
table.insert(package.loaders, 3, function(path)
  if path:sub(1, 1) == '.' then
    local level = 3
    local caller

    -- Loop past any C functions to get to the real caller.
    -- This avoids pcall(require, "path") getting "=C" as the source.
    repeat
      caller = debug.getinfo(level, "S").source
      level = level + 1
    until caller ~= "=[C]"

    -- The caller usually has a leading @ for whatever reason.
    if caller:sub(1, 1) == '@' then
      caller = caller:sub(2)
    end

    -- The caller must be an absolute path.
    if caller:sub(1, 1) == '.' then
      caller = cwd .. caller:sub(3)
    end

    local file = resolve(caller, path .. '.lua')
    if file then
      local code = read_file(file)
      if code then

        -- Files relative to `cwd` are shortened.
        if file:sub(1, #cwd) == cwd then
          file = '.' .. file:sub(#cwd)
        end

        return loadstring(code, '@' .. file)
      end
    end

    error('module \'' .. path .. '\' not found', 3)
  end
end)
