## Async metric sampling infrastructure for darwinmetrics.
##
## This module provides types and procedures for periodic sampling of system metrics
## with proper async support and cancellation handling.

import std/[times, options]
when defined(useChronos):
  import chronos
  import chronos/timer
else:
  {.error: "This module requires -d:useChronos".}

import os
import stew/base10
import stew/endians2
import results
import ./cpu
import ./memory
import ./power
import ./disk
import ./network
import ./process

type
  MetricKind* = enum
    ## Supported metric types for sampling
    mkCPU = "cpu"          ## CPU metrics (usage, frequency, etc.)
    mkMemory = "memory"    ## Memory metrics (usage, pressure, etc.)
    mkPower = "power"      ## Power metrics (battery, charging, etc.)
    mkDisk = "disk"        ## Disk metrics (IO, space, etc.)
    mkNetwork = "network"  ## Network metrics (bandwidth, etc.)
    mkProcess = "process"  ## Process metrics (count, resources, etc.)

  MetricValue* = object
    ## A variant object holding any type of metric data
    timestamp*: Time       ## When the metric was collected
    case kind*: MetricKind
    of mkCPU: cpuInfo*: CpuInfo
    of mkMemory: memInfo*: MemoryStats  # Using existing MemoryStats type
    of mkPower: powerInfo*: PowerInfo
    of mkDisk: diskInfo*: DiskInfo
    of mkNetwork: networkInfo*: NetworkInfo
    of mkProcess: processInfo*: ProcessInfo

  MetricSnapshot* = ref object
    ## A point-in-time collection of multiple metrics
    timestamp*: Time                ## When the snapshot was taken
    values*: seq[MetricValue]       ## Successfully collected metrics
    errors*: seq[MetricError]       ## Any collection errors

  MetricSampler* = ref object
    ## Manages periodic collection of system metrics
    kinds*: set[MetricKind]         ## Which metrics to collect
    interval*: times.Duration       ## How often to sample
    snapshots*: seq[MetricSnapshot] ## Historical snapshots (if enabled)
    maxSnapshots*: int             ## Maximum snapshots to retain (0 = unlimited)
    cancelFut: Future[void]        ## For clean shutdown
    running: bool                  ## Whether sampling is active

  MetricErrorKind* = enum
    ## Types of errors that can occur during metric collection
    meCollection     ## Failed to collect the metric
    meTimeout        ## Collection took too long
    meCancellation   ## Collection was cancelled
    meResource       ## System resource issue

  MetricError* = ref object
    ## Detailed error information for failed metric collection
    kind*: MetricErrorKind  ## What type of error occurred
    msg*: string           ## Human-readable error description
    source*: MetricKind    ## Which metric caused the error
    timestamp*: Time       ## When the error occurred

proc newMetricError*(kind: MetricErrorKind, msg: string, source: MetricKind): MetricError =
  ## Creates a new metric error with current timestamp
  MetricError(
    kind: kind,
    msg: msg,
    source: source,
    timestamp: getTime()
  )

proc collectMetric(kind: MetricKind): Future[MetricValue] {.async.} =
  ## Collects a single metric asynchronously
  var value = MetricValue(kind: kind, timestamp: getTime())
  try:
    case kind
    of mkCPU:
      value.cpuInfo = getCpuInfo()  # Non-async function
    of mkMemory:
      value.memInfo = getMemoryStats()  # Non-async function
    of mkPower:
      value.powerInfo = getPowerInfo()  # Non-async function
    of mkDisk:
      value.diskInfo = getDiskInfo()  # Non-async function
    of mkNetwork:
      value.networkInfo = getNetworkInfo()  # Non-async function
    of mkProcess:
      value.processInfo = getProcessInfo()  # Non-async function
    return value
  except CatchableError as e:
    raise newException(ValueError, "Failed to collect " & $kind & ": " & e.msg)

## Metric sampling interface.
##
## This module provides a unified interface for collecting system metrics
## asynchronously using either the Chronos or standard library async backend.
## The backend is selected at compile time using the `-d:useChronos` flag.

import ../internal/sampling_core
export sampling_core

when defined(useChronos):
  import ../internal/sampling_chronos
  export sampling_chronos
  type MetricSamplerImpl* = ChronosSampler
else:
  import ../internal/sampling_stdlib
  export sampling_stdlib
  type MetricSamplerImpl* = StdlibSampler

proc newMetricSampler*(kinds: set[MetricKind] = {low(MetricKind)..high(MetricKind)},
                      interval = chronos.seconds(1),
                      maxSnapshots: int = 0): MetricSamplerImpl =
  ## Creates a new metric sampler using the configured async backend.
  ## The backend is selected at compile time using the `-d:useChronos` flag.
  ##
  ## Args:
  ##   kinds: Set of metrics to collect
  ##   interval: How often to collect metrics
  ##   maxSnapshots: Maximum number of snapshots to retain (0 = unlimited)
  when defined(useChronos):
    newChronosSampler(kinds, interval, maxSnapshots)
  else:
    newStdlibSampler(kinds, interval, maxSnapshots)

proc pruneSnapshots(sampler: MetricSampler) =
  ## Removes old snapshots if we're over the limit
  if sampler.maxSnapshots > 0 and sampler.snapshots.len > sampler.maxSnapshots:
    sampler.snapshots.delete(0 ..< sampler.snapshots.len - sampler.maxSnapshots)

proc collectSnapshot(sampler: MetricSampler): Future[MetricSnapshot] {.async.} =
  ## Collects all configured metrics in parallel
  var snapshot = MetricSnapshot(
    timestamp: getTime(),
    values: @[],
    errors: @[]
  )

  var futures: seq[Future[MetricValue]]
  for kind in sampler.kinds:
    futures.add(collectMetric(kind))

  try:
    let values = await allFutures(futures)
    snapshot.values = values
  except CatchableError as e:
    snapshot.errors.add(newMetricError(meCollection, e.msg, mkCPU))

  return snapshot

proc start*(sampler: MetricSampler) {.async.} =
  ## Starts periodic metric collection
  if sampler.running:
    return

  sampler.running = true
  sampler.cancelFut = newFuture[void]("MetricSampler.stop")

  try:
    while not sampler.cancelFut.finished:
      let snapshot = await sampler.collectSnapshot()
      sampler.snapshots.add(snapshot)
      sampler.pruneSnapshots()
      await sleepAsync(sampler.interval.milliseconds)
  except CancelledError:
    # Normal cancellation, clean up
    sampler.running = false
  except CatchableError as e:
    # Unexpected error
    sampler.running = false
    raise e

proc stop*(sampler: MetricSampler) {.async.} =
  ## Stops metric collection gracefully
  if not sampler.running:
    return

  sampler.cancelFut.complete()
  sampler.running = false

proc isRunning*(sampler: MetricSampler): bool =
  ## Returns whether the sampler is currently collecting metrics
  sampler.running

proc latestSnapshot*(sampler: MetricSampler): Option[MetricSnapshot] =
  ## Returns the most recent snapshot if available
  if sampler.snapshots.len > 0:
    some(sampler.snapshots[^1])
  else:
    none(MetricSnapshot)
