local fs = require('luarocks.fs')
local cfg = require('luarocks.cfg')
local path = require('luarocks.path')
local util = require('util')
local semver = require('semver')
local compat = require('compat')

local function get_rockspec_dir(root_dir)
  return util.try_path(root_dir, 'rockspecs') or util.try_path(root_dir, 'rockspec')
end

return function(cwd)
  local rocks_dir = cwd .. '/lib/.rocks/'
  local function install_dep(dep)
    local dir = rocks_dir .. dep
    local spec_dir = get_rockspec_dir(dir) or dir

    local spec, latest_version
    for file in util.read_dir(spec_dir) do
      if file:match('%.rockspec$') then
        local _, v = path.parse_name(file)
        local ok, version = pcall(semver, v)
        if ok then
          is_latest = latest_version == nil or version > latest_version
          if is_latest then spec, latest_version = file, version end
        end
      end
    end

    if spec then
      fs.change_dir(dir)
      compat.build_dep(spec_dir .. '/' .. spec)
      fs.pop_dir()
    end
  end

  cfg.root_dir = cwd .. '/lib'
  cfg.rocks_dir = cwd .. cfg.rocks_subdir

  for file in util.read_dir(rocks_dir) do
    install_dep(file)
  end

  -- Copy pure Lua dependencies into ./lib
  local deps_dir = cfg.root_dir .. '/share/lua/' .. cfg.lua_version
  if util.path_exists(deps_dir) then
    fs.copy_contents(deps_dir, cfg.root_dir)
  end

  -- Copy compiled dependencies into ./lib
  deps_dir = cfg.root_dir .. '/lib/lua/' .. cfg.lua_version
  if util.path_exists(deps_dir) then
    fs.copy_contents(deps_dir, cfg.root_dir)
  end
end
