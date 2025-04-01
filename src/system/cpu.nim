## CPU metrics module for Darwin
##
## This module provides CPU-related metrics and information for Darwin-based systems.
## Requires macOS 12.0+ (Darwin 21.0+).

import std/[strformat, strutils, options, times, deques, asyncdispatch, locks]
import ../internal/[platform_darwin, cpu_types, darwin_errors]
from ../internal/mach_stats import
  HostCpuLoadInfo, HostLoadInfo, KERN_SUCCESS, LOAD_SCALE, PROCESSOR_CPU_LOAD_INFO,
  mach_host_self, host_processor_info, vm_deallocate, getHostLoadInfo, getHostCpuLoadInfo

export cpu_types

const DefaultMaxSamples = 60 # Keep 1 hour of samples at 1-minute intervals

proc validateCpuInfo*(info: CpuInfo) =
  ## Validates CPU information, raising DarwinError for invalid fields
  if info.physicalCores <= 0:
    raise newException(DarwinError, "Invalid physical core count")
  if info.logicalCores <= 0:
    raise newException(DarwinError, "Invalid logical core count")
  if info.architecture.len == 0:
    raise newException(DarwinError, "Missing CPU architecture")
  if info.architecture notin ["arm64", "x86_64"]:
    raise newException(DarwinError, "Invalid CPU architecture: " & info.architecture)
  if info.model.len == 0:
    raise newException(DarwinError, "Missing machine model")
  if info.brand.len == 0:
    raise newException(DarwinError, "Missing CPU brand")

proc newCpuInfo*(
    physicalCores: int,
    logicalCores: int,
    architecture: string,
    model: string,
    brand: string,
    frequency: CpuFrequency,
): CpuInfo =
  ## Creates a new CpuInfo instance with validation
  ## Raises DarwinError if any fields are invalid
  result = CpuInfo(
    physicalCores: physicalCores,
    logicalCores: logicalCores,
    architecture: architecture,
    model: model,
    brand: brand,
    frequency: frequency,
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

proc getFrequencyInfo(): CpuFrequency =
  ## Get CPU frequency information
  ## Note: Current frequency is not available in user mode on macOS
  ## Returns nominal frequency and optionally max/min if available
  result = CpuFrequency()

  # On Apple Silicon, we can't get exact frequencies in user mode
  # Set reasonable defaults based on chip family
  let brand = getCpuBrand().toLowerAscii()
  if "apple" in brand:
    if "m1" in brand:
      result.nominal = 3200.0 # M1 base frequency
      result.max = some(3200.0)
      result.min = some(600.0)
    elif "m2" in brand:
      result.nominal = 3500.0 # M2 base frequency
      result.max = some(3500.0)
      result.min = some(600.0)
    else:
      result.nominal = 3200.0 # Default for unknown Apple Silicon
      result.max = some(3200.0)
      result.min = some(600.0)
  else:
    # For Intel CPUs, try to get frequency from sysctl
    try:
      let nominal = getSysctlInt("hw.cpufrequency")
      if nominal <= 0:
        raise newException(DarwinError, "Invalid CPU frequency returned by sysctl")
      result.nominal = nominal.float / 1_000_000 # Convert Hz to MHz

      # Get max frequency if available
      let maxFreq = getSysctlInt("hw.cpufrequency_max")
      if maxFreq > 0:
        result.max = some(maxFreq.float / 1_000_000)

      # Get min frequency if available
      let minFreq = getSysctlInt("hw.cpufrequency_min")
      if minFreq > 0:
        result.min = some(minFreq.float / 1_000_000)
    except DarwinError:
      # If sysctl calls fail on Intel, use brand string to estimate
      if "ghz" in brand:
        for part in brand.split():
          try:
            result.nominal = parseFloat(part) * 1000.0
            break
          except ValueError:
            continue
      if result.nominal <= 0:
        result.nominal = 2400.0 # Default fallback

  # Current frequency is not available in user mode
  # powermetrics could provide this but requires root access
  result.current = none(float)

proc calculateCpuUsage(prev, curr: HostCpuLoadInfo): CpuUsage =
  ## Calculate CPU usage percentages from two consecutive CPU load info samples
  var
    userDiff = 0'f
    systemDiff = 0'f
    idleDiff = 0'f
    niceDiff = 0'f
    totalTicks = 0'f

  # Calculate differences for each CPU state
  for i in 0 .. 3:
    let
      userD = curr.userTicks[i] - prev.userTicks[i]
      systemD = curr.systemTicks[i] - prev.systemTicks[i]
      idleD = curr.idleTicks[i] - prev.idleTicks[i]
      niceD = curr.niceTicks[i] - prev.niceTicks[i]
      total = userD + systemD + idleD + niceD

    if total > 0:
      userDiff += userD.float
      systemDiff += systemD.float
      idleDiff += idleD.float
      niceDiff += niceD.float
      totalTicks += total.float

  # Convert to percentages
  if totalTicks > 0:
    result = CpuUsage(
      user: (userDiff / totalTicks) * 100,
      system: (systemDiff / totalTicks) * 100,
      idle: (idleDiff / totalTicks) * 100,
      nice: (niceDiff / totalTicks) * 100,
      total: ((totalTicks - idleDiff) / totalTicks) * 100
    )
  else:
    # If no ticks have passed, assume the system is idle
    result = CpuUsage(
      user: 0.0,
      system: 0.0,
      idle: 100.0,
      nice: 0.0,
      total: 0.0
    )

var
  lastCpuInfo: HostCpuLoadInfo # Store last CPU info for usage calculation
  isFirstCall = true # Track first call to getCpuUsage

proc getCpuUsage*(): CpuUsage {.raises: [DarwinError].} =
  ## Get current CPU usage information
  ## Returns percentages of time spent in different CPU states
  ## Raises DarwinError if CPU information cannot be retrieved
  let currInfo = getHostCpuLoadInfo()

  if isFirstCall:
    isFirstCall = false
    lastCpuInfo = currInfo
    # On first call, assume system is idle to avoid bogus initial reading
    result = CpuUsage(
      user: 0.0,
      system: 0.0,
      idle: 100.0,
      nice: 0.0,
      total: 0.0
    )
  else:
    result = calculateCpuUsage(lastCpuInfo, currInfo)

  lastCpuInfo = currInfo

proc getCpuInfo*(): CpuInfo =
  ## Returns detailed CPU information for the current system.
  ##
  ## This includes:
  ## * Number of physical and logical CPU cores
  ## * CPU architecture (arm64/x86_64)
  ## * Machine model identifier
  ## * CPU brand string
  ## * Frequency information (nominal, max, min if available)
  ## * Current CPU usage information
  ##
  ## Note: Current CPU frequency is not available in user mode on macOS.
  ## Use powermetrics (requires root) if you need real-time frequency data.
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
    frequency = getFrequencyInfo(),
  )
  result.usage = getCpuUsage()

proc `$`*(usage: CpuUsage): string =
  ## String representation of CPU usage information
  fmt"""CPU Usage:
  User:   {usage.user:.1f}%
  System: {usage.system:.1f}%
  Nice:   {usage.nice:.1f}%
  Idle:   {usage.idle:.1f}%
  Total:  {usage.total:.1f}%"""

proc `$`*(freq: CpuFrequency): string =
  ## String representation of CPU frequency information
  var parts: seq[string] = @[]
  parts.add fmt"Nominal: {freq.nominal:.0f} MHz"

  if freq.current.isSome:
    parts.add fmt"Current: {freq.current.get():.0f} MHz"
  else:
    parts.add "Current: Not available"

  if freq.max.isSome:
    parts.add fmt"Max: {freq.max.get():.0f} MHz"
  if freq.min.isSome:
    parts.add fmt"Min: {freq.min.get():.0f} MHz"

  result = parts.join("\n  ")

proc `$`*(info: CpuInfo): string =
  ## String representation of CPU information
  validateCpuInfo(info) # Validate before creating string representation
  fmt"""CPU Information:
  Architecture: {info.architecture}
  Physical Cores: {info.physicalCores}
  Logical Cores: {info.logicalCores}
  Model: {info.model}
  Brand: {info.brand}
  Frequency:
  {$info.frequency}
{$info.usage}"""

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
  ## Thread-safe: Yes
  result = LoadHistory(
    samples: initDeque[LoadAverage](),
    maxSamples: maxSamples
  )
  initLock(result.lock)

proc add*(history: LoadHistory, load: LoadAverage) =
  ## Adds a load average sample to the history
  ## If the history is full, the oldest sample is removed
  ## Thread-safe: Yes
  validateLoadAverage(load)
  withLock history.lock:
    if history.samples.len >= history.maxSamples:
      discard history.samples.popFirst()
    history.samples.addLast(load)

proc getLoadAverageAsync*(): Future[LoadAverage] {.async.} =
  ## Get the current system load averages asynchronously
  ##
  ## Returns a Future[LoadAverage] containing the 1, 5, and 15 minute
  ## load averages along with the timestamp of measurement.
  ## Load averages represent the number of processes in the run queue
  ## (waiting for CPU time) averaged over the specified time period.
  ##
  ## A load average of 1.0 means the system has exactly enough CPU
  ## capacity to handle the current load. Values > 1.0 indicate
  ## processes are waiting for CPU time.
  ##
  ## Thread-safe: Yes
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

proc startLoadMonitoring*(history: LoadHistory, interval: float = 60.0): Future[void] {.async.} =
  ## Start monitoring load averages at the specified interval
  ## The samples will be added to the provided history object
  ##
  ## Parameters:
  ##   history: LoadHistory object to store samples in
  ##   interval: Time in seconds between samples (default 60.0)
  ##
  ## Thread-safe: Yes
  while true:
    try:
      let load = await getLoadAverageAsync()
      history.add(load)
    except DarwinError as e:
      # Log error but continue monitoring
      echo "Error getting load average: ", e.msg
    await sleepAsync(int(interval * 1000))

proc getPerCoreCpuLoadInfo*(): seq[HostCpuLoadInfo] {.raises: [DarwinError].} =
  ## Retrieves per-core CPU load information using Mach's host_processor_info.
  ## Returns a sequence of HostCpuLoadInfo objects, one per CPU core.
  var cpuInfoPtr: pointer = nil
  var cpuCount: uint32 = 0
  var infoCount: uint32 = 0

  # Use the properly declared host_processor_info from mach_stats
  let kr = host_processor_info(
    mach_host_self(),
    PROCESSOR_CPU_LOAD_INFO.cint,
    addr cpuCount,
    addr cpuInfoPtr,
    addr infoCount
  )

  if kr != KERN_SUCCESS:
    raise newException(DarwinError, "Failed to retrieve per-core CPU load information")

  var results: seq[HostCpuLoadInfo] = @[]

  # Cast the void pointer to an array of uint32 values (the type returned by Mach)
  let infoArr = cast[ptr UncheckedArray[uint32]](cpuInfoPtr)

  # Each core returns 4 integers: user, system, idle, and nice tick counts.
  for i in 0..<int(cpuCount):
    let offset = i * 4
    # No need for .float conversion, we access array directly
    let userVal = infoArr[offset]
    let systemVal = infoArr[offset + 1]
    let idleVal = infoArr[offset + 2]
    let niceVal = infoArr[offset + 3]

    let coreInfo = HostCpuLoadInfo(
      userTicks: [userVal, 0'u32, 0'u32, 0'u32],
      systemTicks: [systemVal, 0'u32, 0'u32, 0'u32],
      idleTicks: [idleVal, 0'u32, 0'u32, 0'u32],
      niceTicks: [niceVal, 0'u32, 0'u32, 0'u32]
    )
    results.add(coreInfo)

  # Free the memory allocated by host_processor_info using vm_deallocate
  # On 64-bit systems, cast directly to uint64
  let totalSize: uint64 = uint64(infoCount) * uint64(sizeof(uint32))
  discard vm_deallocate(mach_host_self(), cast[uint64](cpuInfoPtr), totalSize)

  return results
