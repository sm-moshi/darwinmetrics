import std/os

include "nimble.paths"
# end Nimble config

# Add chronos package path
switch("path", os.getHomeDir() & "/.local/share/mise/installs/nim/2.2.2/nimble/pkgcache/githubcom_statusimnimchronos")

# Add stew package path
switch("path", os.getHomeDir() & "/.local/share/mise/installs/nim/2.2.2/nimble/pkgs2/stew-0.2.0-26d477c735913b7daa1dab53dd74803c88209634")

# Add results package path
switch("path", os.getHomeDir() & "/.local/share/mise/installs/nim/2.2.2/nimble/pkgs2/results-0.5.1-a9c011f74bc9ed5c91103917b9f382b12e82a9e7")

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
