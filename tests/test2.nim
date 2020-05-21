import std/[strformat]
import version

for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg", "foo"]:
  echo &"{app} : {app.getVersion()}"
