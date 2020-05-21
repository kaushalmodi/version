import std/[strformat]
import version

static:
  for app in ["nim", "gcc", "emacs"]:
    echo &"{app} : {app.getVersionCT()}"

  doAssert "fooBar_123_".getVersionCT() == versionUnset
  doAssert "nim".getVersionCT() == (NimMajor, NimMinor, NimPatch)
