import std/[strformat]
import version

static:
  for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg", "tcc"]:
    echo &"{app} : {app.getVersionCT()}"

  doAssert "fooBar_123_".getVersionCT() == versionUnset
  doAssert "nim".getVersionCT() == (NimMajor, NimMinor, NimPatch)
