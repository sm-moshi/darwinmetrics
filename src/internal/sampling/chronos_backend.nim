## Chronos-based metric sampler implementation.
##
## This module provides a Chronos-based implementation of the metric sampler
## that leverages async/await for efficient concurrent metric collection.
## It implements the core sampling interface defined in core.nim using
## the Chronos async framework.

import std/[options, strutils, times]
import pkg/chronos
import pkg/chronos/timer
import chronos/futures as chronosFutures
import ../[cpu_types, memory_types, disk_types, network_types, process_types]
import ./core
import ../../system/[
  cpu,
  disk,
  memory,
  network,
  process
]
import ../mach_stats
import ../mach_power
import ../polling

const DefaultTimeout = chronos.seconds(5) # Default timeout for metric collection

type
  ChronosMetricError* = ref object of CatchableError
    metricError*: MetricError

  ChronosSampler* = ref object of SamplerBase
    timer: Future[void]
    config*: SamplerConfig
    lastError*: Option[MetricError]

proc getMetricKind(e: ref Exception): MetricKind =
  ## Helper to extract MetricKind from error context
  if e of ValueError:
    for kind in MetricKind:
      if e.msg.find($kind) >= 0:
        return kind
  low(MetricKind)  # Default if not found

proc toChronosDuration(duration: SamplingDuration): chronos.Duration =
  ## Convert from SamplingDuration to chronos Duration
  chronos.nanoseconds(inNanoseconds(duration))

proc raiseMetricError(error: MetricError) =
  var e = new ChronosMetricError
  e.msg = error.msg
  e.metricError = error
  raise e

proc getCurrentUniversalTime(): UniversalTime =
  ## Get current time as UniversalTime (nanoseconds since Unix epoch)
  getTime().toUnix * 1_000_000_000'i64

proc collectMetric(kind: MetricKind): Future[MetricValue] {.async.} =
  let timestamp = getCurrentUniversalTime()
  try:
    case kind
    of mkCPU:
      let info = cpu.getCpuMetrics()
      result = MetricValue(kind: mkCPU, timestamp: timestamp, cpuInfo: info)
    of mkMemory:
      let info = memory.getMemoryMetrics()
      result = MetricValue(kind: mkMemory, timestamp: timestamp, memInfo: info)
    of mkDisk:
      let info = disk.getDiskMetrics()
      result = MetricValue(kind: mkDisk, timestamp: timestamp, diskMetrics: info)
    of mkNetwork:
      let info = network.getNetworkMetrics()
      result = MetricValue(kind: mkNetwork, timestamp: timestamp, networkInfo: info)
    of mkProcess:
      let info = process.getProcessMetrics()
      result = MetricValue(kind: mkProcess, timestamp: timestamp, processInfo: info)
  except CatchableError as e:
    raiseMetricError(newMetricError(meCollection, e.msg, kind, timestamp))

proc collectSnapshot(sampler: ChronosSampler): Future[MetricSnapshot] {.async.} =
  ## Collects a snapshot of all enabled metrics.
  ## May raise ChronosMetricError or CatchableError if collection fails.
  if not sampler.running:
    return

  let timestamp = getCurrentUniversalTime()
  var snapshot = MetricSnapshot(timestamp: timestamp)

  try:
    # Collect metrics individually to avoid type issues
    try:
      let cpuMetric = await collectMetric(mkCPU)
      snapshot.cpuMetrics = cpuMetric.cpuInfo

      let memoryMetric = await collectMetric(mkMemory)
      snapshot.memoryMetrics = memoryMetric.memInfo

      let diskMetric = await collectMetric(mkDisk)
      snapshot.diskMetrics = diskMetric.diskInfo

      let networkMetric = await collectMetric(mkNetwork)
      snapshot.networkMetrics = networkMetric.networkInfo

      let processMetric = await collectMetric(mkProcess)
      snapshot.processMetrics = processMetric.processInfo
    except CatchableError as e:
      raiseMetricError(newMetricError(meCollection, "Failed to collect metrics: " & e.msg, mkCPU, timestamp))

    if sampler.maxSnapshots > 0:
      sampler.snapshots.add(snapshot)
      sampler.pruneSnapshots()

    if not sampler.config.callback.isNil:
      try:
        let callbackFut = sampler.config.callback(snapshot)
        await callbackFut
      except CatchableError as e:
        sampler.lastError = some(newMetricError(meCollection, "Callback failed: " & e.msg, mkCPU, timestamp))

    sampler.lastError = none(MetricError)
    result = snapshot

  except ChronosMetricError as e:
    sampler.lastError = some(e.metricError)
    raise e
  except CatchableError as e:
    let error = newMetricError(meCollection, e.msg, mkCPU, timestamp)
    sampler.lastError = some(error)
    raiseMetricError(error)

proc samplingLoop(sampler: ChronosSampler) {.async.} =
  while sampler.running:
    try:
      discard await sampler.collectSnapshot()
    except CatchableError:
      # Error already handled in collectSnapshot
      discard
    await chronos.sleepAsync(toChronosDuration(sampler.config.interval))

proc newChronosSampler*(config: SamplerConfig): ChronosSampler =
  new(result)
  result.config = config
  result.running = false
  result.maxSnapshots = 100  # Default to keeping last 100 snapshots
  result.lastError = none(MetricError)
  result.kinds = {mkCPU, mkMemory, mkDisk, mkNetwork, mkProcess}  # Enable all metrics by default
  result.interval = config.interval
  result.snapshots = @[]

method start*(sampler: ChronosSampler): Future[void] {.async.} =
  if not sampler.running:
    sampler.running = true
    sampler.timer = samplingLoop(sampler)

method stop*(sampler: ChronosSampler): Future[void] {.async.} =
  sampler.running = false
  if not sampler.timer.isNil:
    await sampler.timer.cancelAndWait()

method isRunning*(sampler: ChronosSampler): bool =
  sampler.running

proc getLastError*(sampler: ChronosSampler): Option[MetricError] =
  sampler.lastError

proc getLastSnapshot*(sampler: ChronosSampler): Option[MetricSnapshot] =
  if sampler.snapshots.len > 0:
    some(sampler.snapshots[^1])
  else:
    none(MetricSnapshot)
