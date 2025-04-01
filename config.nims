import std/os

# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

when defined(macosx):
  # Ensure darwin is defined when compiling on macOS
  switch("define", "darwin")

# Common compiler flags
switch("threads", "on")
switch("tlsEmulation", "off")
switch("gc", "orc")
