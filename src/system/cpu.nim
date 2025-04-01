## CPU metrics module for Darwin
##
## This module provides CPU-related metrics and information for Darwin-based systems.

import std/[strformat]
import ../internal/platform_darwin

type
  CpuInfo* = object
    ## CPU information structure
    architecture*: string  ## CPU architecture (e.g., "arm64" or "x86_64")
    model*: string        ## Machine model identifier
    brand*: string        ## CPU brand string

proc getCpuInfo*(): CpuInfo =
  ## Returns detailed CPU information for the current system.
  ##
  ## This includes:
  ## * CPU architecture (arm64/x86_64)
  ## * Machine model identifier
  ## * CPU brand string
  ##
  ## Raises:
  ## * SysctlError if system information cannot be retrieved
  result = CpuInfo(
    architecture: getMachineArchitecture(),
    model: getMachineModel(),
    brand: getCpuBrand()
  )

proc `$`*(info: CpuInfo): string =
  ## String representation of CPU information
  fmt"""CPU Information:
  Architecture: {info.architecture}
  Model: {info.model}
  Brand: {info.brand}"""
