## Darwin-specific low-level API stubs
{.push raises: [].}

import std/[strutils]

type SysctlError* = object of CatchableError

proc sysctlbyname(
  name: cstring, oldp: pointer, oldlenp: ptr uint, newp: pointer, newlen: uint
): cint {.importc, header: "<sys/sysctl.h>".}

proc getSysctlString*(name: string): string {.raises: [SysctlError].} =
  ## Retrieves a string value from sysctl by name
  var size: uint = 0
  if sysctlbyname(name.cstring, nil, addr size, nil, 0) < 0:
    raise newException(SysctlError, "Failed to get size for " & name)

  result = newString(size)
  if sysctlbyname(name.cstring, addr result[0], addr size, nil, 0) < 0:
    raise newException(SysctlError, "Failed to get value for " & name)

  # Remove null terminator if present
  if result.endsWith('\0'):
    result.setLen(result.len - 1)

proc getMachineArchitecture*(): string {.raises: [SysctlError].} =
  ## Returns the machine architecture (e.g. "arm64" for Apple Silicon, "x86_64" for Intel)
  result = getSysctlString("hw.machine")

proc getMachineModel*(): string {.raises: [SysctlError].} =
  ## Returns the machine model identifier (e.g. "MacBookPro18,3")
  result = getSysctlString("hw.model")

proc getCpuBrand*(): string {.raises: [SysctlError].} =
  ## Returns the CPU brand string (e.g. "Apple M1 Pro")
  result = getSysctlString("machdep.cpu.brand_string")

{.pop.}
