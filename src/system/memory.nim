## Memory metrics module for Darwin
##
## This module provides a high-level interface for retrieving memory statistics
## on Darwin-based systems (macOS). It supports both Intel and Apple Silicon
## architectures.
##
## Example:
##
## ```nim
## import darwinmetrics/system/memory
##
## # Get system memory statistics
## let stats = getMemoryStats()
## echo "Total physical memory: ", stats.totalPhysical
## echo "Available physical memory: ", stats.availablePhysical
## echo "Used physical memory: ", stats.usedPhysical
##
## # Get current process memory info
## let procInfo = getProcessMemoryInfo()
## echo "Process resident size: ", procInfo.residentSize
## echo "Process virtual size: ", procInfo.virtualSize
## ```

import ../internal/[mach_memory, memory_types]
export memory_types.KB, memory_types.MB, memory_types.GB, memory_types.TB

type
  MemoryStats* = object
    ## System-wide memory statistics
    totalPhysical*: uint64     ## Total physical memory in bytes
    availablePhysical*: uint64 ## Available physical memory in bytes
    usedPhysical*: uint64      ## Used physical memory in bytes
    pressureLevel*: MemoryPressureLevel  ## Current memory pressure level
    pageSize*: uint32          ## System page size in bytes
    pagesFree*: uint64        ## Number of free pages
    pagesActive*: uint64      ## Number of active pages in use
    pagesInactive*: uint64    ## Number of inactive pages that can be reclaimed
    pagesWired*: uint64       ## Number of wired (locked) pages
    pagesCompressed*: uint64  ## Number of compressed pages

  ProcessMemoryInfo* = object
    ## Process-specific memory information
    virtualSize*: uint64     ## Virtual memory size in bytes
    residentSize*: uint64    ## Resident set size (RSS) in bytes
    residentPeak*: uint64    ## Peak resident size in bytes

  MemoryPressure* = enum
    ## Memory pressure level indicating system memory availability
    Normal     ## Normal memory pressure - system operating normally
    Warning    ## Warning level - system beginning to experience memory pressure
    Critical   ## Critical level - system under significant memory pressure
    Error      ## Error state - unable to determine memory pressure

proc getMemoryStats*(): MemoryStats {.raises: [ref MemoryError].} =
  ## Returns system-wide memory statistics.
  ##
  ## This procedure retrieves the current memory usage statistics from the system,
  ## including total, used, and available physical memory.
  ##
  ## Returns:
  ##   A `MemoryStats` object containing various memory metrics
  ##
  ## Raises:
  ##   MemoryError: If a memory-related operation fails
  ##
  ## Example:
  ##   ```nim
  ##   let stats = getMemoryStats()
  ##   echo "Total memory: ", stats.totalPhysical div GB, " GB"
  ##   echo "Available memory: ", stats.availablePhysical div MB, " MB"
  ##   ```
  let internalStats = mach_memory.getMemoryStats()
  let pageSize = mach_memory.getSystemPageSize()

  result = MemoryStats(
    totalPhysical: internalStats.totalPhysical,
    availablePhysical: internalStats.availablePhysical,
    usedPhysical: internalStats.usedPhysical,
    pressureLevel: internalStats.pressureLevel,
    pageSize: uint32(pageSize),
    pagesFree: internalStats.pagesFree,
    pagesActive: internalStats.pagesActive,
    pagesInactive: internalStats.pagesInactive,
    pagesWired: internalStats.pagesWired,
    pagesCompressed: internalStats.pagesCompressed
  )

proc getProcessMemoryInfo*(): ProcessMemoryInfo {.raises: [ref MemoryError].} =
  ## Returns memory information for the current process.
  ##
  ## This procedure retrieves memory usage statistics for the currently running
  ## process, including resident and virtual memory sizes.
  ##
  ## Returns:
  ##   A `ProcessMemoryInfo` object containing process memory metrics
  ##
  ## Raises:
  ##   MemoryError: If a memory-related operation fails
  ##
  ## Example:
  ##   ```nim
  ##   let procInfo = getProcessMemoryInfo()
  ##   echo "Process RSS: ", procInfo.residentSize div MB, " MB"
  ##   echo "Process virtual size: ", procInfo.virtualSize div GB, " GB"
  ##   ```
  let taskInfo = mach_memory.getTaskMemoryInfo()

  result = ProcessMemoryInfo(
    virtualSize: taskInfo.virtualSize,
    residentSize: taskInfo.residentSize,
    residentPeak: taskInfo.residentSizeMax
  )

proc getMemoryPressureLevel*(): MemoryPressure {.raises: [].} =
  ## Returns the current memory pressure level of the system.
  ##
  ## This procedure provides insight into the system's memory availability
  ## and pressure state. It can be used to make decisions about memory usage
  ## in your application.
  ##
  ## Returns:
  ##   A `MemoryPressure` enum value indicating the current pressure level
  ##
  ## Example:
  ##   ```nim
  ##   let pressure = getMemoryPressureLevel()
  ##   case pressure
  ##   of Normal: echo "Memory pressure is normal"
  ##   of Warning: echo "System is experiencing memory pressure"
  ##   of Critical: echo "System is under critical memory pressure"
  ##   of Error: echo "Unable to determine memory pressure"
  ##   ```
  let level = mach_memory.getMemoryPressureLevel()
  case level
  of memory_types.mplNormal: Normal
  of memory_types.mplWarning: Warning
  of memory_types.mplCritical: Critical
