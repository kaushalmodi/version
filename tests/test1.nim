import std/[unittest]
import version

proc getVersionInt*(versionOutLines: openArray[string]): (int, int, int) =
  let
    v = versionOutLines.getVersion()
  return (v.major.int, v.minor.int, v.micro.int)

proc getVersionInt*(app: string): (int, int, int) =
  let
    v = app.getVersion()
  return (v.major.int, v.minor.int, v.micro.int)

suite "version strings":

  test "a.b.c":
    check:
      # [""
      #  ].getVersion() == (, , )

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
      $(["tmux next-3.2"].getVersion()) == "3.1.99"

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
      `v00.00.00` = (0, 0, 0)
      `v00.00.01` = (0, 0, 1)
      `v00.01.00` = (0, 1, 0)
      `v01.00.00` = (1, 0, 0)
      `v01.01.01` = (1, 1, 1)
      `v01.01.00` = (1, 1, 0)

      `v00.00.09` = (0, 0, 9)
      `v00.00.99` = (0, 0, 99)
      `v00.99.99` = (0, 99, 99)
      `v00.09.00` = (0, 9, 0)
      `v00.99.00` = (0, 99, 0)
      `v99.00.00` = (99, 0, 0)
      `v100.00.00` = (100, 0, 0)

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

suite "compare":

  test "==, >=, <=":
    check:
      ["0.0.0"].getVersion() == ["0.0.0"].getVersion()
      ["0.0.0"].getVersion() <= ["0.0.0"].getVersion()
      ["0.0.0"].getVersion() >= ["0.0.0"].getVersion()

      ["0.0.0"].getVersion() == (0, 0, 0)
      (0, 0, 0) == ["0.0.0"].getVersion()

  test "!=":
    check:
      ["0.0.0"].getVersion() != ["0.0.1"].getVersion()
      ["0.0.0"].getVersion() != ["0.1.0"].getVersion()
      ["0.0.0"].getVersion() != ["1.0.0"].getVersion()

      ["v1.0.0-DEV"].getVersion() != ["v1.0.0"].getVersion()

  test "<":
    check:
      ["0.0.0"].getVersion() < ["0.0.1"].getVersion()
      ["0.0.0"].getVersion() < ["0.1.0"].getVersion()
      ["0.0.0"].getVersion() < ["1.1.0"].getVersion()

      ["v0.99.0"].getVersion() < ["v1.0.0-DEV"].getVersion()
      ["v1.0.0-DEV"].getVersion() < ["v1.0.0"].getVersion()

  test ">":
    check:
      ["0.0.1"].getVersion() > ["0.0.0"].getVersion()
      ["0.1.0"].getVersion() > ["0.0.0"].getVersion()
      ["1.1.0"].getVersion() > ["0.0.0"].getVersion()

      ["v1.0.0-DEV"].getVersion() > ["v0.99.0"].getVersion()
      ["v1.0.0"].getVersion() > ["v1.0.0-DEV"].getVersion()
