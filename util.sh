
eval_package() {
  lua -e "
    package.path = '?.lua;' .. package.path
    require('$PACKAGE_DIR/package')
    $1
  "
}

get_prop() {
  eval_package "
    pcall(function()
      local val = $1 or '$2'
      if type(val) == 'table' then
        for _, val in pairs(val) do
          if val then print(val) end
        end
      elseif val then
        print(val)
      end
    end)
  "
}

run_script() {
  ROOT="$PWD"
  cd "$LULA_PATH"
  eval_package "
    local fn = require('$1')
    if type(fn) == 'function' then fn('$ROOT/') end
  "
  cd "$ROOT"
}

search_rocks() {
  lua -e "
    search = require('luarocks.search')
    query = search.make_query('$1')
    query.arch = '${2:-src}'
    print(search.find_suitable_rock(query) or '')
  "
} 2> /dev/null

get_rockspec() {
  URL="$(search_rocks "$1" rockspec)"
  echo "$(curl $URL -sS)" > "lib/.rocks/$1.rockspec"
}

eval_rockspec() {
  lua -e "
    $(cat lib/.rocks/$1.rockspec)
    print($2 or '')
  "
}

p() {
  echo "  $@"
}
