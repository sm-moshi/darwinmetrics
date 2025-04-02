import std/os

when hostOS == "macosx":
  switch("define", "darwin")

# Common test flags
switch("threads", "on")
switch("tlsEmulation", "off")
switch("gc", "orc")
switch("passL", "-framework IOKit")
switch("passL", "-framework CoreFoundation")
switch("passL", "-framework Foundation")
switch("passL", "-framework CoreServices")
switch("passL", "-framework DiskArbitration")
switch("passL", "-framework SystemConfiguration")
switch("path", "$projectDir/src")
switch("path", "$HOME/.nimble/pkgs/chronos-*/")
