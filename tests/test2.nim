import std/[strformat]
import version

for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg", "tcc"]:
  echo &"{app} : {app.getVersion()}"
