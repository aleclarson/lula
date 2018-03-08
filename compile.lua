local fs = require('luarocks.fs')

local function read_file(path)
  local fh = io.open(path, 'rb')
  if fh then
    return fh:read('*a'), fh:close()
  end
end

function string.ends(str, val)	
  return val == '' or string.sub(str, -string.len(val)) == val
end

return function(cwd)
  res = ''
  local function addRequire(path)
    res = res .. 'require("' .. path:gsub('.lua', '') .. '")\n'
  end

  -- Relative paths use $LULA_ROOT.
  local root = os.getenv('LULA_ROOT')
  if root ~= '.' then cwd = cwd .. root:sub(3) .. '/' end

  -- Support for relative paths.
  res = res .. read_file('loader.lua') .. '\n'

  if inject then
    for _, path in ipairs(inject) do
      if path:ends('/*') then
        path = path:sub(1, #path - 2)

        local dir = path
        if path:match('^[%.~]/') then
          dir = cwd .. path:sub(3)
        end

        for child in fs.dir(dir) do
          addRequire(path .. '/' .. child)
        end

      else
        addRequire(path)
      end
    end
  end

  addRequire(main or './init')
  print(res)
end
