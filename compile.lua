local util = require 'util'

return function(cwd)
  res = ''
  local function addRequire(path)
    res = res .. 'require("' .. path:gsub('.lua', '') .. '")\n'
  end

  -- Support for relative paths.
  res = res .. util.read_file('loader.lua') .. '\n'

  if inject then
    for _, path in ipairs(inject) do
      if path:ends('/*') then
        path = path:sub(1, #path - 2)

        local dir = path
        if path:match('^[%.~]/') then
          dir = cwd .. path:sub(3)
        end

        for child in util.read_dir(dir) do
          addRequire(path .. '/' .. child)
        end

      else
        addRequire(path)
      end
    end
  end

  addRequire(main or 'init.lua')
  print(res)
end
