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

import std/[strutils]
import ./darwin_errors

type
  SysctlError* = object of CatchableError
  DarwinVersionError* = object of CatchableError

proc sysctlbyname(
  name: cstring, oldp: pointer, oldlenp: ptr uint, newp: pointer, newlen: uint
): cint {.importc, header: "<sys/sysctl.h>".}

proc getSysctlString*(name: string): string =
  ## Get string value from sysctl
  ## Raises DarwinError if the sysctl call fails
  var
    len: uint = 0
    oldp: pointer

  # First get the string length
  if sysctlbyname(name.cstring, nil, len.addr, nil, 0) != 0:
    raise newException(DarwinError, "Failed to get sysctl length for " & name)

  # Allocate buffer and get the value
  result = newString(len)
  if sysctlbyname(name.cstring, result[0].addr, len.addr, nil, 0) != 0:
    raise newException(DarwinError, "Failed to get sysctl value for " & name)

  # Remove null terminator if present
  if result.endsWith('\0'):
    result.setLen(result.len - 1)

proc getSysctlInt*(name: string): int =
  ## Get integer value from sysctl
  ## Raises DarwinError if the sysctl call fails
  var
    value: int
    size = sizeof(value).uint

  if sysctlbyname(name.cstring, value.addr, size.addr, nil, 0) != 0:
    raise newException(DarwinError, "Failed to get sysctl value for " & name)

  result = value

proc getDarwinVersion*(): tuple[major, minor: int] {.
    raises: [SysctlError, DarwinError]
.} =
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

proc checkDarwinVersion*() {.raises: [DarwinError, DarwinVersionError, ValueError].} =
  ## Check if current Darwin version meets minimum requirements
  ## Raises:
  ## * DarwinVersionError if version is too old
  ## * ValueError if version string is malformed
  const MinVersion = 21 # macOS 12.0
  let version = parseInt(getSysctlString("kern.osrelease").split('.')[0])

  if version < MinVersion:
    raise newException(
      DarwinVersionError,
      "Darwin version " & $version & " is not supported. " &
        "Minimum required version is " & $MinVersion & " (macOS 12.0+)",
    )

# Platform detection functions
proc getMachineArchitecture*(): string {.raises: [DarwinError].} =
  ## Get the current machine architecture
  result = getSysctlString("hw.machine")

proc getMachineModel*(): string {.raises: [DarwinError].} =
  ## Get the current machine model
  result = getSysctlString("hw.model")

proc getCpuBrand*(): string {.raises: [DarwinError].} =
  ## Get the CPU brand string
  result = getSysctlString("machdep.cpu.brand_string")
