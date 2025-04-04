## Mach kernel statistics bindings
##
## This module provides low-level access to Mach kernel statistics
## via the host_statistics interface.
##
## Note: This is Darwin-specific and requires linking against the Mach framework.

import ./darwin_errors

{.passL: "-framework CoreFoundation -framework IOKit".}

type
  MachPort* = distinct uint32 ## Mach port type
  HostFlavorT* = distinct int32 ## Host information flavor
  MachTimeT* = uint32 ## Mach time type

  HostCpuLoadInfo* {.pure, packed.} = object
    userTicks*: array[0 .. 3, uint32]   ## CPU ticks in user mode
    systemTicks*: array[0 .. 3, uint32] ## CPU ticks in system mode
    idleTicks*: array[0 .. 3, uint32]   ## CPU ticks idle
    niceTicks*: array[0 .. 3, uint32]   ## CPU ticks in nice priority

  HostLoadInfo* {.pure, packed.} = object
    avenrun*: array[0 .. 2, int32]     ## Load averages (scaled by LOAD_SCALE)
    mach_factor*: array[0 .. 2, int32] ## Resource availability mach factor

const
  KERN_SUCCESS* = 0.cint
  LOAD_SCALE* = 1000 ## Scale factor for load averages
  PROCESSOR_CPU_LOAD_INFO* = 2 ## Flavor for per-processor CPU load info

let
  hostCpuLoadInfoCount* = (sizeof(HostCpuLoadInfo) div sizeof(int32)).uint32
  hostLoadInfoCount* = (sizeof(HostLoadInfo) div sizeof(int32)).uint32

# Make sure the mach_host_self function is properly declared
proc mach_host_self*(): MachPort {.importc, header: "<mach/mach_host.h>".}

# Add host_processor_info and vm_deallocate definitions
proc host_processor_info*(
  host: MachPort,
  flavor: cint,
  processor_count: ptr uint32,
  processor_info: ptr pointer,
  processor_info_count: ptr uint32
): cint {.importc, header: "<mach/processor_info.h>".}

proc vm_deallocate*(
  target_task: MachPort,
  address: uint64,  # Use uint64 for vm_address_t on 64-bit systems
  size: uint64
): cint {.importc, header: "<mach/vm_map.h>".}

proc host_statistics(
  host_priv: MachPort,
  flavor: HostFlavorT,
  host_info_out: pointer,
  host_info_outCnt: ptr uint32,
): cint {.importc, header: "<mach/mach_host.h>".}

proc getHostCpuLoadInfo*(): HostCpuLoadInfo {.raises: [DarwinError].} =
  ## Get CPU load information from the Mach kernel
  ## Raises DarwinError if the statistics cannot be retrieved
  var
    count = hostCpuLoadInfoCount
    info: HostCpuLoadInfo

  let host = mach_host_self()
  if host_statistics(host, 3.HostFlavorT, addr info, addr count) != KERN_SUCCESS:
    raise newException(DarwinError, "Failed to get host CPU load info")

  info

proc getHostLoadInfo*(): HostLoadInfo {.raises: [DarwinError].} =
  ## Get system load averages from the Mach kernel
  ## The load averages are scaled by LOAD_SCALE
  ## Raises DarwinError if the statistics cannot be retrieved
  var
    count = hostLoadInfoCount
    info: HostLoadInfo

  let host = mach_host_self()
  if host_statistics(host, 1.HostFlavorT, addr info, addr count) != KERN_SUCCESS:
    raise newException(DarwinError, "Failed to get host load info")

  info
