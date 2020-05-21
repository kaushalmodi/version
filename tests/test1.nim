import std/[unittest, sugar]
import version

suite "app versions":

  test "non-existent app":
    check:
      "fooBar_123_".getVersion() == versionUnset

  test "nim":
    check:
      "nim".getVersion() == (NimMajor, NimMinor, NimPatch)

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
        ].getVersion() == (1, 3, 5)

      ["gcc (GCC) 9.1.0",
       "Copyright (C) 2019 Free Software Foundation, Inc.",
       "This is free software; see the source for copying conditions.  There is NO",
       "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
        ].getVersion() == (9, 1, 0)

      ["GNU Emacs 27.0.91",
       "Copyright (C) 2020 Free Software Foundation, Inc.",
       "GNU Emacs comes with ABSOLUTELY NO WARRANTY.",
       "You may redistribute copies of GNU Emacs",
       "under the terms of the GNU General Public License.",
       "For more information about these matters, see the file named COPYING."
        ].getVersion() == (27, 0, 91)

      ["ripgrep 12.0.1 (rev a2e6aec7a4)",
       "-SIMD -AVX (compiled)",
       "+SIMD -AVX (runtime)"
        ].getVersion() == (12, 0, 1)

  test "next-a.b":
    check:
      ["tmux next-3.2"
        ].getVersion() == (3, 1, 99)
      $(["tmux next-3.2"].getVersion()) == "3.1.99"

  test "va.b.c":
    check:
      ["Hugo Static Site Generator v0.71.0-06150C87 linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
        ].getVersion() == (0, 71, 0)

  test "va.b.c-DEV":
    check:
      ["Hugo Static Site Generator v0.72.0-DEV linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
        ].getVersion() == (0, 71, 99)

suite "inc dec tests":

  test "inc":
    check:
      (0, 0, 0).dup(inc(vPatch)) == (0, 0, 1)

      (0, 0, 0).dup(inc(vMinor)) == (0, 1, 0)
      (0, 0, 1).dup(inc(vMinor)) == (0, 1, 0)

      (0, 0, 0).dup(inc(vMajor)) == (1, 0, 0)
      (0, 0, 1).dup(inc(vMajor)) == (1, 0, 0)
      (0, 1, 0).dup(inc(vMajor)) == (1, 0, 0)
      (0, 1, 1).dup(inc(vMajor)) == (1, 0, 0)
      (99, 0, 0).dup(inc(vMajor)) == (100, 0, 0)

  test "inc overflow":
    check:
      (0, 0, 99).dup(inc(vPatch)) == (0, 1, 0)
      (0, 0, 9).dup(inc(vPatch, maxVersionPatch = 9)) == (0, 1, 0)
      (0, 5, 9).dup(inc(vPatch, maxVersionMinor = 5, maxVersionPatch = 9)) == (1, 0, 0)
      (0, 99, 99).dup(inc(vPatch)) == (1, 0, 0)

      (0, 99, 0).dup(inc(vMinor)) == (1, 0, 0)
      (0, 9, 0).dup(inc(vMinor, maxVersionMinor = 9)) == (1, 0, 0)

  test "dec":
    check:
      (1, 1, 1).dup(dec(vPatch)) == (1, 1, 0)

      (1, 1, 0).dup(dec(vMinor)) == (1, 0, 0)
      (1, 1, 1).dup(dec(vMinor)) == (1, 0, 0)

      (1, 0, 0).dup(dec(vMajor)) == (0, 0, 0)
      (1, 0, 1).dup(dec(vMajor)) == (0, 0, 0)
      (1, 1, 0).dup(dec(vMajor)) == (0, 0, 0)
      (1, 1, 1).dup(dec(vMajor)) == (0, 0, 0)

  test "dec underflow":
    check:
      (0, 0, 0).dup(dec(vPatch)) == (0, 0, 0)
      (0, 0, 0).dup(dec(vMinor)) == (0, 0, 0)
      (0, 0, 0).dup(dec(vMajor)) == (0, 0, 0)

      (0, 1, 0).dup(dec(vPatch)) == (0, 0, 99)
      (0, 1, 0).dup(dec(vPatch, maxVersionPatch = 9)) == (0, 0, 9)
      (1, 0, 0).dup(dec(vPatch, maxVersionMinor = 5, maxVersionPatch = 9)) == (0, 5, 9)

      (1, 0, 0).dup(dec(vMinor)) == (0, 99, 0)
      (1, 0, 0).dup(dec(vMinor, maxVersionMinor = 9)) == (0, 9, 0)

suite "compare":

  test "==, >=, <=":
    check:
      ["5.5.5"].getVersion() == (5, 5, 5)
      ["5.5.5"].getVersion() <= (5, 5, 5)
      ["5.5.5"].getVersion() >= (5, 5, 5)

  test "!=":
    check:
      ["0.0.0"].getVersion() != (0, 0, 1)
      ["0.0.0"].getVersion() != (0, 1, 0)
      ["0.0.0"].getVersion() != (1, 0, 0)

      ["v1.0.0-DEV"].getVersion() != (1, 0, 0)

  test "<":
    check:
      ["0.0.0"].getVersion() < (0, 0, 1)
      ["0.0.0"].getVersion() < (0, 1, 0)
      ["0.0.0"].getVersion() < (1, 1, 0)

      ["v0.99.0"].getVersion() < ["v1.0.0-DEV"].getVersion()
      ["v1.0.0-DEV"].getVersion() < (1, 0, 0)

  test ">":
    check:
      ["0.0.1"].getVersion() > (0, 0, 0)
      ["0.1.0"].getVersion() > (0, 0, 0)
      ["1.1.0"].getVersion() > (0, 0, 0)

      ["v1.0.0-DEV"].getVersion() > (0, 99, 0)
      ["v1.0.0"].getVersion() > ["v1.0.0-DEV"].getVersion()
