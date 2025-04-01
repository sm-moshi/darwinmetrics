## CPU metrics module for Darwin
##
## This module provides CPU-related metrics and information for Darwin-based systems.
## Requires macOS 12.0+ (Darwin 21.0+).

import std/[strformat, strutils, options, times, deques]
import ../internal/platform_darwin
import ../internal/darwin_errors
import ../internal/mach_stats

type CpuInfo* = object         ## CPU information structure
  physicalCores*: int          ## Number of physical CPU cores
  logicalCores*: int           ## Number of logical CPU cores (including hyperthreading)
  architecture*: string        ## CPU architecture (e.g., "arm64" or "x86_64")
  model*: string               ## Machine model identifier
  brand*: string               ## CPU brand string
  maxFrequency*: Option[float] ## Maximum CPU frequency in MHz (if available)

type LoadAverage* = object ## System load average information
  oneMinute*: float        ## 1-minute load average
  fiveMinute*: float       ## 5-minute load average
  fifteenMinute*: float    ## 15-minute load average
  timestamp*: Time         ## When this measurement was taken

type LoadHistory* = object     ## Historical load average tracking
  samples*: Deque[LoadAverage] ## Load average samples
  maxSamples*: int             ## Maximum number of samples to keep

const DefaultMaxSamples = 60 # Keep 1 hour of samples at 1-minute intervals

proc validateCpuInfo(info: CpuInfo) =
  ## Validates CPU information
  ## Raises DarwinError if any fields are invalid
  if info.physicalCores <= 0:
    raise
      newException(DarwinError, "Invalid physical core count: " &
          $info.physicalCores)
  if info.logicalCores < info.physicalCores:
    raise newException(DarwinError, "Logical cores cannot be less than physical cores")
  if info.logicalCores mod info.physicalCores != 0:
    raise
      newException(DarwinError, "Logical cores must be a multiple of physical cores")
  if info.architecture notin ["arm64", "x86_64"]:
    raise newException(DarwinError, "Invalid architecture: " &
        info.architecture)
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

proc validateLoadAverage(load: LoadAverage) =
  ## Validates load average values
  ## Raises DarwinError if any values are invalid
  if load.oneMinute < 0.0:
    raise newException(DarwinError, "Invalid 1-minute load average: " &
        $load.oneMinute)
  if load.fiveMinute < 0.0:
    raise newException(DarwinError, "Invalid 5-minute load average: " &
        $load.fiveMinute)
  if load.fifteenMinute < 0.0:
    raise newException(DarwinError, "Invalid 15-minute load average: " &
        $load.fifteenMinute)
  if load.timestamp > getTime():
    raise newException(DarwinError, "Load average timestamp is in the future")

proc `$`*(load: LoadAverage): string =
  ## String representation of load average information
  validateLoadAverage(load)
  fmt"""Load Averages:
  1 minute:  {load.oneMinute:.2f}
  5 minute:  {load.fiveMinute:.2f}
  15 minute: {load.fifteenMinute:.2f}
  Timestamp: {load.timestamp.format("yyyy-MM-dd HH:mm:ss")}"""

proc newLoadHistory*(maxSamples: int = DefaultMaxSamples): LoadHistory =
  ## Creates a new load history tracker
  ## maxSamples determines how many samples to keep (default 60)
  result = LoadHistory(
    samples: initDeque[LoadAverage](),
    maxSamples: maxSamples
  )

proc add*(history: var LoadHistory, load: LoadAverage) =
  ## Adds a load average sample to the history
  ## If the history is full, the oldest sample is removed
  validateLoadAverage(load)
  if history.samples.len >= history.maxSamples:
    discard history.samples.popFirst()
  history.samples.addLast(load)

proc getLoadAverage*(): LoadAverage {.raises: [DarwinError].} =
  ## Get the current system load averages
  ##
  ## Returns a LoadAverage object containing the 1, 5, and 15 minute
  ## load averages along with the timestamp of measurement.
  ## Load averages represent the number of processes in the run queue
  ## (waiting for CPU time) averaged over the specified time period.
  ##
  ## A load average of 1.0 means the system has exactly enough CPU
  ## capacity to handle the current load. Values > 1.0 indicate
  ## processes are waiting for CPU time.
  ##
  ## Raises DarwinError if the load averages cannot be retrieved
  let info = getHostLoadInfo()

  # Convert scaled load averages to float values
  result = LoadAverage(
    oneMinute: info.avenrun[0].float / LOAD_SCALE.float,
    fiveMinute: info.avenrun[1].float / LOAD_SCALE.float,
    fifteenMinute: info.avenrun[2].float / LOAD_SCALE.float,
    timestamp: getTime(),
  )
  validateLoadAverage(result)
