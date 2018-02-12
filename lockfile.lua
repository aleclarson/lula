local lockfile = {
  path = './lib/.lock',
  versions = {},
}

local function noop() end

local function read_file(path)
  local fh = io.open(path, 'r')
  if fh == nil then
    return noop
  end
  local lines = fh:lines()
  return function()
    local line = lines()
    if line then return line end
    fh:close()
  end
end

local function split_dep(dep)
  local i, res = 0, {}
  dep = dep:gsub("%s*=%s*", "=")
  for str in dep:gmatch('[^=]+') do
    i = i + 1
    res[i] = str
  end
  return res
end

function lockfile.read()
  local map = lockfile.versions
  for dep in read_file(lockfile.path) do
    dep = split_dep(dep)
    map[dep[1]] = dep[2]
  end
  return map
end

function lockfile.save()
  local lines
  for name, version in pairs(lockfile.versions) do
    local line = name .. ' = ' .. version
    if lines then
      lines = lines .. '\n' .. line
    else lines = line end
  end
  local fh = io.open(lockfile.path, 'w')
  fh:write(lines)
  fh:close()
end

function lockfile.clear()
  os.remove(lockfile.path)
  lockfile.versions = {}
end

lockfile.read()
return lockfile
