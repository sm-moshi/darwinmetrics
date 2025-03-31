# Package

version       = "0.0.1"
author        = "Stuart Meya"
description   = "System metrics library for macOS (Darwin) written in pure Nim — CPU, memory, disk, processes, and more."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.2.2"

proc buildHook() =
  switch("threads", "on")
  switch("define", "useMalloc")
  switch("define", "tlsEmulation=off")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")

before "build":
    buildHook()
