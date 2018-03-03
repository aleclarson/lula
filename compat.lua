local cfg = require('luarocks.cfg')
local deps = require('luarocks.deps')
local make = require('luarocks.make')

local function ver(ver)
  return deps.parse_version(cfg.program_version) >= deps.parse_version(ver)
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
