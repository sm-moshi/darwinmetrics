## Memory management types and constants for Darwin systems.
##
## This module defines the core types and constants used for memory management,
## including memory pressure levels, statistics, and error handling.

type
  MemoryPressureLevel* = enum
    ## Memory pressure level as reported by the system
    mplNormal = 1    ## Normal memory conditions
    mplWarning = 2   ## Warning level - memory pressure increasing
    mplCritical = 4  ## Critical level - severe memory pressure

  MemoryError* = object of CatchableError
    ## Error type for memory-related operations
    code*: int       ## Error code from the operation
    operation*: string  ## Name of the operation that failed

  MemoryStats* = object
    ## Memory statistics for the system
    totalPhysical*: uint64      ## Total physical memory in bytes
    availablePhysical*: uint64  ## Available physical memory in bytes
    usedPhysical*: uint64      ## Used physical memory in bytes
    pressureLevel*: MemoryPressureLevel  ## Current memory pressure level
    pageSize*: uint32          ## System page size in bytes
    pagesFree*: uint64        ## Number of free pages
    pagesActive*: uint64      ## Number of active pages
    pagesInactive*: uint64    ## Number of inactive pages
    pagesWired*: uint64       ## Number of wired (locked) pages
    pagesCompressed*: uint64  ## Number of compressed pages

  TaskMemoryInfo* = object
    ## Memory information for a specific task/process
    virtualSize*: uint64      ## Virtual memory size
    residentSize*: uint64     ## Resident memory size
    residentSizeMax*: uint64  ## Peak resident size

  MachVMStatistics* = object
    ## Low-level VM statistics from Mach kernel
    freeCount*: uint32        ## Number of pages free
    activeCount*: uint32      ## Number of pages active
    inactiveCount*: uint32    ## Number of pages inactive
    wireCount*: uint32        ## Number of pages wired down
    zeroFillCount*: uint32    ## Number of zero fill pages
    reactivations*: uint32    ## Number of pages reactivated
    pageIns*: uint32         ## Number of pageins
    pageOuts*: uint32        ## Number of pageouts
    faults*: uint32          ## Number of faults
    copy*: uint32            ## Number of copy-on-write faults
    compressions*: uint32    ## Number of pages compressed
    decompressions*: uint32  ## Number of pages decompressed
    swapIns*: uint32        ## Number of swap ins
    swapOuts*: uint32       ## Number of swap outs

  HostBasicInfo* {.pure, packed.} = object
    ## Direct mapping of Mach kernel host_basic_info structure
    maxCpus*: int32          ## Maximum number of CPUs possible
    availCpus*: int32        ## Number of CPUs currently available
    memorySize*: uint64      ## Total memory size in bytes
    cpuType*: int32         ## CPU type
    cpuSubtype*: int32      ## CPU subtype
    cpuThreadtype*: int32   ## CPU thread type
    physicalCpus*: int32    ## Number of physical CPUs
    physicalCpuMax*: int32  ## Maximum number of physical CPUs
    logicalCpus*: int32     ## Number of logical CPUs
    logicalCpuMax*: int32   ## Maximum number of logical CPUs
    maxMem*: uint64        ## Maximum memory size in bytes

  TaskBasicInfo64* {.pure, packed, importc: "struct mach_task_basic_info",
                     header: "<mach/task_info.h>".} = object
    ## Direct mapping of Mach kernel mach_task_basic_info structure
    virtual_size*: uint64    ## Virtual memory size (bytes)
    resident_size*: uint64   ## Resident memory size (bytes)
    resident_size_max*: uint64  ## Peak resident size (bytes)
    user_time*: uint64       ## User run time
    system_time*: uint64     ## System run time
    policy*: int32          ## Default policy
    suspend_count*: uint32  ## Suspend count for task

  VMStatistics64* {.pure, packed, importc: "struct vm_statistics64",
                   header: "<mach/vm_statistics.h>".} = object
    ## Direct mapping of Mach kernel vm_statistics64 structure
    free_count*: uint64           ## Number of free pages
    active_count*: uint64         ## Number of active pages
    inactive_count*: uint64       ## Number of inactive pages
    wire_count*: uint64          ## Number of wired (locked) pages
    zero_fill_count*: uint64     ## Number of zero fill pages
    reactivations*: uint64       ## Number of reactivated pages
    pageins*: uint64            ## Number of pageins
    pageouts*: uint64           ## Number of pageouts
    faults*: uint64             ## Number of faults
    cow_faults*: uint64         ## Number of copy-on-write faults
    lookups*: uint64           ## Number of object cache lookups
    hits*: uint64              ## Number of object cache hits
    purges*: uint64            ## Number of purges
    purgeable_count*: uint64   ## Number of purgeable pages
    speculative_count*: uint64 ## Number of speculative pages
    decompressions*: uint64    ## Number of pages decompressed
    compressions*: uint64      ## Number of pages compressed
    swapins*: uint64          ## Number of swap ins
    swapouts*: uint64         ## Number of swap outs
    compressor_page_count*: uint64 ## Number of pages in compressor

const
  # Memory pressure thresholds (percentage of free memory)
  MEMORY_PRESSURE_WARNING* = 15'u8   ## Warning threshold percentage
  MEMORY_PRESSURE_CRITICAL* = 10'u8  ## Critical threshold percentage

  # Common memory size units in bytes
  KB* = 1024'u64
  MB* = KB * 1024'u64
  GB* = MB * 1024'u64
  TB* = GB * 1024'u64

  # Host VM info count for vm_statistics64
  HostVMInfoCount* = 38'u32  ## Size of vm_statistics64 structure

  # Mach kernel constants
  SYSCTL_CTL_HW* = 6'i32           ## sysctl hw namespace
  SYSCTL_CTL_VM* = 2'i32           ## sysctl vm namespace
  SYSCTL_HW_MEMSIZE* = 24'i32      ## Memory size parameter
  SYSCTL_HW_PAGESIZE* = 7'i32      ## Page size parameter
  MACH_TASK_BASIC_INFO* = 20'i32   ## Task info flavor for mach_task_basic_info
  HOST_VM_INFO64* = 4'i32          ## Host VM info flavor
  MACH_KERN_SUCCESS* = 0'i32        ## Success return code
  MACH_KERN_INVALID_ARGUMENT* = 4'i32  ## Invalid argument error
  MACH_KERN_PROTECTION_FAILURE* = 5'i32 ## Protection failure error
  MACH_KERN_NO_SPACE* = 3'i32         ## No space error
  MACH_KERN_RESOURCE_SHORTAGE* = 2'i32 ## Resource shortage error
