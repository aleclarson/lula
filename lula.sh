SELF_PATH=`readlink "$0"`
export LULA_PATH=`dirname $SELF_PATH`

# Shell functions
. "$LULA_PATH/util.sh"

# lula <command>
CMD=${1:-start}; shift

# lula start
start() {
  CMD=`get_prop scripts.start lua`
  MAIN=`get_prop main init.lua`

  INJECT=`eval_package "
    if inject then print('true') end
  "`
  if [ ! -z "$INJECT" ]; then
    ENTRY="$(mktemp).lua"
    echo "$(run_script "compile")" > "$ENTRY"
    trap "rm $ENTRY" EXIT
  else
    ENTRY="$MAIN"
  fi

  echo ""
  printf "\e[1m$CMD $MAIN\n\e[0m"
  echo ""

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

  if [ $SCRIPT == "start" ]; then start; fi

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
  if [ "$1" == "-f" ]; then rm -rf lib; fi
  mkdir -p "lib/.rocks"

  get_prop "dependencies" | while read DEP; do

    # Extract a trailing git tag.
    GIT_TAG="${DEP##*#}"
    if [ "$DEP" == "$GIT_TAG" ]; then
      GIT_TAG=""
    else
      DEP="${DEP%#*}"
    fi

    if [ "${DEP##*.}" == "git" ]; then
      GIT_URL="$DEP"
      DEP_NAME=`basename "$DEP" | cut -f 1 -d "."`
    elif [[ "$DEP" = *"://"* ]]; then
      p ""
      p "Package URL must end with .git"
      p "  $DEP"
      p ""
      exit 1
    else
      DEP_NAME="$DEP"
      GIT_URL=""
    fi

    ROCK_PATH="lib/.rocks/$DEP_NAME"
    if [ -e "$ROCK_PATH" ]; then
      p "* $DEP"
      continue
    fi

    # Fetch the rockspec if GIT_URL not provided.
    if [ -z "$GIT_URL" ]; then
      get_rockspec "$DEP_NAME"
      GIT_URL="$(eval_rockspec "$DEP_NAME" source.url)"
      GIT_TAG="$(eval_rockspec "$DEP_NAME" source.tag)"
    fi

    if [ -z "$GIT_TAG" ]; then
      p "+ $GIT_URL"
    else
      p "+ $GIT_URL#$GIT_TAG"
    fi

    git clone "$GIT_URL" "$ROCK_PATH" -b "${GIT_TAG:-master}" --depth 1 &> /dev/null
    rm -rf "$ROCK_PATH/.git"
  done

  if [ $? == 0 ]; then
    run_script "install" &> /dev/null

    # Remove luarocks directories.
    rm -rf "lib/lib" "lib/share"
  fi
}

# package.lua must exist
if [ ! -f "$PWD/package.lua" ]; then
  p "Cannot find ./package.lua"
  exit 1
fi

# lua dependency paths
export LUA_PATH="lib/?.lua;lib/?/init.lua;;"
export LUA_CPATH=`echo "$LUA_PATH" | sed "s/lua;/so;/g"`

if [ $CMD == "start" ]; then start
elif [ $CMD == "run" ]; then run_cmd $@
elif [ $CMD == "install" ] || [ $CMD == "i" ]; then install $@
else run_cmd $CMD $@
fi
