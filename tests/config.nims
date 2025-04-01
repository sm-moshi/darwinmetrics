import std/os

when hostOS == "macosx":
  switch("define", "darwin")

# Common test flags
switch("threads", "on")
switch("tlsEmulation", "off")
switch("gc", "orc")
