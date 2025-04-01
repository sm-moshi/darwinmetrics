# Package

version       = "0.0.6"
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
requires "weave >= 0.4.0"

# Modules to install
installDirs = @["doctools"]

# Binaries to build
bin = @["doctools/docsync_cli=docsync"]

# Tasks

task test, "Run all tests":
  # Set compilation flags
  switch("threads", "on")
  switch("tlsEmulation", "off")
  switch("gc", "orc")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("passL", "-framework Foundation")
  switch("passL", "-framework CoreServices")
  switch("passL", "-framework DiskArbitration")
  switch("passL", "-framework SystemConfiguration")

  # Run tests
  exec "nim c -r tests/test_all.nim"
  if fileExists("tests/test_docsync.nim"):
    exec "nim c -r tests/test_docsync.nim"
  if fileExists("tests/test_cpu.nim"):
    exec "nim c -r tests/test_cpu.nim"
  if fileExists("tests/test_system_cpu.nim"):
    exec "nim c -r tests/test_system_cpu.nim"
  if fileExists("tests/test_memory.nim"):
    exec "nim c -r tests/test_memory.nim"

task coverage, "Generate coverage reports":
  switch("threads", "on")
  switch("tlsEmulation", "off")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("debugger", "native")
  switch("define", "coverage")
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
  switch("threads", "on")
  switch("tlsEmulation", "off")
  switch("gc", "orc")
  switch("debugger", "native")
  switch("passC", "-fsanitize=thread")
  switch("passL", "-fsanitize=thread")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("path", ".")
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
