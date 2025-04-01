## Memory management types and constants for Darwin systems.
##
## This module defines the core types and constants used for memory management
## on Darwin-based systems (macOS, iOS). It provides type definitions that map
## directly to Mach kernel structures and constants for memory statistics,
## pressure levels, and error handling.
##
## The types and constants in this module support both Intel and Apple Silicon
## architectures, ensuring consistent memory management across platforms.
##
## Example:
##
## .. code-block:: nim
##   # Create memory statistics object
##   var stats = MemoryStats()
##
##   # Memory sizes can be compared using predefined constants
##   if stats.availablePhysical < 2 * GB:
##     echo "Available memory is less than 2GB"
##
##   # Memory pressure can be checked
##   if stats.pressureLevel == mplWarning:
##     echo "System is under memory pressure"

type
  MemoryPressureLevel* = enum
    ## System memory pressure level as reported by the Darwin kernel.
    ## This indicates the current memory utilisation state of the system.
    mplNormal = 1    ## Normal memory utilisation conditions
    mplWarning = 2   ## Warning level - memory pressure is elevated
    mplCritical = 4  ## Critical level - severe memory pressure, action required

  MemoryError* = object of CatchableError
    ## Error type for memory-related operations.
    ## Provides detailed information about memory operation failures.
    code*: int       ## Error code from the failed operation
    operation*: string  ## Name of the operation that failed

  MemoryStats* = object
    ## Comprehensive system memory statistics.
    ##
    ## This object provides a high-level view of system memory utilisation,
    ## including physical memory usage, pressure levels, and detailed page counts.
    totalPhysical*: uint64      ## Total physical memory in bytes
    availablePhysical*: uint64  ## Available physical memory in bytes
    usedPhysical*: uint64      ## Used physical memory in bytes
    pressureLevel*: MemoryPressureLevel  ## Current memory pressure level
    pageSize*: uint32          ## System memory page size in bytes
    pagesFree*: uint64        ## Number of free pages
    pagesActive*: uint64      ## Number of active pages in use
    pagesInactive*: uint64    ## Number of inactive pages that can be reclaimed
    pagesWired*: uint64       ## Number of wired (locked) pages that cannot be paged out
    pagesCompressed*: uint64  ## Number of compressed pages in the compression pool

  TaskMemoryInfo* = object
    ## Memory information for a specific task/process.
    ##
    ## Provides detailed memory usage statistics for a single process,
    ## including virtual and physical memory utilisation.
    virtualSize*: uint64      ## Total virtual memory size in bytes
    residentSize*: uint64     ## Current resident (physical) memory size in bytes
    residentSizeMax*: uint64  ## Peak resident memory size in bytes

  MachVMStatistics* = object
    ## Low-level virtual memory statistics from the Mach kernel.
    ##
    ## This structure provides detailed statistics about virtual memory
    ## system activity and performance.
    freeCount*: uint32        ## Number of free pages available
    activeCount*: uint32      ## Number of pages currently in use
    inactiveCount*: uint32    ## Number of pages marked as inactive
    wireCount*: uint32        ## Number of pages wired down (cannot be paged out)
    zeroFillCount*: uint32    ## Number of zero fill pages created
    reactivations*: uint32    ## Number of pages reactivated from inactive state
    pageIns*: uint32         ## Number of pageins from disk
    pageOuts*: uint32        ## Number of pageouts to disk
    faults*: uint32          ## Total number of page faults
    copy*: uint32            ## Number of copy-on-write faults
    compressions*: uint32    ## Number of pages compressed
    decompressions*: uint32  ## Number of pages decompressed
    swapIns*: uint32        ## Number of swap-ins from swap space
    swapOuts*: uint32       ## Number of swap-outs to swap space

  HostBasicInfo* {.pure, packed.} = object
    ## Direct mapping of Mach kernel host_basic_info structure.
    ##
    ## Provides basic information about the host system's CPU and memory
    ## configuration.
    maxCpus*: int32          ## Maximum number of CPUs supported
    availCpus*: int32        ## Number of CPUs currently available
    memorySize*: uint64      ## Total memory size in bytes
    cpuType*: int32         ## CPU architecture type
    cpuSubtype*: int32      ## CPU specific subtype
    cpuThreadtype*: int32   ## CPU thread capabilities
    physicalCpus*: int32    ## Number of physical CPU cores
    physicalCpuMax*: int32  ## Maximum number of physical CPU cores
    logicalCpus*: int32     ## Number of logical CPU cores (including SMT)
    logicalCpuMax*: int32   ## Maximum number of logical CPU cores
    maxMem*: uint64        ## Maximum supported memory size in bytes

  TaskBasicInfo64* {.pure, packed, importc: "struct mach_task_basic_info",
                     header: "<mach/task_info.h>".} = object
    ## Direct mapping of Mach kernel mach_task_basic_info structure.
    ##
    ## Provides detailed task/process resource usage information.
    virtual_size*: uint64    ## Virtual memory size in bytes
    resident_size*: uint64   ## Resident memory size in bytes
    resident_size_max*: uint64  ## Peak resident size in bytes
    user_time*: uint64       ## User mode CPU time used
    system_time*: uint64     ## System mode CPU time used
    policy*: int32          ## Scheduling policy
    suspend_count*: uint32  ## Suspension count

  VMStatistics64* {.pure, packed, importc: "struct vm_statistics64",
                   header: "<mach/vm_statistics.h>".} = object
    ## Direct mapping of Mach kernel vm_statistics64 structure.
    ##
    ## Provides comprehensive statistics about the virtual memory system's
    ## current state and historical activity.
    free_count*: uint64           ## Number of free pages
    active_count*: uint64         ## Number of active pages
    inactive_count*: uint64       ## Number of inactive pages
    wire_count*: uint64          ## Number of wired pages
    zero_fill_count*: uint64     ## Number of zero fill pages
    reactivations*: uint64       ## Number of reactivated pages
    pageins*: uint64            ## Number of pageins
    pageouts*: uint64           ## Number of pageouts
    faults*: uint64             ## Number of page faults
    cow_faults*: uint64         ## Number of copy-on-write faults
    lookups*: uint64           ## Number of object cache lookups
    hits*: uint64              ## Number of object cache hits
    purges*: uint64            ## Number of pages purged
    purgeable_count*: uint64   ## Number of purgeable pages
    speculative_count*: uint64 ## Number of speculative pages
    decompressions*: uint64    ## Number of pages decompressed
    compressions*: uint64      ## Number of pages compressed
    swapins*: uint64          ## Number of swap ins
    swapouts*: uint64         ## Number of swap outs
    compressor_page_count*: uint64 ## Number of pages in compressor

const
  # Memory pressure thresholds (percentage of free memory)
  MEMORY_PRESSURE_WARNING* = 15'u8   ## Warning threshold (15% free memory)
  MEMORY_PRESSURE_CRITICAL* = 10'u8  ## Critical threshold (10% free memory)

  # Common memory size units in bytes
  KB* = 1024'u64              ## Kilobyte (1024 bytes)
  MB* = KB * 1024'u64         ## Megabyte (1,048,576 bytes)
  GB* = MB * 1024'u64         ## Gigabyte (1,073,741,824 bytes)
  TB* = GB * 1024'u64         ## Terabyte (1,099,511,627,776 bytes)

  # Host VM info count for vm_statistics64
  HostVMInfoCount* = 38'u32  ## Size of vm_statistics64 structure in 32-bit words

  # Mach kernel constants
  SYSCTL_CTL_HW* = 6'i32           ## sysctl hardware information namespace
  SYSCTL_CTL_VM* = 2'i32           ## sysctl virtual memory namespace
  SYSCTL_HW_MEMSIZE* = 24'i32      ## Total memory size parameter
  SYSCTL_HW_PAGESIZE* = 7'i32      ## System page size parameter
  MACH_TASK_BASIC_INFO* = 20'i32   ## Task info flavour for mach_task_basic_info
  HOST_VM_INFO64* = 4'i32          ## Host VM info flavour for 64-bit statistics
  MACH_KERN_SUCCESS* = 0'i32       ## Operation completed successfully
  MACH_KERN_INVALID_ARGUMENT* = 4'i32  ## Invalid argument provided
  MACH_KERN_PROTECTION_FAILURE* = 5'i32 ## Memory protection violation
  MACH_KERN_NO_SPACE* = 3'i32         ## Insufficient space/resources
  MACH_KERN_RESOURCE_SHORTAGE* = 2'i32 ## System resource shortage
