## Memory management tests.
##
## Tests the memory statistics and pressure monitoring functionality.

import unittest
## import std/strformat
import ../src/system/memory

{.emit: """/*INCLUDESECTION*/
#include <mach/mach.h>
#include <mach/task_info.h>
#include <mach/mach_init.h>
#include <sys/sysctl.h>
""".}

test "getMemoryStats returns valid stats":
  let stats = getMemoryStats()
  check stats.totalPhysical > 0
  check stats.availablePhysical > 0
  check stats.usedPhysical > 0
  check stats.pageSize > 0
  check stats.totalPhysical >= stats.availablePhysical + stats.usedPhysical

test "getProcessMemoryInfo returns valid info":
  let info = getProcessMemoryInfo()
  check info.virtualSize > 0
  check info.residentSize > 0
  check info.residentPeak >= info.residentSize

test "getMemoryPressureLevel returns valid level":
  let level = getMemoryPressureLevel()
  check level in {Normal, Warning, Critical, Error}

suite "Memory API Tests":
  test "getMemoryStats returns valid stats":
    let stats = getMemoryStats()
    check:
      stats.totalPhysical > 0'u64
      stats.availablePhysical > 0'u64
      stats.usedPhysical > 0'u64
      stats.pageSize > 0'u32
      stats.pagesFree >= 0'u64
      stats.pagesActive >= 0'u64
      stats.pagesInactive >= 0'u64
      stats.pagesWired >= 0'u64
      stats.pagesCompressed >= 0'u64
      stats.totalPhysical >= stats.usedPhysical
      stats.totalPhysical >= stats.availablePhysical

  test "getProcessMemoryInfo returns valid info":
    let info = getProcessMemoryInfo()
    check:
      info.virtualSize > 0'u64
      info.residentSize > 0'u64
      info.residentPeak >= info.residentSize
      info.virtualSize >= info.residentSize

  test "getMemoryPressureLevel returns valid level":
    let level = getMemoryPressureLevel()
    check:
      level in {Normal, Warning, Critical, Error}

  test "Memory size constants are correct":
    check:
      KB == 1024'u64
      MB == KB * 1024'u64
      GB == MB * 1024'u64
      TB == GB * 1024'u64

  test "Memory stats fields are properly populated":
    let stats = getMemoryStats()
    check:
      stats.pagesFree * uint64(stats.pageSize) <= stats.totalPhysical
      stats.pagesActive * uint64(stats.pageSize) <= stats.totalPhysical
      stats.pagesInactive * uint64(stats.pageSize) <= stats.totalPhysical
      stats.pagesWired * uint64(stats.pageSize) <= stats.totalPhysical
