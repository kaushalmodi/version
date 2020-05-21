import std/[strformat, os, osproc, strutils, strscans]

type
  VersionSegment* = enum
    vMajor
    vMinor
    vPatch
  Version* = tuple
    major: int
    minor: int
    patch: int
  VersionTup* = tuple
    tup: Version
    str: string

const
  versionUnset*: Version = (0, 0, 0) # Assuming that a real version will never be 0.0.0
  minVer = 0
  maxVer = 99
  versionSwitches = ["--version", # gcc, emacs and probably all GNU projects, nim
                     "-V", # tmux, p4
                     "version" # hugo
                     ]

proc inc*(v: var Version; seg = vPatch; maxV = maxVer) =
  ## Increment version.
  case seg
  of vMajor:
    inc v.major
    v.minor = minVer
    v.patch = minVer
  of vMinor:
    if v.minor == maxV:
      v.inc(vMajor)
    else:
      inc v.minor
    v.patch = minVer
  else:
    if v.patch == maxV:
      v.inc(vMinor)
    else:
      inc v.patch

proc dec*(v: var Version; seg = vPatch; maxV = maxVer) =
  ## Decrement version.
  if v == versionUnset:
    return
  case seg
  of vMajor:
    if v.major > minVer:
      dec v.major
    v.minor = minVer
    v.patch = minVer
  of vMinor:
    if v.minor > minVer:
      dec v.minor
    else:
      v.dec(vMajor)
      v.minor = maxV
    v.patch = minVer
  else:
    if v.patch > minVer:
      dec v.patch
    else:
      v.dec(vMinor)
      v.patch = maxV

proc getVersion*(versionOutLines: openArray[string]): Version =
  for ln in versionOutLines:
    for word in ln.split():
      when defined(debug):
        echo &"word = {word}"
      var
        major, minor, patch: int
        tag: string
      if scanf(word, "$i.$i.$i", major, minor, patch) or # nim, gcc, emacs
         scanf(word, "v$i.$i.$i-$w", major, minor, patch, tag) or # hugo DEV
         scanf(word, "v$i.$i.$i", major, minor, patch) or # hugo
         scanf(word, "$w-$i.$i", tag, major, minor) or # tmux
         scanf(word, "$i.$i", major, minor): # ?
        if major > 0:
          result.major = major
        if minor > 0:
          result.minor = minor
        if patch > 0:
          result.patch = patch
        case tag
        of "next", "DEV":
          # tmux : "next-3.2" -> (3, 1, 99)
          # hugo : "v0.72.0-DEV" -> (0, 71, 99)
          result.dec(vPatch)
        else:
          discard

proc getVersionTup*(app: string): VersionTup =
  ## Return the current version of `app` as a tuple.
  when defined(debug):
    echo app
  if app.findExe() != "":
    for switch in versionSwitches:
      let
        (outp, exitCode) = execCmdEx(&"{app} {switch}")
      # echo &"  {switch}: exitCode = {exitCode}, outp = {outp}"
      if exitCode == QuitSuccess:
        when defined(debug):
          echo &"  {switch}: {outp}"
        let
          v = outp.splitLines().getVersion()
        if v != versionUnset:
          result.tup = v
          result.str = outp
          return

proc getVersion*(app: string): Version =
  return app.getVersionTup().tup

proc `$`*(v: Version): string =
  &"{v.major}.{v.minor}.{v.patch}"

when isMainModule:
  import std/[terminal]

  if isatty(stdin): # Input from stdin
    # example: version nim emacs hugo
    for app in commandLineParams():
      echo &"{app} version: {app.getVersionTup().tup}"
      echo app.getVersionTup().str.indent(2)
  else: # Input from a pipe
    let
      pipeData = readAll(stdin).strip().splitLines()
    # example: echo "nim emacs hugo" | version .. just because
    for ln in pipeData:
      for app in ln.split():
        echo &"{app} version: {app.getVersionTup().tup}"
        echo app.getVersionTup().str.indent(2)
