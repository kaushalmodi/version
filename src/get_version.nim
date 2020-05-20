import std/[strformat, osproc, strutils, strscans]

type
  VersionSegment = enum
    vMajor
    vMinor
    vMicro
  Version = tuple
    major: Natural
    minor: Natural
    micro: Natural

const
  minVer = 0.Natural
  maxVer = 99
  versionUnset: Version = (0.Natural, 0.Natural, 0.Natural) # Assuming that a real version will never be 0.0.0
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
    if result.minor == maxV.Natural:
      return v.inc(vMajor)
    else:
      inc result.minor
    result.micro = minVer
  else:
    if result.micro == maxV.Natural:
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
      result.minor = maxV.Natural
    result.micro = minVer
  else:
    if result.micro > minVer:
      dec result.micro
    else:
      result = v.dec(vMinor)
      result.micro = maxV.Natural

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

proc getVersionInt*(versionOutLines: openArray[string]): (int, int, int) =
  let
    v = versionOutLines.getVersion()
  return (v.major.int, v.minor.int, v.micro.int)

proc getVersionInt*(app: string): (int, int, int) =
  let
    v = app.getVersion()
  return (v.major.int, v.minor.int, v.micro.int)

when isMainModule:
  import std/[unittest]

  for app in ["nim", "gcc", "emacs", "tmux", "hugo", "rg"]:
    echo &"{app} : {app.getVersion()}"

  suite "version strings":

    test "a.b.c":
      check:
        # [""
        #  ].getVersion() == (.Natural, .Natural, .Natural)

        ["Nim Compiler Version 1.3.5 [Linux: amd64]",
         "Compiled at 2020-05-19",
         "Copyright (c) 2006-2020 by Andreas Rumpf",
         "",
         "git hash: e909486e5cde5a4a77cd6f21b42fc9ab38ec2ae6",
         "active boot switches: -d:release"
         ].getVersionInt() == (1, 3, 5)

        ["gcc (GCC) 9.1.0",
         "Copyright (C) 2019 Free Software Foundation, Inc.",
         "This is free software; see the source for copying conditions.  There is NO",
         "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
         ].getVersionInt() == (9, 1, 0)

        ["GNU Emacs 27.0.91",
         "Copyright (C) 2020 Free Software Foundation, Inc.",
         "GNU Emacs comes with ABSOLUTELY NO WARRANTY.",
         "You may redistribute copies of GNU Emacs",
         "under the terms of the GNU General Public License.",
         "For more information about these matters, see the file named COPYING."
         ].getVersionInt() == (27, 0, 91)

        ["ripgrep 12.0.1 (rev a2e6aec7a4)",
         "-SIMD -AVX (compiled)",
         "+SIMD -AVX (runtime)"
         ].getVersionInt() == (12, 0, 1)

    test "next-a.b":
      check:
        ["tmux next-3.2"
         ].getVersionInt() == (3, 1, 99)

    test "va.b.c":
      check:
        ["Hugo Static Site Generator v0.71.0-06150C87 linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
         ].getVersionInt() == (0, 71, 0)

    test "va.b.c-DEV":
      check:
        ["Hugo Static Site Generator v0.72.0-DEV linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
         ].getVersionInt() == (0, 71, 99)

  suite "inc dec tests":
    setup:
      const
        `v00.00.00` = (0.Natural, 0.Natural, 0.Natural)
        `v00.00.01` = (0.Natural, 0.Natural, 1.Natural)
        `v00.01.00` = (0.Natural, 1.Natural, 0.Natural)
        `v01.00.00` = (1.Natural, 0.Natural, 0.Natural)
        `v01.01.01` = (1.Natural, 1.Natural, 1.Natural)
        `v01.01.00` = (1.Natural, 1.Natural, 0.Natural)

        `v00.00.09` = (0.Natural, 0.Natural, 9.Natural)
        `v00.00.99` = (0.Natural, 0.Natural, 99.Natural)
        `v00.99.99` = (0.Natural, 99.Natural, 99.Natural)
        `v00.09.00` = (0.Natural, 9.Natural, 0.Natural)
        `v00.99.00` = (0.Natural, 99.Natural, 0.Natural)
        `v99.00.00` = (99.Natural, 0.Natural, 0.Natural)
        `v100.00.00` = (100.Natural, 0.Natural, 0.Natural)

    test "inc":
      check:
        `v00.00.00`.inc(vMicro) == `v00.00.01`

        `v00.00.00`.inc(vMinor) == `v00.01.00`

        `v00.00.00`.inc(vMajor) == `v01.00.00`
        `v99.00.00`.inc(vMajor) == `v100.00.00`

    test "inc overflow":
      check:
        `v00.00.99`.inc(vMicro) == `v00.01.00`
        `v00.00.09`.inc(vMicro, 9) == `v00.01.00`
        `v00.99.99`.inc(vMicro) == `v01.00.00`

        `v00.99.00`.inc(vMinor) == `v01.00.00`
        `v00.09.00`.inc(vMinor, 9) == `v01.00.00`

    test "dec":
      check:
        `v01.01.01`.dec(vMicro) == `v01.01.00`

        `v01.01.00`.dec(vMinor) == `v01.00.00`
        `v01.01.01`.dec(vMinor) == `v01.00.00`

        `v01.00.00`.dec(vMajor) == `v00.00.00`
        `v01.01.01`.dec(vMajor) == `v00.00.00`

    test "dec underflow":
      check:
        `v00.00.00`.dec(vMicro) == `v00.00.00`
        `v00.01.00`.dec(vMicro) == `v00.00.99`
        `v00.01.00`.dec(vMicro, 9) == `v00.00.09`

        `v00.00.00`.dec(vMinor) == `v00.00.00`
        `v01.00.00`.dec(vMinor) == `v00.99.00`
        `v01.00.00`.dec(vMinor, 9) == `v00.09.00`

        `v00.00.00`.dec(vMajor) == `v00.00.00`
