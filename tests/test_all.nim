## Test runner for all DarwinMetrics tests
##
## This module imports and runs all test modules in the project.

import std/unittest

# Import all test modules
import test_docsync
import test_system_cpu
import test_cpu
import tsan_test

when isMainModule:
  echo "Running all tests..."
