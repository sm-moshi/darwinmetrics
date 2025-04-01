## Memory management implementation for Darwin systems using unprivileged APIs.
##
## This module provides memory statistics and pressure monitoring using sysctl
## and task_info APIs that don't require elevated privileges.

import std/posix
import std/strformat
import ./memory_types
import ./darwin_errors
import ./mach_stats

{.passC: "-I/usr/include".}
{.passC: "-I/usr/include/mach".}
{.passC: "-D__DARWIN_UNIX03".}
{.passL: "-framework CoreFoundation".}

{.emit: """/*TYPESECTION*/
#include <mach/mach.h>
#include <mach/task_info.h>
#include <mach/mach_init.h>
#include <sys/sysctl.h>
""".}

type
  MachPort* = distinct uint32

{.pragma: mach_import, importc, nodecl.}

proc sysctl(name: ptr cint, namelen: uint32, oldp: pointer, oldlenp: ptr uint,
            newp: pointer = nil, newlen: uint = 0): cint {.mach_import.}

proc sysctlbyname*(name: cstring, oldp: pointer, oldlenp: ptr uint,
                  newp: pointer = nil, newlen: uint = 0): cint {.mach_import.}

proc mach_task_self(): MachPort {.mach_import.}

proc task_info(task: MachPort, flavor: int32, info_out: pointer,
               count: ptr uint32): cint {.mach_import.}

proc host_statistics64(host: MachPort, flavor: int32, info_out: pointer,
                      count: ptr uint32): cint {.mach_import.}

proc mach_host_self(): MachPort {.mach_import.}

{.emit: """/*INCLUDESECTION*/
#include <mach/mach.h>
#include <mach/task_info.h>
#include <mach/mach_init.h>
#include <sys/sysctl.h>
""".}

proc getSystemPageSize*(): uint32 {.exportc: "getSystemPageSize", dynlib.} =
  ## Get the system page size using sysctl
  var pageSize: uint32
  var size = sizeof(pageSize).uint
  let mib = [SYSCTL_CTL_HW.cint, SYSCTL_HW_PAGESIZE.cint]

  if sysctl(cast[ptr cint](unsafeAddr mib[0]), 2,
            addr pageSize, addr size, nil, 0) != 0:
    var err = newException(MemoryError, "Failed to get system page size")
    err.code = errno
    err.operation = "sysctl(HW_PAGESIZE)"
    raise err

  result = pageSize

proc getMemoryPressureLevel*(): MemoryPressureLevel {.exportc: "getMemoryPressureLevel", dynlib.} =
  ## Get the current memory pressure level using sysctl
  var level: cint
  var size = sizeof(level).uint

  if sysctlbyname("kern.memorystatus_vm_pressure_level",
                  addr level, addr size, nil, 0) != 0:
    return mplNormal # Default to normal if we can't get the pressure level

  case level
  of 1: mplNormal
  of 2: mplWarning
  of 4: mplCritical
  else: mplNormal

proc getTaskMemoryInfo*(): TaskMemoryInfo {.exportc: "getTaskMemoryInfo", dynlib.} =
  ## Get memory information for the current process
  var info: TaskBasicInfo64
  var count = uint32(sizeof(info) div sizeof(uint32))
  let task = mach_task_self()

  if task_info(task, MACH_TASK_BASIC_INFO, cast[pointer](addr info), addr count) != MACH_KERN_SUCCESS:
    var err = newException(MemoryError, "Failed to get task memory info")
    err.code = errno
    err.operation = "task_info"
    raise err

  result = TaskMemoryInfo(
    virtualSize: info.virtual_size,
    residentSize: info.resident_size,
    residentSizeMax: info.resident_size_max
  )

proc getMemoryStats*(): MemoryStats {.exportc: "getMemoryStats", dynlib.} =
  ## Get comprehensive memory statistics using unprivileged APIs
  var memSize: uint64
  var size = sizeof(memSize).uint
  let mib = [SYSCTL_CTL_HW.cint, SYSCTL_HW_MEMSIZE.cint]

  # Get total physical memory
  if sysctl(cast[ptr cint](unsafeAddr mib[0]), 2,
            addr memSize, addr size, nil, 0) != 0:
    var err = newException(MemoryError, "Failed to get total memory size")
    err.code = errno
    err.operation = "sysctl(HW_MEMSIZE)"
    raise err

  # Get page size
  let pageSize = getSystemPageSize()

  # Get memory pressure level
  let pressureLevel = getMemoryPressureLevel()

  # Get VM statistics using host_statistics64
  var vmStats: VMStatistics64
  var count = uint32(sizeof(vmStats) div sizeof(uint32))
  let host = mach_host_self()

  if host_statistics64(host, HOST_VM_INFO64, cast[pointer](addr vmStats), addr count) != MACH_KERN_SUCCESS:
    var err = newException(MemoryError, "Failed to get VM statistics")
    err.code = errno
    err.operation = "host_statistics64"
    raise err

  # Calculate memory usage from VM stats
  let pagesFree = vmStats.free_count
  let pagesActive = vmStats.active_count
  let pagesInactive = vmStats.inactive_count
  let pagesWired = vmStats.wire_count
  let pagesCompressed = vmStats.compressor_page_count

  let usedPhysical = (pagesActive + pagesWired + pagesCompressed) * pageSize.uint64
  let availablePhysical = (pagesFree + pagesInactive) * pageSize.uint64

  result = MemoryStats(
    totalPhysical: memSize,
    availablePhysical: availablePhysical,
    usedPhysical: usedPhysical,
    pressureLevel: pressureLevel,
    pageSize: pageSize,
    pagesFree: pagesFree,
    pagesActive: pagesActive,
    pagesInactive: pagesInactive,
    pagesWired: pagesWired,
    pagesCompressed: pagesCompressed
  )
