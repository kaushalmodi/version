# Package

version       = "0.1.0"
author        = "Kaushal Modi"
description   = "Parse the version number of most CLI apps"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["get_version"]



# Dependencies

requires "nim >= 1.3.5"
