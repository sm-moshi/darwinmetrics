# Package

version       = "0.0.7"
author        = "Stuart Meya"
description   = "System metrics library for macOS (Darwin) written in pure Nim — CPU, memory, disk, processes, and more."
license       = "MIT"
srcDir        = "src"

# Package Type
backend       = "c"
installExt    = @["nim"]

# Dependencies
requires "nim >= 2.2.2"
requires "chronos >= 4.0.4"
requires "stew >= 0.2.0"
requires "results >= 0.5.1"

# Optional Dependencies
when defined(threads) and defined(test):
  requires "weave >= 0.4.0"

# Modules to install
installDirs = @["doctools"]

# Binaries to build
bin = @[
  "doctools/docsync_cli=docsync"  # Documentation sync tool
]

# Tasks

task test, "Run all tests":
  # Set compilation flags
  when not defined(noThreads):
    switch("threads", "on")
  switch("tlsEmulation", "off")
  switch("gc", "orc")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("passL", "-framework Foundation")
  switch("passL", "-framework CoreServices")
  switch("passL", "-framework DiskArbitration")
  switch("passL", "-framework SystemConfiguration")
  switch("define", "test")
  switch("define", "useChronos")  # Enable chronos async backend

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
  if fileExists("tests/test_power.nim"):
    exec "nim c -r tests/test_power.nim"

task coverage, "Generate coverage reports":
  switch("threads", "on")
  switch("tlsEmulation", "off")
  switch("passL", "-framework IOKit")
  switch("passL", "-framework CoreFoundation")
  switch("debugger", "native")
  switch("define", "coverage")
  switch("define", "useChronos")  # Enable chronos async backend
  exec "nim c -r tests/test_all"

task format, "Format code using nimpretty":
  exec "nimpretty src/*.nim"
  exec "nimpretty src/doctools/*.nim"
  exec "nimpretty tests/*.nim"

task check, "Run static analysis":
  switch("define", "useChronos")  # Enable chronos async backend
  exec "nim check --hints:on --warnings:on src/darwinmetrics.nim"
  exec "nim check --hints:on --warnings:on src/doctools/sync.nim"
  exec "nim check --hints:on --warnings:on src/doctools/docsync_cli.nim"

task tsan, "Run with ThreadSanitizer":
  # Run the test with thread sanitizer enabled
  exec "CFLAGS='-fsanitize=thread' LDFLAGS='-fsanitize=thread -framework IOKit -framework CoreFoundation' nim c --threads:on --tlsEmulation:off --mm:orc --debugger:native -d:useChronos -r tests/tsan_test.nim"

task ci, "Run CI tasks":
  exec "nimble check"
  exec "nimble format"
  exec "nimble test"

task docs, "Sync documentation between docs/ and .jekyll/_docs/":
  # Ensure docsync is built
  exec "nimble build"
  # Run the build script
  exec "nim c -r build_docs.nims"
  if existsEnv("CI"):
    exec "git diff --exit-code .jekyll/_docs/"
