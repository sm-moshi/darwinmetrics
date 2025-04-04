## Metric collection implementation.
##
## This module provides the core metric collection functionality, supporting
## async collection of various system metrics with error handling and timeouts.
##
## Example:
## .. code-block:: nim
##   let collector = newMetricCollector()
##   let cpuResult = await collector.collectCpu()
##   let memResult = await collector.collectMemory()
##
##   # Start periodic sampling
##   await collector.startPeriodicSampling(milliseconds(500)) do (snapshot: MetricSnapshot):
##     echo "CPU Usage: ", snapshot.metrics["cpu"].value.cpuValue, "%"

import std/[options, tables]
import chronos
import chronos/timer
import ./types
import ../../system/cpu
import ../../system/memory
import ../../system/disk
import ../../system/network
import ../../system/power
import ../../system/process

type
  MetricCollector* = ref object ## \
    ## Collects system metrics asynchronously.
    timeout*: SamplingDuration ## Maximum time to wait for collection
    isRunning: bool           ## Whether periodic sampling is active
    samplingFuture: Future[void] ## Current sampling task

proc newMetricCollector*(timeout: SamplingDuration = types.seconds(5)): MetricCollector =
  ## Creates a new metric collector.
  ##
  ## Parameters:
  ## - timeout: Maximum time to wait for collection (default: 5 seconds)
  ##
  ## Returns: A new MetricCollector instance
  MetricCollector(timeout: timeout)

proc collectCpu*(collector: MetricCollector): Future[MetricResult] {.async.} =
  ## Collects CPU metrics asynchronously.
  ##
  ## Returns: A MetricResult containing CPU usage information
  let startTime = now()
  try:
    let cpuMetrics = getCpuMetrics()
    let usage = getCpuUsage()
    result = newMetricResult(MetricValue(
      kind: mkCPU,
      cpuValue: usage.total
    ))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkCPU, cpuValue: 0.0))
    result.error = some(e.msg)

proc collectMemory*(collector: MetricCollector): Future[MetricResult] {.async.} =
  ## Collects memory metrics asynchronously.
  ##
  ## Returns: A MetricResult containing memory usage information
  let startTime = now()
  try:
    let memMetrics = getMemoryMetrics()
    result = newMetricResult(MetricValue(
      kind: mkMemory,
      memoryBytes: memMetrics.usedPhysical
    ))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkMemory, memoryBytes: 0'u64))
    result.error = some(e.msg)

proc collectDisk*(collector: MetricCollector): Future[MetricResult] {.async.} =
  ## Collects disk metrics asynchronously.
  ##
  ## Returns: A MetricResult containing disk usage information
  let startTime = now()
  try:
    # TODO: Implement disk metrics collection
    result = newMetricResult(MetricValue(kind: mkDisk, diskBytes: 0'u64))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkDisk, diskBytes: 0'u64))
    result.error = some(e.msg)

proc collectNetwork*(collector: MetricCollector): Future[MetricResult] {.async.} =
  ## Collects network metrics asynchronously.
  ##
  ## Returns: A MetricResult containing network usage information
  let startTime = now()
  try:
    # TODO: Implement network metrics collection
    result = newMetricResult(MetricValue(kind: mkNetwork, networkBytes: 0'u64))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkNetwork, networkBytes: 0'u64))
    result.error = some(e.msg)

proc collectPower*(collector: MetricCollector): Future[MetricResult] {.async.} =
  ## Collects power metrics asynchronously.
  ##
  ## Returns: A MetricResult containing power usage information
  let startTime = now()
  try:
    let powerMetrics = getPowerMetrics()
    # For now, we'll use the battery percentage as a proxy for power
    # since we don't have direct wattage measurements
    result = newMetricResult(MetricValue(
      kind: mkPower,
      powerWatts: powerMetrics.percentRemaining
    ))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkPower, powerWatts: 0.0))
    result.error = some(e.msg)

proc collectProcess*(collector: MetricCollector, pid: int32): Future[MetricResult] {.async.} =
  ## Collects process metrics asynchronously.
  ##
  ## Parameters:
  ## - pid: Process ID to collect metrics for
  ##
  ## Returns: A MetricResult containing process information
  let startTime = now()
  try:
    # TODO: Implement process metrics collection
    result = newMetricResult(MetricValue(kind: mkProcess, pid: pid))
  except CatchableError as e:
    result = newMetricResult(MetricValue(kind: mkProcess, pid: pid))
    result.error = some(e.msg)

proc collectAll*(collector: MetricCollector): Future[MetricSnapshot] {.async.} =
  ## Collects all available metrics asynchronously.
  ##
  ## Returns: A MetricSnapshot containing all collected metrics
  let startTime = now()
  var snapshot = newMetricSnapshot(startTime)

  try:
    # Collect all metrics in parallel
    let futures = @[
      collector.collectCpu(),
      collector.collectMemory(),
      collector.collectPower()
    ]

    let results = await all(futures)
    snapshot.metrics["cpu"] = results[0]
    snapshot.metrics["memory"] = results[1]
    snapshot.metrics["power"] = results[2]

  except CatchableError as e:
    snapshot.error = some(e.msg)

  return snapshot

proc stopSampling*(collector: MetricCollector) {.async.} =
  ## Stops periodic sampling if it's running.
  if collector.isRunning and not collector.samplingFuture.isNil:
    collector.isRunning = false
    await collector.samplingFuture
    collector.samplingFuture = nil

proc startPeriodicSampling*(collector: MetricCollector,
                           interval: SamplingDuration,
                           callback: proc(snapshot: MetricSnapshot) {.closure, gcsafe.}): Future[void] {.async.} =
  ## Starts periodic sampling of all metrics at the specified interval.
  ##
  ## Parameters:
  ## - interval: How often to collect metrics
  ## - callback: Function to call with each snapshot
  ##
  ## Example:
  ## .. code-block:: nim
  ##   await collector.startPeriodicSampling(seconds(1)) do (snapshot: MetricSnapshot):
  ##     echo "CPU: ", snapshot.metrics["cpu"].value.cpuValue, "%"
  ##     echo "Memory: ", snapshot.metrics["memory"].value.memoryBytes div MB, " MB"

  if collector.isRunning:
    await collector.stopSampling()

  collector.isRunning = true
  collector.samplingFuture = newFuture[void]("periodicSampling")

  try:
    while collector.isRunning:
      let snapshot = await collector.collectAll()
      try:
        callback(snapshot)
      except CatchableError as e:
        # Log callback error but continue sampling
        snapshot.error = some(e.msg)

      # Wait for next interval using chronos timer
      await sleepAsync(interval.toChronosDuration)

  except CatchableError as e:
    if collector.samplingFuture != nil:
      collector.samplingFuture.fail(e)
  finally:
    collector.isRunning = false
    if collector.samplingFuture != nil:
      collector.samplingFuture.complete()

proc isSampling*(collector: MetricCollector): bool =
  ## Returns whether periodic sampling is currently active.
  collector.isRunning
