## :Author: Kaushal Modi
## :License: MIT
##
## Introduction
## ============
## This module provides a Nim library as well as a standalone CLI utility
## to fetch and parse the version info for almost any CLI app.
##
## Source
## ======
## `Repo link <https://github.com/kaushalmodi/version>`_

import std/[strformat, os, osproc, strutils, strscans, sequtils]

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
  versionVersion* = gorge("git describe --tags HEAD")
  versionUnset*: Version = (0, 0, 0) # Assuming that a real version will never be 0.0.0
  minVer = 0
  maxVersion* = 99
  versionSwitches = ["--version", # gcc, emacs and probably all GNU projects, nim
                     "-V", # tmux, p4
                     "-v", # tcc
                     "version", # hugo
                     "-version" # Cadence xrun
                     ]

proc inc*(v: var Version; seg = vPatch; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion) =
  ## Increment version.
  ##
  ## *Patch version:*
  ## - The patch version can increment up to `maxVersionPatch`.
  ## - Once the max patch version is reached, the minor version is incremented.
  ##
  ## *Minor version:*
  ## - The minor version can increment up to `maxVersionMinor`.
  ## - Once the max minor version is reached, the major version is incremented.
  ## - The patch version is reset to 0 each time the minor version is incremented.
  ##
  ## *Major version:*
  ## - The patch and minor versions are reset to 0 each time the major version is
  ##   incremented.
  runnableExamples:
    var
      v: Version = (1, 9, 9)
    v.inc(vPatch, maxVersionMinor = 9, maxVersionPatch = 9)
    doAssert v == (2, 0, 0)
    v.inc(vPatch)
    doAssert v == (2, 0, 1)
    v.inc(vMinor)
    doAssert v == (2, 1, 0)
    v.inc(vMajor)
    doAssert v == (3, 0, 0)
  ##
  case seg
  of vMajor:
    inc v.major
    v.minor = minVer
    v.patch = minVer
  of vMinor:
    if v.minor == maxVersionMinor:
      v.inc(vMajor)
    else:
      inc v.minor
    v.patch = minVer
  else:
    if v.patch == maxVersionPatch:
      v.inc(vMinor, maxVersionMinor)
    else:
      inc v.patch

proc dec*(v: var Version; seg = vPatch; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion) =
  ## Decrement version.
  ##
  ## *Patch version:*
  ## - Once the patch version reaches 0, the minor version is decremented, and
  ##   the patch version is reset to `maxVersionPatch`.
  ##
  ## *Minor version:*
  ## - Once the minor version reaches 0, the major version is decremented, and
  ##   the minor version is reset to `maxVersionMinor`.
  ## - The patch version is reset to 0 each time the minor version is decremented.
  ##
  ## *Major version:*
  ## - The patch and minor versions are reset to 0 each time the major version is
  ##   decremented.
  ## - Once the major patch version reaches 0, it remains 0.
  runnableExamples:
    var
      v: Version = (4, 0, 0)
    v.dec(vPatch, maxVersionMinor = 5, maxVersionPatch = 9)
    doAssert v == (3, 5, 9)
    v.dec(vPatch)
    doAssert v == (3, 5, 8)
    v.dec(vMinor)
    doAssert v == (3, 4, 0)
    v.dec(vMajor)
    doAssert v == (2, 0, 0)
  ##
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
      v.minor = maxVersionMinor
    v.patch = minVer
  else:
    if v.patch > minVer:
      dec v.patch
    else:
      v.dec(vMinor, maxVersionMinor)
      v.patch = maxVersionPatch

proc getVersion*(versionOutLines: openArray[string];
                 app = "";
                 maxVersionMinor = maxVersion;
                 maxVersionPatch = maxVersion): Version =
  ## Return the version parsed from an array or sequence of strings.
  runnableExamples:
    doAssert ["Nim Compiler Version 1.3.5 [Linux: amd64]"
              ].getVersion() == (1, 3, 5)
    doAssert ["gcc (GCC) 9.1.0",
              "Copyright (C) 2019 Free Software Foundation, Inc."
              ].getVersion() == (9, 1, 0)
    doAssert @["GNU Emacs 27.0.91",
               "Copyright (C) 2020 Free Software Foundation, Inc."
               ].getVersion() == (27, 0, 91)
  ##
  # https://nim-lang.github.io/Nim/strscans#user-definable-matchers
  proc cadenceSep(input: string; start: int; seps = {'-', 'a', 's'}): int =
    # Note: The parameters and return value must match to what ``scanf`` requires
    while start+result < input.len and input[start+result] in seps: inc result

  var
    app = app.toLowerAscii()
    versionOutLinesFiltered: seq[string]

  for ln in versionOutLines:
    versionOutLinesFiltered.add(ln)

  if app != "" and versionOutLines.anyIt(it.toLowerAscii().contains(app)):
    versionOutLinesFiltered = versionOutLines.filterIt(it.toLowerAscii().contains(app))

  for ln in versionOutLinesFiltered:
    when defined(debug):
      echo &"ln = {ln}"
    for word in ln.split():
      when defined(debug):
        echo &"word = {word}"
      var
        major, minor, patch, extra: int
        tag: string
      if scanf(word, "$i.$i.$i", major, minor, patch) or # nim, gcc, emacs
         scanf(word, "v$i.$i.$i-$i-$w", major, minor, patch, extra, tag) or # git describe --tags HEAD
         scanf(word, "v$i.$i.$i-$w", major, minor, patch, tag) or # hugo DEV
         scanf(word, "v$i.$i.$i", major, minor, patch) or # hugo
         scanf(word, "(v$i.$i.$i)", major, minor, patch) or # perl
         scanf(word, "$w-$i.$i", tag, major, minor) or # tmux
         scanf(word, "$i.$i$[cadenceSep]$i", major, minor, patch) or # Cadence xrun
         scanf(word, "$i.$i", major, minor): # ?
        if major > 0:
          result.major = major
        if minor > 0:
          result.minor = minor
        if patch > 0:
          result.patch = patch
        if tag in ["next", "DEV"]:
          # tmux : "next-3.2" -> (3, 1, 99)
          # hugo : "v0.72.0-DEV" -> (0, 71, 99)
          result.dec(vPatch, maxVersionMinor, maxVersionPatch)
        return

proc getVersionTupInternal(app: string;
                           versionLines: string;
                           maxVersionMinor: int;
                           maxVersionPatch: int): VersionTup =
  let
    v = versionLines.splitLines().getVersion(app, maxVersionMinor, maxVersionPatch)
  if v != versionUnset:
    result.tup = v
    result.str = versionLines.strip() & "\n"

proc getVersionTup(app: string; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion): VersionTup =
  ## Return the version of `app` as a tuple of `Version` tuple and the app's original version string.
  when defined(debug):
    echo &"app = `{app}', findExe = {app.findExe}"
  if app == "version":
    return getVersionTupInternal(app, versionVersion, maxVersionMinor, maxVersionPatch)
  if app.findExe() == "":
    raise newException(OSError, &"`{app}' executable was not found")
  for switch in versionSwitches:
    let
      (outp, exitCode) = execCmdEx(&"{app} {switch}")
    when defined(debug):
      echo &"  {switch}: exitCode = {exitCode}, outp = {outp}"
    if exitCode == QuitSuccess:
      let
        vTup = getVersionTupInternal(app, outp, maxVersionMinor, maxVersionPatch)
      if vTup.tup != versionUnset:
        return vTup

proc getVersion*(app: string; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion): Version =
  ## Return the version parsed from the `app`'s version string.
  runnableExamples:
    doAssert "nim".getVersion() == (NimMajor, NimMinor, NimPatch)
    doAssert "version".getVersion() == [versionVersion].getVersion()
  ##
  return app.getVersionTup(maxVersionMinor, maxVersionPatch).tup

proc getVersionTupCT(app: string; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion): VersionTup =
  ## Return the version of `app` as a tuple of `Version` tuple and the app's original version string.
  ## **This is a compile time proc.**
  if app == "version":
    return getVersionTupInternal(app, versionVersion, maxVersionMinor, maxVersionPatch)
  for switch in versionSwitches:
    let
      (outp, exitCode) = gorgeEx(&"{app} {switch}")
    if exitCode == QuitSuccess:
      let
        vTup = getVersionTupInternal(app, outp, maxVersionMinor, maxVersionPatch)
      if vTup.tup != versionUnset:
        return vTup

proc getVersionCT*(app: string; maxVersionMinor = maxVersion; maxVersionPatch = maxVersion): Version =
  ## Return the version parsed from the `app`'s version string.
  ## **This is a compile time proc.**
  ##
  ## .. code-block:: nim
  ##   static:
  ##     doAssert "nim".getVersion() == (NimMajor, NimMinor, NimPatch)
  ##     doAssert "version".getVersion() == [versionVersion].getVersion()
  return app.getVersionTupCT(maxVersionMinor, maxVersionPatch).tup

proc `$`*(v: Version): string =
  ## Return the string representation of the version.
  runnableExamples:
    let
      v: Version = (1, 2, 3)
    doAssert $v == "1.2.3"
  ##
  &"{v.major}.{v.minor}.{v.patch}"

when isMainModule:
  import std/[terminal]

  const
    versionHelp = """Usage   : version <app1> <app2> ..
Example : version nim emacs"""

  if isatty(stdin): # Input from stdin
    let
      params = commandLineParams()
    if params.len == 0:
      echo versionHelp
    elif params.len == 1 and params[0] in ["--version", "-v"]:
      echo versionVersion
    else:
      # example: version nim emacs hugo
      for app in params:
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
