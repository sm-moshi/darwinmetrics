## CPU metrics module for Darwin
##
## This module provides CPU-related metrics and information for Darwin-based systems.
## Requires macOS 12.0+ (Darwin 21.0+).

import std/[strformat, strutils, options]
import ../internal/platform_darwin
import ../internal/darwin_errors

type CpuInfo* = object ## CPU information structure
  physicalCores*: int ## Number of physical CPU cores
  logicalCores*: int ## Number of logical CPU cores (including hyperthreading)
  architecture*: string ## CPU architecture (e.g., "arm64" or "x86_64")
  model*: string ## Machine model identifier
  brand*: string ## CPU brand string
  maxFrequency*: Option[float] ## Maximum CPU frequency in MHz (if available)

proc validateCpuInfo(info: CpuInfo) =
  ## Validates CPU information
  ## Raises DarwinError if any fields are invalid
  if info.physicalCores <= 0:
    raise
      newException(DarwinError, "Invalid physical core count: " & $info.physicalCores)
  if info.logicalCores < info.physicalCores:
    raise newException(DarwinError, "Logical cores cannot be less than physical cores")
  if info.logicalCores mod info.physicalCores != 0:
    raise
      newException(DarwinError, "Logical cores must be a multiple of physical cores")
  if info.architecture notin ["arm64", "x86_64"]:
    raise newException(DarwinError, "Invalid architecture: " & info.architecture)
  if info.model.len == 0:
    raise newException(DarwinError, "Model cannot be empty")
  if info.brand.len == 0:
    raise newException(DarwinError, "Brand cannot be empty")

proc newCpuInfo*(
    physicalCores: int,
    logicalCores: int,
    architecture: string,
    model: string,
    brand: string,
    maxFrequency: Option[float] = none(float),
): CpuInfo =
  ## Creates a new CpuInfo instance with validation
  ## Raises DarwinError if any fields are invalid
  result = CpuInfo(
    physicalCores: physicalCores,
    logicalCores: logicalCores,
    architecture: architecture,
    model: model,
    brand: brand,
    maxFrequency: maxFrequency,
  )
  validateCpuInfo(result)

proc getCoreCount(): tuple[physical, logical: int] =
  ## Internal helper to get physical and logical core counts
  ## Raises DarwinError if sysctl calls fail
  let
    physical = getSysctlInt("hw.physicalcpu")
    logical = getSysctlInt("hw.logicalcpu")

  if physical <= 0 or logical <= 0:
    raise newException(DarwinError, "Invalid CPU core count returned by sysctl")

  result = (physical: physical, logical: logical)

proc getMaxFrequency(): Option[float] =
  ## Internal helper to get max CPU frequency
  ## Returns None if frequency cannot be determined
  try:
    let freqHz = getSysctlInt("hw.cpufrequency_max")
    if freqHz > 0:
      some(freqHz.float / 1_000_000) # Convert Hz to MHz
    else:
      none(float)
  except DarwinError:
    none(float)

proc getCpuInfo*(): CpuInfo =
  ## Returns detailed CPU information for the current system.
  ##
  ## This includes:
  ## * Number of physical and logical CPU cores
  ## * CPU architecture (arm64/x86_64)
  ## * Machine model identifier
  ## * CPU brand string
  ## * Maximum CPU frequency (if available)
  ##
  ## Raises:
  ## * DarwinError if system information cannot be retrieved
  ## * DarwinVersionError if running on an unsupported Darwin version

  checkDarwinVersion()

  let cores = getCoreCount()
  result = newCpuInfo(
    physicalCores = cores.physical,
    logicalCores = cores.logical,
    architecture = getMachineArchitecture(),
    model = getMachineModel(),
    brand = getCpuBrand(),
    maxFrequency = getMaxFrequency(),
  )

proc `$`*(info: CpuInfo): string =
  ## String representation of CPU information
  validateCpuInfo(info) # Validate before creating string representation
  let freqStr =
    if info.maxFrequency.isSome:
      fmt"{info.maxFrequency.get():.1f} MHz"
    else:
      "Unknown"

  fmt"""CPU Information:
  Architecture: {info.architecture}
  Physical Cores: {info.physicalCores}
  Logical Cores: {info.logicalCores}
  Model: {info.model}
  Brand: {info.brand}
  Max Frequency: {freqStr}"""
