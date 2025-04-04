## CPU metrics module for Darwin systems
##
## This module provides a high-level async interface for retrieving CPU information
## and metrics on Darwin-based systems (macOS). It supports both Intel and
## Apple Silicon architectures, providing accurate CPU statistics through
## the Mach kernel interfaces.
##
## The module offers async functionality for:
## * CPU information (cores, architecture, model)
## * Real-time CPU usage monitoring
## * Frequency information (where available)
## * Load average tracking
## * Per-core statistics
##
## Example:
##
## ```nim
## import darwinmetrics/system/cpu
## import chronos
##
## proc main() {.async.} =
##   # Get detailed CPU information
##   let info = await getCpuMetrics()
##   echo "CPU: ", info.brand
##   echo "Architecture: ", info.architecture
##   echo "Physical cores: ", info.physicalCores
##
##   # Monitor CPU usage
##   let usage = await getCpuUsage()
##   echo "Total CPU usage: ", usage.total, "%"
##   echo "System: ", usage.system, "%"
##   echo "User: ", usage.user, "%"
##
##   # Track load averages
##   let history = newLoadHistory()
##   let load = await getLoadAverage()
##   echo "1-minute load: ", load.oneMinute
##
##   # Start continuous monitoring
##   let usageHistory = newCpuUsageHistory()
##   asyncCheck startCpuUsageTracking(usageHistory)
##
## waitFor main()
## ```
##
## Integration with Sampling System:
## This module integrates with darwinmetrics' sampling system for automated
## metric collection. See `sampling/metric_collector.nim` for details on
## periodic sampling.
##
## ```nim
## import darwinmetrics/internal/sampling/metric_collector
##
## let collector = newMetricCollector()
## await collector.startPeriodicSampling(seconds(1)) do (snapshot: MetricSnapshot):
##   echo "CPU Usage: ", snapshot.metrics["cpu"].value.cpuValue, "%"
## ```
##
## Note: Some features like current CPU frequency are not available in user mode
## on macOS. Use powermetrics (requires root) for real-time frequency data.

import std/[strformat, strutils, options, times, deques, locks]
import pkg/chronos
import pkg/chronos/timer
import ../internal/[platform_darwin, cpu_types, darwin_errors]
from ../internal/mach_stats import
  HostCpuLoadInfo, HostLoadInfo, KERN_SUCCESS, LOAD_SCALE, PROCESSOR_CPU_LOAD_INFO,
  mach_host_self, host_processor_info, vm_deallocate, getHostLoadInfo, getHostCpuLoadInfo

export cpu_types

const
  DefaultMaxSamples = 60  # Keep 1 hour of samples at 1-minute intervals
  DefaultCpuSamples = 60  # Keep 1 minute of samples at 1-second intervals

type
  LoadHistory* = ref object
    ## Tracks CPU load average history
    samples: Deque[LoadAverage]
    maxSamples: int
    lock: Lock

  CpuStateTracker = object  # Changed to non-ref for GC-safety
    lastInfo: HostCpuLoadInfo
    isFirstCall: bool
    lock: Lock

  CpuUsageHistory* = ref object
    ## Tracks CPU usage history with thread-safe access
    samples: Deque[CpuUsage]
    maxSamples: int
    lock: Lock

  PerCoreHistory* = ref object
    ## Tracks per-core CPU load information history with thread-safe access
    samples: Deque[seq[HostCpuLoadInfo]]
    maxSamples: int
    lock: Lock

var
  cpuState {.threadvar.}: CpuStateTracker
  isInitialized {.threadvar.}: bool

proc initCpuState() {.raises: [].} =
  if not isInitialized:
    cpuState.isFirstCall = true
    initLock(cpuState.lock)
    isInitialized = true

initCpuState()

proc maxSamples*(history: LoadHistory): int =
  ## Returns the maximum number of samples that can be stored in the history
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.maxSamples

proc len*(history: LoadHistory): int =
  ## Returns the current number of samples in the history
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.samples.len

proc validateCpuMetrics*(metrics: CpuMetrics) =
  ## Validates CPU metrics, raising DarwinError for invalid fields
  if metrics.physicalCores <= 0:
    raise newException(DarwinError, "Invalid physical core count")
  if metrics.logicalCores <= 0:
    raise newException(DarwinError, "Invalid logical core count")
  if metrics.architecture.len == 0:
    raise newException(DarwinError, "Missing CPU architecture")
  if metrics.architecture notin ["arm64", "x86_64"]:
    raise newException(DarwinError, "Invalid CPU architecture: " & metrics.architecture)
  if metrics.model.len == 0:
    raise newException(DarwinError, "Missing machine model")
  if metrics.brand.len == 0:
    raise newException(DarwinError, "Missing CPU brand")

proc newCpuMetrics*(
    physicalCores: int,
    logicalCores: int,
    architecture: string,
    model: string,
    brand: string,
    frequency: CpuFrequency,
): CpuMetrics =
  ## Creates a new CpuMetrics instance with validation
  ## Raises DarwinError if any fields are invalid
  result = CpuMetrics(
    physicalCores: physicalCores,
    logicalCores: logicalCores,
    architecture: architecture,
    model: model,
    brand: brand,
    frequency: frequency,
    timestamp: getTime().toUnix * 1_000_000_000
  )
  validateCpuMetrics(result)

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

proc newCpuUsageHistory*(maxSamples: int = DefaultCpuSamples): CpuUsageHistory =
  ## Creates a new CPU usage history tracker
  ## maxSamples determines how many samples to keep (default 60)
  ## Thread-safe: Yes
  result = CpuUsageHistory(
    samples: initDeque[CpuUsage](),
    maxSamples: maxSamples
  )
  initLock(result.lock)

proc add*(history: CpuUsageHistory, usage: CpuUsage) =
  ## Adds a CPU usage sample to the history
  ## If the history is full, the oldest sample is removed
  ## Thread-safe: Yes
  withLock history.lock:
    if history.samples.len >= history.maxSamples:
      discard history.samples.popFirst()
    history.samples.addLast(usage)

proc len*(history: CpuUsageHistory): int =
  ## Returns the number of samples in the history
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.samples.len

proc maxSamples*(history: CpuUsageHistory): int =
  ## Returns the maximum number of samples that can be stored
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.maxSamples

proc getCpuUsage*(): Future[CpuUsage] {.async.} =
  ## Get current CPU usage information asynchronously
  ## Returns percentages of time spent in different CPU states
  ## Thread-safe: Yes
  ## Raises DarwinError if CPU information cannot be retrieved
  let currInfo = getHostCpuLoadInfo()
  var result: CpuUsage

  withLock cpuState.lock:
    if cpuState.isFirstCall:
      cpuState.isFirstCall = false
      cpuState.lastInfo = currInfo
      # On first call, assume system is idle
      result = CpuUsage(
        user: 0.0,
        system: 0.0,
        idle: 100.0,
        nice: 0.0,
        total: 0.0
      )
    else:
      result = calculateCpuUsage(cpuState.lastInfo, currInfo)
    cpuState.lastInfo = currInfo

  return result

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

proc getLoadAverage*(): Future[LoadAverage] {.async.} =
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
    timestamp: getTime()
  )
  validateLoadAverage(result)

proc getCpuMetrics*(): Future[CpuMetrics] {.async.} =
  ## Returns detailed CPU metrics for the current system.
  ##
  ## This includes:
  ## * Number of physical and logical CPU cores
  ## * CPU architecture (arm64/x86_64)
  ## * Machine model identifier
  ## * CPU brand string
  ## * Frequency information (nominal, max, min if available)
  ## * Current CPU usage information
  ## * Load averages
  ##
  ## Note: Current CPU frequency is not available in user mode on macOS.
  ## Use powermetrics (requires root) if you need real-time frequency data.
  ##
  ## Raises:
  ## * DarwinError if system information cannot be retrieved
  ## * DarwinVersionError if running on an unsupported Darwin version

  checkDarwinVersion()

  let cores = getCoreCount()
  result = newCpuMetrics(
    physicalCores = cores.physical,
    logicalCores = cores.logical,
    architecture = getMachineArchitecture(),
    model = getMachineModel(),
    brand = getCpuBrand(),
    frequency = getFrequencyInfo()
  )
  result.usage = await getCpuUsage()
  result.loadAverage = await getLoadAverage()
  result.timestamp = getTime().toUnix * 1_000_000_000

proc `$`*(metrics: CpuMetrics): string =
  ## String representation of CPU metrics
  validateCpuMetrics(metrics)
  fmt"""CPU Information:
  Architecture: {metrics.architecture}
  Physical Cores: {metrics.physicalCores}
  Logical Cores: {metrics.logicalCores}
  Model: {metrics.model}
  Brand: {metrics.brand}
  Frequency:
  {$metrics.frequency}
{$metrics.usage}
{$metrics.loadAverage}"""

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

proc startLoadTracking*(history: LoadHistory, interval = chronos.seconds(60)): Future[void] {.async.} =
  ## Start tracking load averages at the specified interval
  ## Returns a Future that completes when tracking is stopped
  while true:
    let load = await getLoadAverage()
    history.add(load)
    await chronos.sleepAsync(interval)

proc getPerCoreCpuLoadInfo*(): Future[seq[HostCpuLoadInfo]] {.async.} =
  ## Retrieves per-core CPU load information using Mach's host_processor_info
  ## Returns a sequence of HostCpuLoadInfo objects, one per CPU core
  ## Thread-safe: Yes
  ## Raises DarwinError if CPU information cannot be retrieved
  var
    cpuInfoPtr: pointer = nil
    cpuCount: uint32 = 0
    infoCount: uint32 = 0

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

  try:
    # Cast the void pointer to an array of uint32 values
    let infoArr = cast[ptr UncheckedArray[uint32]](cpuInfoPtr)

    # Each core returns 4 integers: user, system, idle, and nice tick counts
    for i in 0..<int(cpuCount):
      let offset = i * 4
      let coreInfo = HostCpuLoadInfo(
        userTicks: [infoArr[offset], 0'u32, 0'u32, 0'u32],
        systemTicks: [infoArr[offset + 1], 0'u32, 0'u32, 0'u32],
        idleTicks: [infoArr[offset + 2], 0'u32, 0'u32, 0'u32],
        niceTicks: [infoArr[offset + 3], 0'u32, 0'u32, 0'u32]
      )
      results.add(coreInfo)
  finally:
    # Ensure memory is deallocated even if processing fails
    if cpuInfoPtr != nil:
      let totalSize: uint64 = uint64(infoCount) * uint64(sizeof(uint32))
      discard vm_deallocate(mach_host_self(), cast[uint64](cpuInfoPtr), totalSize)

  return results

proc startCpuUsageTracking*(history: CpuUsageHistory, interval = chronos.seconds(1)): Future[void] {.async.} =
  ## Start tracking CPU usage at the specified interval
  ## Stores samples in the provided history object
  ## Thread-safe: Yes
  ##
  ## Example:
  ## ```nim
  ## let history = newCpuUsageHistory()
  ## asyncCheck startCpuUsageTracking(history)
  ## ```
  while true:
    let usage = await getCpuUsage()
    history.add(usage)
    await chronos.sleepAsync(interval)

proc newPerCoreHistory*(maxSamples: int = DefaultCpuSamples): PerCoreHistory =
  ## Creates a new per-core CPU load history tracker
  ## maxSamples determines how many samples to keep (default 60)
  ## Thread-safe: Yes
  result = PerCoreHistory(
    samples: initDeque[seq[HostCpuLoadInfo]](),
    maxSamples: maxSamples
  )
  initLock(result.lock)

proc add*(history: PerCoreHistory, info: seq[HostCpuLoadInfo]) =
  ## Adds a per-core CPU load sample to the history
  ## If the history is full, the oldest sample is removed
  ## Thread-safe: Yes
  withLock history.lock:
    if history.samples.len >= history.maxSamples:
      discard history.samples.popFirst()
    history.samples.addLast(info)

proc len*(history: PerCoreHistory): int =
  ## Returns the number of samples in the history
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.samples.len

proc maxSamples*(history: PerCoreHistory): int =
  ## Returns the maximum number of samples that can be stored
  ## Thread-safe: Yes
  withLock history.lock:
    result = history.maxSamples

proc startPerCoreTracking*(history: PerCoreHistory, interval = chronos.seconds(1)): Future[void] {.async.} =
  ## Start tracking per-core CPU load information at the specified interval
  ## Stores samples in the provided history object
  ## Thread-safe: Yes
  ##
  ## Example:
  ## ```nim
  ## let history = newPerCoreHistory()
  ## asyncCheck startPerCoreTracking(history)
  ## ```
  while true:
    let info = await getPerCoreCpuLoadInfo()
    history.add(info)
    await chronos.sleepAsync(interval)
