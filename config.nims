import std/os

# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

when defined(macosx):
  # Ensure darwin is defined when compiling on macOS
  switch("define", "darwin")
  # Add framework linking flags
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("passL", "-framework Foundation")
  switch("passL", "-framework CoreServices")
  switch("passL", "-framework DiskArbitration")
  switch("passL", "-framework SystemConfiguration")

# Common compiler flags
switch("threads", "on")
switch("tlsEmulation", "off")
switch("gc", "orc")
