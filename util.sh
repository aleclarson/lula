
eval_package() {
  lua -e "
    package.path = '?.lua;' .. package.path
    require('$PWD/package')
    $1
  "
}

get_prop() {
  eval_package "
    ok, res = pcall(function()
      return $1 or ''
    end)
    if ok then print(res) end
  "
}

run_script() {
  eval_package "
    require('$LULA_PATH/$1')
  "
}

p() {
  echo "  $@"
}
