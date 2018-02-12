# lula

Try it:
```sh
git clone https://github.com/aleclarson/lula.git --depth 1
ln -s $PWD/lula/lula.sh ~/bin/lula
```

**NOTE:** This is highly experimental. Only use this for top-level application packages. Things may be broken!

Currently, this tool uses `luarocks` extensively. Please have it installed.

### package.lua

You must create a `package.lua` file in the root directory of your project.
In it, you will declare a global variable for each configuration option you want to use.

Here are the configuration options:
- `main: string` Used as the 2nd argument when you run `lula` or `lula start`
- `scripts: {}` Contains named shell scripts that you run with `lula run <name>`
- `inject: {}` An array of module paths to require before your "main" path
- `dependencies: {}` An array of git urls to shallow clone into the ./lib directory

The `main` option defaults to `init.lua`.

The `scripts.start` option defaults to `lua`.

### Usage

```sh
# Run the "start" script
lula
lula start

# Run any other script you wish
lula run <name>

# Install "dependencies" into the ./lib directory
lula install
lula i
```

### Roadmap

- Support `lua_version` property
- Support version locking for a dependency
- Support adding a dependency via `lula install <git-url>`
- Support adding a dependency by its luarocks name (by resolving it to a url)
- Support passing extra arguments to `lula start` and `lula run`
- Let `scripts` contain pairs where the value is an array of commands

### Example package.lua

```lua
main = "init.lua"
inject = {
  "moonscript",
}
dependencies = {
  "https://github.com/tarantool/queue.git",
}
scripts = {
  start = "tarantool",
  clean = "rm data/backup/* &> /dev/null",
}
```
