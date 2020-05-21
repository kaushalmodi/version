import std/[unittest]
import version

suite "issues":

  test "10": # https://github.com/kaushalmodi/version/issues/10
    check:
      ["Python 2.7.13 (4a68d8d3d2fc1faec2e83bcb4d28559099092574, Nov 10 2019, 19:37:56)",
       "[PyPy 7.2.0 with GCC 8.3.0]"
       ].getVersion() == (2, 7, 13)
