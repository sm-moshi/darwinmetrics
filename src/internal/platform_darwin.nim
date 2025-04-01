## Darwin-specific low-level API stubs
##
## This module provides low-level access to Darwin-specific system information
## via the sysctl interface.
##
## Requirements:
## * Darwin 21.0 or later (macOS 12.0+)
## * Support for both Intel (x86_64) and Apple Silicon (arm64) architectures
##
## Note: While sysctlbyname is available in earlier versions, we set a minimum
## supported version to ensure consistent behavior and feature availability.
{.push raises: [].}

import std/[strutils]

type
  SysctlError* = object of CatchableError
  DarwinVersionError* = object of CatchableError

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

proc getDarwinVersion*(): tuple[major, minor: int] {.raises: [SysctlError].} =
  ## Returns the Darwin kernel version as major.minor
  let version = getSysctlString("kern.osrelease")
  try:
    let parts = version.split('.')
    if parts.len >= 2:
      result = (parseInt(parts[0]), parseInt(parts[1]))
    else:
      raise newException(ValueError, "Invalid version format")
  except ValueError:
    raise newException(SysctlError, "Failed to parse Darwin version: " & version)

proc checkDarwinVersion*() {.raises: [DarwinVersionError].} =
  ## Verifies that the current Darwin version meets minimum requirements
  try:
    let (major, minor) = getDarwinVersion()
    if major < 21:
      raise newException(
        DarwinVersionError,
        "Darwin version " & $major & "." & $minor &
        " is not supported. Minimum required version is 21.0 (macOS 12.0)"
      )
  except SysctlError as e:
    raise newException(DarwinVersionError, "Failed to check Darwin version: " & e.msg)

proc getMachineArchitecture*(): string {.raises: [SysctlError, DarwinVersionError].} =
  ## Returns the machine architecture (e.g. "arm64" for Apple Silicon, "x86_64" for Intel)
  checkDarwinVersion()
  result = getSysctlString("hw.machine")

proc getMachineModel*(): string {.raises: [SysctlError, DarwinVersionError].} =
  ## Returns the machine model identifier (e.g. "MacBookPro18,3")
  checkDarwinVersion()
  result = getSysctlString("hw.model")

proc getCpuBrand*(): string {.raises: [SysctlError, DarwinVersionError].} =
  ## Returns the CPU brand string (e.g. "Apple M1 Pro")
  checkDarwinVersion()
  result = getSysctlString("machdep.cpu.brand_string")

{.pop.}
