import std/[strformat, os, osproc, strutils, strscans]

type
  VersionSegment* = enum
    vMajor
    vMinor
    vMicro
  Version* = tuple
    major: int
    minor: int
    micro: int

const
  minVer = 0
  maxVer = 99
  versionUnset: Version = (0, 0, 0) # Assuming that a real version will never be 0.0.0
  versionSwitches = ["--version", # gcc, emacs and probably all GNU projects, nim
                     "-V", # tmux, p4
                     "version" # hugo
                     ]

proc inc*(v: Version; seg = vMicro; maxV = maxVer): Version =
  ## Increment version.
  result = v
  case seg
  of vMajor:
    inc result.major
    result.minor = minVer
    result.micro = minVer
  of vMinor:
    if result.minor == maxV:
      return v.inc(vMajor)
    else:
      inc result.minor
    result.micro = minVer
  else:
    if result.micro == maxV:
      return v.inc(vMinor)
    else:
      inc result.micro

proc dec*(v: Version; seg = vMicro; maxV = maxVer): Version =
  ## Decrement version.
  if v == versionUnset:
    return
  result = v
  case seg
  of vMajor:
    if result.major > minVer:
      dec result.major
    result.minor = minVer
    result.micro = minVer
  of vMinor:
    if result.minor > minVer:
      dec result.minor
    else:
      result = v.dec(vMajor)
      result.minor = maxV
    result.micro = minVer
  else:
    if result.micro > minVer:
      dec result.micro
    else:
      result = v.dec(vMinor)
      result.micro = maxV

proc getVersion*(versionOutLines: openArray[string]): Version =
  for ln in versionOutLines:
    for word in ln.split():
      when defined(debug):
        echo &"word = {word}"
      var
        major, minor, micro: int
        tag: string
      if scanf(word, "$i.$i.$i", major, minor, micro) or # nim, gcc, emacs
         scanf(word, "v$i.$i.$i-$w", major, minor, micro, tag) or # hugo DEV
         scanf(word, "v$i.$i.$i", major, minor, micro) or # hugo
         scanf(word, "$w-$i.$i", tag, major, minor) or # tmux
         scanf(word, "$i.$i", major, minor): # ?
        if major > 0:
          result.major = major
        if minor > 0:
          result.minor = minor
        if micro > 0:
          result.micro = micro
        case tag
        of "next", "DEV":
          # tmux : "next-3.2" -> (3, 1, 99)
          # hugo : "v0.72.0-DEV" -> (0, 71, 99)
          result = result.dec(vMicro)
        else:
          return

proc getVersion*(app: string): Version =
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
        result = outp.splitLines().getVersion()
        if result != versionUnset:
          return

proc `$`*(v: Version): string =
  &"{v.major}.{v.minor}.{v.micro}"

when isMainModule:
  import std/[os]

  for app in commandLineParams():
    echo &"{app} version = {app.getVersion()}"
