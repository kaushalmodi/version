import std/[unittest, sugar]
import version

suite "app versions":

  test "non-existent app":
    expect OSError:
      discard "fooBar_123_".getVersion()

  test "nim":
    check:
      "nim".getVersion() == (NimMajor, NimMinor, NimPatch)

suite "version strings":

  test "dollar":
    check:
      $["1.2.3"].getVersion() == "1.2.3"

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

      ["GNU bash, version 4.1.2(1)-release (x86_64-redhat-linux-gnu)",
       "Copyright (C) 2009 Free Software Foundation, Inc.",
       "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>",
       "",
       "This is free software; you are free to change and redistribute it.",
       "There is NO WARRANTY, to the extent permitted by law."
       ].getVersion() == (4, 1, 2) # I am not planning to support a 4th segment in version tuple
                                   # So that (1) in 4.1.2(1) will be silently ignored.

  test "next-a.b":
    check:
      ["tmux next-3.2"
       ].getVersion() == (3, 1, 99)
      ["tmux next-3.2"].getVersion() == (3, 1, 99)

  test "va.b.c":
    check:
      ["Hugo Static Site Generator v0.71.0-06150C87 linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
       ].getVersion() == (0, 71, 0)

  test "va.b.c-DEV":
    check:
      ["Hugo Static Site Generator v0.72.0-DEV linux/amd64 BuildDate: 2020-05-18T16:08:02Z"
       ].getVersion() == (0, 71, 99)

  test "Cadence xrun":
    check:
      ["19.09-s008"].getVersion() == (19, 9, 8)
      ["20.04-a01"].getVersion() == (20, 4, 1)

  test "git describe --tags HEAD":
    check:
      ["v0.2.1-4-g0df556e"].getVersion() == (0, 2, 1)

  test "maxVersionMinor, maxVersionPatch":
    check:
      ["next-3.2"].getVersion(maxVersionPatch = 9) == (3, 1, 9)
      ["v0.72.0-DEV"].getVersion(maxVersionPatch = 51) == (0, 71, 51)
      ["v10.0.0-DEV"].getVersion(maxVersionMinor = 5, maxVersionPatch = 9) == (9, 5, 9)

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
