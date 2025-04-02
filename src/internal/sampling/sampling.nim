## Unified sampling implementation for Darwin metrics
##
## This module provides a simplified implementation of the metric sampling system,
## using Chronos as the asynchronous backend. It provides high-level functions for
## collecting system metrics at regular intervals.

import std/[options, tables, times, monotimes]
import chronos
import chronos/timer as chronosTimer

import ../[cpu_types, memory_types, disk_types, network_types, process_types, power_types]
import ./core
import ../../system/cpu as system_cpu
import ../../system/disk as system_disk
import ../../system/memory as system_memory
import ../../system/network as system_network
import ../../system/process as system_process
import ../../system/power as system_power

type
  Sampler* = ref object of SamplerBase
    ## Chronos-based metric sampler implementation
    config*: SamplerConfig
    loopFuture: Future[void]
    errorHandler: proc(err: MetricError) {.gcsafe.}

# Time conversion helpers
proc toChronosDuration(d: SamplingDuration): chronosTimer.Duration =
  ## Convert our duration to Chronos duration
  chronosTimer.nanoseconds(inNanoseconds(d))

proc collectMetric(kind: MetricKind): Future[MetricValue] {.async: (raises: [CatchableError]).} =
  ## Collects a single metric value asynchronously.
  ## Returns a MetricValue containing the collected data.
  result = MetricValue(kind: kind, timestamp: getMonoTime().ticks)
  try:
    case kind
    of mkCPU:
      result.cpuInfo = await getCpuMetrics()
      result.cpuInfo.timestamp = result.timestamp
    of mkMemory:
      let memStats = getMemoryMetrics()
      var metrics = memory_types.MemoryMetrics(
        memoryStats: memory_types.MemoryStats(
          totalPhysical: memStats.totalPhysical,
          availablePhysical: memStats.availablePhysical,
          usedPhysical: memStats.usedPhysical,
          pressureLevel: case memStats.pressureLevel
            of system_memory.MemoryPressure.Normal: memory_types.MemoryPressureLevel.mplNormal
            of system_memory.MemoryPressure.Warning: memory_types.MemoryPressureLevel.mplWarning
            of system_memory.MemoryPressure.Critical: memory_types.MemoryPressureLevel.mplCritical
            of system_memory.MemoryPressure.Error: memory_types.MemoryPressureLevel.mplNormal,
          pageSize: memStats.pageSize,
          pagesFree: memStats.pagesFree,
          pagesActive: memStats.pagesActive,
          pagesInactive: memStats.pagesInactive,
          pagesWired: memStats.pagesWired,
          pagesCompressed: memStats.pagesCompressed,
          timestamp: result.timestamp
        ),
        timestamp: result.timestamp
      )
      result.memInfo = metrics
    of mkDisk:
      result.diskInfo = await getDiskMetrics()
      result.diskInfo.timestamp = result.timestamp
    of mkNetwork:
      result.networkInfo = await getNetworkMetrics()
      result.networkInfo.timestamp = result.timestamp
    of mkProcess:
      result.processInfo = await getProcessMetrics()
      result.processInfo.timestamp = result.timestamp
    of mkPower:
      result.powerInfo = getPowerMetrics()
      result.powerInfo.timestamp = result.timestamp
  except CatchableError as e:
    raise newException(CatchableError, "Failed to collect metric: " & e.msg)

proc collectSnapshot(s: Sampler): Future[MetricSnapshot] {.async: (raises: [CatchableError]).} =
  ## Collects a snapshot of all metrics
  var snapshot = MetricSnapshot(timestamp: getMonoTime().ticks)

  # Collect each metric type if enabled
  if mkCPU in s.kinds:
    try:
      let value = await collectMetric(mkCPU)
      snapshot.cpuMetrics = value.cpuInfo
    except CatchableError as e:
      echo "Failed to collect CPU metrics: ", e.msg

  if mkMemory in s.kinds:
    try:
      let value = await collectMetric(mkMemory)
      snapshot.memoryMetrics = value.memInfo
    except CatchableError as e:
      echo "Failed to collect memory metrics: ", e.msg

  if mkDisk in s.kinds:
    try:
      let value = await collectMetric(mkDisk)
      snapshot.diskMetrics = value.diskInfo
    except CatchableError as e:
      echo "Failed to collect disk metrics: ", e.msg

  if mkNetwork in s.kinds:
    try:
      let value = await collectMetric(mkNetwork)
      snapshot.networkMetrics = value.networkInfo
    except CatchableError as e:
      echo "Failed to collect network metrics: ", e.msg

  if mkProcess in s.kinds:
    try:
      let value = await collectMetric(mkProcess)
      snapshot.processMetrics = value.processInfo
    except CatchableError as e:
      echo "Failed to collect process metrics: ", e.msg

  if mkPower in s.kinds:
    try:
      let value = await collectMetric(mkPower)
      snapshot.powerMetrics = value.powerInfo
    except CatchableError as e:
      echo "Failed to collect power metrics: ", e.msg

  return snapshot

proc samplingLoop(s: Sampler) {.async: (raises: [CatchableError]).} =
  while s.running:
    try:
      let snapshot = await collectSnapshot(s)
      try:
        s.snapshots.add(snapshot)
        s.pruneSnapshots()
      except Exception as e:
        raise newException(CatchableError, "Failed to process snapshot: " & e.msg)

      if not s.config.callback.isNil:
        try:
          await s.config.callback(snapshot)
        except CatchableError:
          # Ignore callback errors
          discard
    except CatchableError:
      # Error already handled in collectSnapshot
      discard
    await sleepAsync(toChronosDuration(s.config.interval))

proc newSampler*(config: SamplerConfig,
                errorHandler: proc(err: MetricError) {.gcsafe.} = nil): Sampler =
  ## Create a new metric sampler
  result = Sampler(
    config: config,
    errorHandler: errorHandler,
    kinds: {mkCPU, mkMemory, mkDisk, mkNetwork, mkProcess, mkPower},
    interval: config.interval,
    maxSnapshots: 100,  # Default to keeping 100 snapshots
    snapshots: @[],
    running: false
  )

method start*(s: Sampler): Future[void] {.async: (raises: [CatchableError]).} =
  ## Start the sampling process
  if not s.running:
    s.running = true
    s.loopFuture = samplingLoop(s)

method stop*(s: Sampler): Future[void] {.async: (raises: [CatchableError]).} =
  ## Stop the sampling process
  if s.running:
    s.running = false
    if not s.loopFuture.isNil and not s.loopFuture.finished:
      await s.loopFuture

method isRunning*(s: Sampler): Future[bool] {.async: (raises: [CatchableError]).} =
  ## Check if the sampler is running
  return s.running

method sample*(s: Sampler): Future[void] {.async: (raises: [CatchableError]).} =
  ## Perform a single sample
  if not s.running:
    let snapshot = await collectSnapshot(s)
    try:
      s.snapshots.add(snapshot)
      s.pruneSnapshots()
    except Exception as e:
      raise newException(CatchableError, "Failed to process snapshot: " & e.msg)

    if not s.config.callback.isNil:
      try:
        await s.config.callback(snapshot)
      except CatchableError:
        # Ignore callback errors
        discard
