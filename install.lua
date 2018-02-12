local fs = require('luarocks.fs')
local cfg = require('luarocks.cfg')
local make = require('luarocks.make')
local path = require('luarocks.path')
local semver = require('semver')

local LUA_VERSION = _VERSION:gsub("Lua (%d%.+)", "%1")

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

local function get_rockspec_dir(root_dir)
  return try_path(root_dir, 'rockspecs') or try_path(root_dir, 'rockspec')
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

return function(cwd)
  local rocks_dir = cwd .. '/lib/.rocks/'
  local function install_dep(dep)
    local dir = rocks_dir .. dep

    local spec_dir = get_rockspec_dir(dir)
    if spec_dir == nil then return end

    local spec, latest_version
    for file in read_dir(spec_dir) do
      local _, v = path.parse_name(file)
      local ok, version = pcall(semver, v)
      if ok then
        is_latest = latest_version == nil or version > latest_version
        if is_latest then spec, latest_version = file, version end
      end
    end

    fs.change_dir(dir)
    cfg.root_dir = cwd .. '/lib'
    cfg.rocks_dir = cwd .. cfg.rocks_subdir
    make.command({}, spec_dir .. '/' .. spec)

    local deps_dir = cfg.root_dir .. '/share/lua/' .. LUA_VERSION
    fs.copy_contents(deps_dir, cfg.root_dir)
    fs.pop_dir()
  end

  for file in read_dir(rocks_dir) do
    install_dep(file)
  end
end
