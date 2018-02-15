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
      if string.ends(path, '/*') then
        path = string.sub(path, 1, string.len(path) - 2)
        for child in util.read_dir(cwd .. '/' .. path) do
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
