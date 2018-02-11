CMD=${1:-start}; shift

get_prop() {
  SCRIPT="
    package.path = '?.lua;' .. package.path
    require('$PWD/package')
    ok, res = pcall(function()
      return $1 or ''
    end)
    if ok then print(res) end"

  lua -e "$SCRIPT"
}

p() {
  echo "  $@"
}

if [ ! -f "$PWD/package.lua" ]; then
  p "Cannot find ./package.lua"
  exit 1
fi

if [ $CMD == "install" ] || [ $CMD == "i" ]; then
  p "lula install: not yet implemented"

elif [ $CMD == "start" ]; then
  CMD="$(get_prop scripts.start)"
  CMD=${CMD:-lua}

  MAIN=`get_prop main`
  MAIN=${MAIN:-init.lua}

  echo ""
  printf "\e[1m$CMD $MAIN\n\e[0m"
  echo ""

  eval "$CMD $MAIN"

elif [ $CMD == "run" ]; then
  SCRIPT=$1
  if [ -z $SCRIPT ]; then
    p "Must provide a script name"
    exit 1
  fi

  CMD=`get_prop scripts.$SCRIPT`
  if [ -z "$CMD" ]; then
    p "Unknown script: $SCRIPT"
    exit 1
  fi

  echo ""
  printf "\e[1m$CMD\n\e[0m"
  echo ""

  eval "$CMD"

else
  p "Unknown command: $CMD"
fi
