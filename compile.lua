res = ""

function addRequire(path)
  res = res .. "require('" .. path .. "')\n"
end

if inject then
  for _, path in ipairs(inject) do
    addRequire(path)
  end
end

main = main or "init"
main = main:gsub(".lua", "")
addRequire(main)

print(res)
