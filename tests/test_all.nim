## Test runner for all DarwinMetrics tests
##
## This module imports and runs all test modules in the project.

import std/unittest

# Import all test modules
import test_docsync
import test_system_cpu
import test_cpu
import test_memory
import test_platform_darwin
import test_polling
import test_helpers

when isMainModule:
  echo "Running all tests..."
  # Run all tests
  {.warning[UnusedImport]: off.}
  when defined(macosx):
    echo "Running on macOS..."
  else:
    echo "Tests skipped: Not running on macOS"
