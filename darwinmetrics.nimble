# Package

version       = "0.0.5"
author        = "Stuart Meya"
description   = "System metrics library for macOS (Darwin) written in pure Nim — CPU, memory, disk, processes, and more."
license       = "MIT"
srcDir        = "src"
binDir        = "bin"

# Package Type
backend       = "c"
installExt    = @["nim"]

# Dependencies

requires "nim >= 2.2.2"

# Modules to install
installDirs = @["doctools"]

# Binaries to build
bin = @["doctools/docsync_cli=docsync"]

# Tasks

task test, "Run all tests":
  --threads:on
  --tlsEmulation:off
  --passL:"-framework IOKit"
  --passL:"-framework CoreFoundation"
  exec "nim c -r tests/test_all.nim"
  exec "nim c -r tests/test_docsync.nim"

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
  exec "nimpretty src/doctools/*.nim"
  exec "nimpretty tests/*.nim"

task check, "Run static analysis":
  exec "nim check --hints:on --warnings:on src/darwinmetrics.nim"
  exec "nim check --hints:on --warnings:on src/doctools/sync.nim"
  exec "nim check --hints:on --warnings:on src/doctools/docsync_cli.nim"

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

task docs, "Sync documentation between docs/ and .jekyll/_docs/":
  # Ensure docsync is built
  exec "nimble build"
  # Run the build script
  exec "nim c -r build_docs.nims"
  if existsEnv("CI"):
    exec "git diff --exit-code .jekyll/_docs/"
