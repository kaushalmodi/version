# Package

version       = "0.1.0"
author        = "Kaushal Modi"
description   = "Fetch/parse the version of most CLI apps"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["version"]

# Dependencies

requires "nim >= 1.3.5"
