local cfg = require('luarocks.cfg')
local make = require('luarocks.make')
local semver = require('semver')

local function ver(ver)
  return semver(cfg.program_version) >= semver(ver)
end

return {
  ver = ver,
  build_dep = (function()
    if ver('2.4') then
      return function(spec_path)
        return make.command({}, spec_path)
      end
    end
    return make.run
  end)(),
}
