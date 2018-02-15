
function string.ends(str, val)
  return val == '' or string.sub(str, -string.len(val)) == val
end

local function read_dir(dir, opts)
  local cmd = 'ls'

  local all = opts and opts.all == true
  if all then cmd = cmd .. ' -a' end

  local fh = io.popen(cmd .. ' "' .. dir .. '"')
  local paths = fh:lines()

  if all then
    -- Ignore . and .. paths
    while true do
      local path = paths()
      if path ~= '.' and path ~= '..' then break end
    end
  end

  return function()
    local path = paths()
    if path then return path end
    fh:close()
  end
end

local function read_file(path)
  local fh = io.open(path, 'rb')
  if fh then
    return fh:read('*all'), fh:close()
  end
end

local function path_exists(path)
  local fh = io.open(path, 'r')
  if fh then return fh:close() else return false end
end

local function try_path(root_dir, dir)
  local path = root_dir .. '/' .. dir
  if path_exists(path) then
    return path
  end
end

return {
  read_dir = read_dir,
  read_file = read_file,
  path_exists = path_exists,
  try_path = try_path,
}
