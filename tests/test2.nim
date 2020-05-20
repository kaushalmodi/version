import std/[strformat]
import get_version

for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg", "foo"]:
  echo &"{app} : {app.getVersion()}"
