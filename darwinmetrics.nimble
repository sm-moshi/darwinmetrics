# Package

version       = "0.0.2"
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

task format, "Format code using nimpretty":
  exec "nimpretty src/*.nim"
  exec "nimpretty tests/*.nim"

task check, "Run static analysis":
  exec "nim check --hints:on --warnings:on src/darwinmetrics.nim"

task tsan, "Run with ThreadSanitizer":
  --threads:on
  --tlsEmulation:off
  --gc:orc
  --debugger:native
  --passC:"-fsanitize=thread"
  --passL:"-fsanitize=thread"
  --passL:"-framework IOKit"
  --passL:"-framework CoreFoundation"
  --path:"."
  exec "nim c -r tests/tsan_test.nim"

task ci, "Run CI tasks":
  exec "nimble check"
  exec "nimble test"
  exec "nimble format"
