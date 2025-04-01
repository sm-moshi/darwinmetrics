## Memory management tests.
##
## Tests the memory statistics and pressure monitoring functionality.

import unittest
## import std/strformat
import ../src/internal/memory_types
import ../src/internal/mach_memory

{.emit: """/*INCLUDESECTION*/
#include <mach/mach.h>
#include <mach/task_info.h>
#include <mach/mach_init.h>
#include <sys/sysctl.h>
""".}

test "getSystemPageSize returns valid page size":
  let pageSize = getSystemPageSize()
  check pageSize > 0
  check pageSize mod 4096 == 0 # Most common page size on modern systems

test "getMemoryPressureLevel returns valid level":
  let level = getMemoryPressureLevel()
  check level in {mplNormal, mplWarning, mplCritical}

test "getTaskMemoryInfo returns valid info":
  let info = getTaskMemoryInfo()
  check info.virtualSize > 0
  check info.residentSize > 0
  check info.residentSize <= info.residentSizeMax

test "getMemoryStats returns valid stats":
  let stats = getMemoryStats()
  check stats.totalPhysical > 0
  check stats.availablePhysical > 0
  check stats.usedPhysical > 0
  check stats.pageSize > 0
  check stats.totalPhysical >= stats.availablePhysical + stats.usedPhysical
