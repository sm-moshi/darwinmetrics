## Memory management types and constants for Darwin systems.
##
## This module defines the core types and constants used for memory management
## and pressure monitoring on Darwin systems.

type
  MemoryPressureLevel* = enum
    ## Represents the current memory pressure level of the system
    mplNormal = "normal"     ## Normal memory conditions
    mplWarning = "warning"   ## Memory pressure is elevated
    mplCritical = "critical" ## System is under critical memory pressure

  MemoryError* = object of CatchableError
    ## Represents errors that can occur during memory operations
    code*: int              ## The error code from the underlying system call
    operation*: string      ## The operation that failed

  MemoryStats* = object
    ## Statistics about the system's memory usage
    totalPhysical*: uint64    ## Total physical memory in bytes
    availablePhysical*: uint64 ## Available physical memory in bytes
    usedPhysical*: uint64     ## Used physical memory in bytes
    pressureLevel*: MemoryPressureLevel ## Current memory pressure level
    pageSize*: uint32         ## System page size in bytes
    pagesFree*: uint64        ## Number of free pages
    pagesActive*: uint64      ## Number of active pages
    pagesInactive*: uint64    ## Number of inactive pages
    pagesWired*: uint64       ## Number of wired (locked) pages
    pagesCompressed*: uint64  ## Number of compressed pages

const
  ## Memory pressure thresholds (in percentage of total memory)
  WarningPressureThreshold* = 75.0  ## Threshold for warning pressure level
  CriticalPressureThreshold* = 90.0 ## Threshold for critical pressure level

  ## Common memory size units in bytes
  Kilobyte* = 1024'u64
  Megabyte* = Kilobyte * 1024
  Gigabyte* = Megabyte * 1024
