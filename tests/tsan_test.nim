## ThreadSanitizer test suite
##
## This module runs tests with ThreadSanitizer enabled to detect
## potential race conditions and thread safety issues.

import std/unittest
import test_system_cpu # This already contains our thread-safety tests

when isMainModule:
  echo "Running ThreadSanitizer tests..."
