# Package

version       = "0.0.1"
author        = "Stuart Meya"
description   = "System metrics library for macOS (Darwin) written in pure Nim — CPU, memory, disk, processes, and more."
license       = "MIT"
srcDir        = "src"

# Package Type
backend       = "c"
installExt    = @["nim"]

# Dependencies

requires "nim >= 2.2.2"

# Tasks

task test, "Verify library can be imported":
  --threads:on
  --tlsEmulation:off
  --passL:"-framework IOKit"
  --passL:"-framework CoreFoundation"
  exec "nim c -r src/darwinmetrics.nim"

task coverage, "Generate coverage reports":
  --threads:on
  --tlsEmulation:off
  --passL:"-framework IOKit"
  --passL:"-framework CoreFoundation"
  --debugger:native
  --define:coverage
  exec "nim c -r tests/test_all"

