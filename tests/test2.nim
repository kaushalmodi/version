import std/[strformat, os]
import version

for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg", "tcc"]:
  if app.findExe() != "":
    echo &"{app} : {app.getVersion()}"
