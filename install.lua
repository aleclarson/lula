local fs = require('luarocks.fs')
local cfg = require('luarocks.cfg')
local deps = require('luarocks.deps')
local path = require('luarocks.path')
local util = require('luarocks.util')
local compat = require('compat')

local join = require('luarocks.dir').path

local function try_path(root_dir, dir)
  local path = join(root_dir, dir)
  if fs.exists(path) then return path end
end

local function get_rockspec_dir(root_dir)
  return try_path(root_dir, 'rockspecs') or try_path(root_dir, 'rockspec')
end

return function(cwd)
  local rocks_dir = join(cwd, 'lib/.rocks')
  local function install_dep(dep)
    local dir = join(rocks_dir, dep)
    local spec_dir = get_rockspec_dir(dir) or dir

    local spec, latest
    for file in fs.dir(spec_dir) do
      if file:match('%.rockspec$') then
        local _, v = path.parse_name(file)
        if latest == nil or deps.compare_versions(v, latest) then
          spec, latest = file, v
        end
      end
    end

    if spec then
      fs.change_dir(dir)
      local ok, err = compat.build_dep(join(spec_dir, spec))
      if not ok then util.printerr(err) end
      fs.pop_dir()
    end
  end

  path.use_tree(join(cwd, 'lib'))

  for file in fs.dir(rocks_dir) do
    install_dep(file)
  end

  -- Copy pure Lua dependencies into ./lib
  local deps_dir = join(cfg.root_dir, 'share/lua', cfg.lua_version)
  if fs.is_dir(deps_dir) then
    fs.copy_contents(deps_dir, cfg.root_dir)
  end

  -- Copy compiled dependencies into ./lib
  deps_dir = join(cfg.root_dir, 'lib/lua', cfg.lua_version)
  if fs.is_dir(deps_dir) then
    fs.copy_contents(deps_dir, cfg.root_dir)
  end
end
