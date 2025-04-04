## CPU types module for Darwin systems.
##
## This module defines the core types used for CPU metrics in Darwin-based systems.
## It provides type definitions that map to Mach kernel structures and constants
## for CPU statistics, load averages, and frequency information.
##
## The types support both Intel and Apple Silicon architectures, ensuring
## consistent CPU metrics across platforms.
##
## Example:
##
## .. code-block:: nim
##   # Create CPU information object
##   var info = CpuInfo()
##
##   # CPU frequencies can be checked
##   if info.frequency.current.isSome:
##     echo "Current CPU frequency: ", info.frequency.current.get(), " MHz"
##
##   # Load averages can be monitored
##   let load = LoadAverage()
##   echo "1-minute load: ", load.oneMinute

import std/[options, times, deques, locks]

type
  CPUState* = enum
    ## CPU power states
    cpuStateUnknown = 0
    cpuStateRunning = 1
    cpuStateStopped = 2
    cpuStateSleeping = 3
    cpuStateHalted = 4
    cpuStateError = 5

  CpuUsage* = object
    ## CPU usage percentages
    user*: float        ## User mode CPU usage (%)
    system*: float      ## System/kernel mode CPU usage (%)
    idle*: float       ## Idle CPU time (%)
    nice*: float       ## Nice CPU usage (%)
    total*: float      ## Total CPU usage (100 - idle)

  CpuFrequency* = object
    ## CPU frequency information in MHz
    nominal*: float                ## Base/nominal frequency
    current*: Option[float]        ## Current frequency (if available)
    max*: Option[float]           ## Maximum frequency (if available)
    min*: Option[float]           ## Minimum frequency (if available)

  CpuCoreStats* = object
    ## Per-core CPU statistics
    usage*: CpuUsage              ## Usage percentages for this core
    frequency*: CpuFrequency      ## Frequency info for this core
    temperature*: Option[float]   ## Core temperature in °C (if available)

  CpuInfo* = object
    ## Basic CPU information
    physicalCores*: int   ## Number of physical CPU cores
    logicalCores*: int    ## Number of logical CPU cores (with hyperthreading)
    architecture*: string ## CPU architecture (arm64/x86_64)
    model*: string       ## Machine model identifier
    brand*: string       ## CPU brand string
    frequency*: CpuFrequency     ## CPU frequency information
    usage*: CpuUsage            ## Current CPU usage percentages
    coreStats*: seq[CpuCoreStats] ## Per-core statistics (if available)
    temperature*: Option[float]  ## CPU package temperature in °C (if available)
    state*: CPUState           ## Current CPU power state
    powerUsage*: Option[float] ## Current CPU power usage in Watts (if available)

  LoadAverage* = object
    ## System load average information
    oneMinute*: float     ## 1 minute load average
    fiveMinute*: float    ## 5 minute load average
    fifteenMinute*: float ## 15 minute load average
    timestamp*: Time      ## When this measurement was taken

  LoadHistory* = ref object
    ## Load average history tracker
    samples*: Deque[LoadAverage]  ## Historical load average samples
    maxSamples*: int             ## Maximum number of samples to keep
    lock*: Lock                  ## Lock for thread safety

  CpuMetrics* = object
    ## Comprehensive CPU metrics
    physicalCores*: int   ## Number of physical CPU cores
    logicalCores*: int    ## Number of logical CPU cores
    architecture*: string ## CPU architecture (arm64/x86_64)
    model*: string       ## Machine model identifier
    brand*: string       ## CPU brand string
    frequency*: CpuFrequency     ## CPU frequency information
    usage*: CpuUsage            ## Current CPU usage percentages
    coreStats*: seq[CpuCoreStats] ## Per-core statistics (if available)
    temperature*: Option[float]  ## CPU package temperature in °C (if available)
    loadAverage*: LoadAverage  ## System load averages
    timestamp*: int64         ## When these metrics were collected (nanoseconds)

proc `$`*(info: CpuInfo): string =
  ## String representation of CPU information
  result = "Architecture: " & info.architecture & "\n"
  result &= "Model: " & info.model & "\n"
  result &= "Brand: " & info.brand & "\n"
  result &= "Physical Cores: " & $info.physicalCores & "\n"
  result &= "Logical Cores: " & $info.logicalCores & "\n"
  result &= "Frequency:\n" & $info.frequency & "\n"
  result &= $info.usage & "\n"
  if info.temperature.isSome:
    result &= "Temperature: " & $info.temperature.get() & "°C\n"
  if info.powerUsage.isSome:
    result &= "Power Usage: " & $info.powerUsage.get() & "W"

proc `$`*(freq: CpuFrequency): string =
  ## String representation of CPU frequency
  result = "Nominal: " & $freq.nominal & " MHz\n"
  result &= "Current: " & (if freq.current.isSome: $freq.current.get() & " MHz" else: "Not available") & "\n"
  if freq.max.isSome:
    result &= "Max: " & $freq.max.get() & " MHz\n"
  if freq.min.isSome:
    result &= "Min: " & $freq.min.get() & " MHz"

proc `$`*(usage: CpuUsage): string =
  ## String representation of CPU usage
  result = "CPU Usage:\n"
  result &= "  User: " & $usage.user & "%\n"
  result &= "  System: " & $usage.system & "%\n"
  result &= "  Nice: " & $usage.nice & "%\n"
  result &= "  Idle: " & $usage.idle & "%\n"
  result &= "  Total: " & $usage.total & "%"
