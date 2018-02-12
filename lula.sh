SELF_PATH=`readlink "$0"`
export LULA_PATH=`dirname $SELF_PATH`

# Shell functions
. "$LULA_PATH/util.sh"

# lula <command>
CMD=${1:-start}; shift

# lula start
start() {
  CMD=`get_prop scripts.start` || "lua"
  MAIN=`get_prop main` || "init.lua"

  ENTRY="$(mktemp).lua"
  echo "$(run_script "compile")" > "$ENTRY"

  echo ""
  printf "\e[1m$CMD $MAIN\n\e[0m"
  echo ""

  trap "rm $ENTRY" EXIT
  eval "$CMD $ENTRY"
  echo ""
  exit 0
}

# lula run
run_cmd() {
  SCRIPT=$1
  if [ -z $SCRIPT ]; then
    p "Must provide a script name"
    exit 1
  fi

  if [ $SCRIPT == "start" ]; then
    start
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
}

# lula install
install() {
  p "lula install: not yet implemented"
}

# package.lua must exist
if [ ! -f "$PWD/package.lua" ]; then
  p "Cannot find ./package.lua"
  exit 1
fi

# lua dependency paths
export LUA_PATH="?.lua;?/init.lua;lib/?.lua;lib/?/init.lua;;"
export LUA_CPATH=`echo "$LUA_PATH" | sed "s/lua;/so;/g"`

if [ $CMD == "start" ]; then start
elif [ $CMD == "run" ]; then run_cmd $@
elif [ $CMD == "install" ] || [ $CMD == "i" ]; then install
else p "Unknown command: $CMD"
fi
