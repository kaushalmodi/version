import std/[unittest]
import version

suite "issues":

  test "10": # https://github.com/kaushalmodi/version/issues/10
    check:
      ["Python 2.7.13 (4a68d8d3d2fc1faec2e83bcb4d28559099092574, Nov 10 2019, 19:37:56)",
       "[PyPy 7.2.0 with GCC 8.3.0]"
       ].getVersion() == (2, 7, 13)

      ["Python 2.7.13 (4a68d8d3d2fc1faec2e83bcb4d28559099092574, Nov 10 2019, 19:37:56)",
       "[PyPy 7.2.0 with GCC 8.3.0]"
       ].getVersion(app = "python") == (2, 7, 13)
      ["Python 2.7.13 (4a68d8d3d2fc1faec2e83bcb4d28559099092574, Nov 10 2019, 19:37:56)",
       "[PyPy 7.2.0 with GCC 8.3.0]"
       ].getVersion(app = "pypy") == (7, 2, 0)

      # We are still limited if there happen to be more than 1 version
      # strings on the same line. It's difficult to robustly identify
      # that string is associated with which version string. So while below should return (8, 3, 0),
      # it does not.
      ["Python 2.7.13 (4a68d8d3d2fc1faec2e83bcb4d28559099092574, Nov 10 2019, 19:37:56)",
       "[PyPy 7.2.0 with GCC 8.3.0]"
       ].getVersion(app = "gcc") == (7, 2, 0) # (8, 3, 0)
