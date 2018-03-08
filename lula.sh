#!/bin/bash

SELF_PATH=`readlink "$0"`
export LULA_PATH=`dirname $SELF_PATH`

ARGS="$*"
flag_exists() {
  echo "$ARGS" | grep "\s$1\b"
}

# Shell functions
. "$LULA_PATH/util.sh"

# lula <command>
CMD=${1:-start}; shift

# lula start
start() {
  CMD=`get_prop scripts.start lua`
  MAIN=`get_prop main init.lua`

  if [ -f ".env" ]; then
    while read name value; do
      declare -rx ${name}="$(eval "echo $value")"
    done < ".env"
  fi

  ROOT=`get_prop root`
  if [ -z "$ROOT" ]; then
    ROOT="."
  elif [[ ! "$ROOT" = ./* ]]; then
    ROOT="./$ROOT"
  fi

  # The compiler and loader need the module root.
  export LULA_ROOT="$ROOT"

  ENTRY="$ROOT/__entry__.lua"
  echo "$(run_script "compile" "$ROOT")" > "$ENTRY"
  trap "rm $ENTRY" EXIT

  echo ""
  printf "\e[1m$CMD $ROOT/$MAIN\n\e[0m"
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
    if [ ! -z "$(flag_exists -v)" ]; then
      run_script "install"
    else
      run_script "install" > /dev/null
    fi

    # Remove luarocks directories.
    rm -rf "lib/lib" "lib/share"
  fi
}

# "package.lua" must exist in the working directory
if [ -f "$PWD/package.lua" ]; then
  export PACKAGE_DIR="$PWD"
else
  p "Cannot find ./package.lua"
  exit 1
fi

export LUA_PATH="$PWD/lib/?.lua;$PWD/lib/?/init.lua;;"
export LUA_CPATH=`echo "$LUA_PATH" | sed "s/lua;/so;/g"`

if [ $CMD == "start" ]; then start
elif [ $CMD == "run" ]; then run_cmd $@
elif [ $CMD == "install" ] || [ $CMD == "i" ]; then install $@
else run_cmd $CMD $@
fi
