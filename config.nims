import std/os

include "nimble.paths"
# end Nimble config

when defined(macosx):
  # Link required frameworks
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
switch("define", "useChronos")  # Enable chronos async backend
