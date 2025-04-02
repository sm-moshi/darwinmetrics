## Core types and interfaces for metric sampling.
##
## This module provides the fundamental types and interfaces used by both
## async backend implementations (chronos and stdlib) without importing
## any backend-specific code.

import std/options
import pkg/chronos
import pkg/chronos/futures
import ../[cpu_types, memory_types, disk_types, network_types, process_types, power_types]
import ../../system/[
  cpu,
  disk,
  memory,
  network,
  process,
  power
]

type
  SamplingDuration* = distinct int64
    ## Platform-agnostic duration type using nanoseconds
    ## This allows us to avoid importing either backend's time library

  MetricKind* = enum
    ## Supported metric types for sampling
    mkCPU = "cpu"          ## CPU metrics (usage, frequency, etc.)
    mkMemory = "memory"    ## Memory metrics (usage, pressure, etc.)
    mkDisk = "disk"        ## Disk metrics (IO, space, etc.)
    mkNetwork = "network"  ## Network metrics (bandwidth, etc.)
    mkProcess = "process"  ## Process metrics (count, resources, etc.)
    mkPower = "power"      ## Power metrics (battery, etc.)

  UniversalTime* = int64
    ## Platform-agnostic timestamp (nanoseconds since Unix epoch)
    ## Used to avoid depending on std/times or chronos/timer

  MetricValue* = object
    ## A variant object holding any type of metric data
    timestamp*: UniversalTime  ## When the metric was collected
    case kind*: MetricKind
    of mkCPU: cpuInfo*: CPUMetrics
    of mkMemory: memInfo*: memory_types.MemoryMetrics
    of mkDisk: diskInfo*: DiskMetrics
    of mkNetwork: networkInfo*: NetworkMetrics
    of mkProcess: processInfo*: ProcessMetrics
    of mkPower: powerInfo*: power_types.PowerMetrics

  MetricSnapshot* = ref object
    ## A point-in-time collection of all metrics
    timestamp*: int64              ## Unix timestamp in nanoseconds
    cpuMetrics*: CPUMetrics       ## CPU usage and stats
    memoryMetrics*: memory_types.MemoryMetrics ## Memory usage and stats
    diskMetrics*: DiskMetrics     ## Disk usage and IO stats
    networkMetrics*: NetworkMetrics ## Network interface stats
    processMetrics*: ProcessMetrics ## Process stats
    powerMetrics*: power_types.PowerMetrics ## Power stats

  MetricCallback* = proc(snapshot: MetricSnapshot): Future[void] {.closure, gcsafe, raises: [CatchableError].}
    ## Callback type for handling collected metrics

  SamplerConfig* = ref object
    ## Configuration for metric samplers
    interval*: SamplingDuration    ## How often to sample metrics
    callback*: MetricCallback      ## Optional callback for handling metrics

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
    timestamp*: UniversalTime  ## When the error occurred

  SamplerBase* = ref object of RootObj
    ## Base type for metric samplers, backend-agnostic
    kinds*: set[MetricKind]         ## Which metrics to collect
    interval*: SamplingDuration     ## How often to sample
    snapshots*: seq[MetricSnapshot] ## Historical snapshots (if enabled)
    maxSnapshots*: int              ## Maximum snapshots to retain (0 = unlimited)
    running*: bool                  ## Whether sampling is active

# Helper functions for duration
proc seconds*(value: int64): SamplingDuration {.inline.} =
  ## Create a duration from seconds
  SamplingDuration(value * 1_000_000_000)

proc milliseconds*(value: int64): SamplingDuration {.inline.} =
  ## Create a duration from milliseconds
  SamplingDuration(value * 1_000_000)

proc microseconds*(value: int64): SamplingDuration {.inline.} =
  ## Create a duration from microseconds
  SamplingDuration(value * 1_000)

proc nanoseconds*(value: int64): SamplingDuration {.inline.} =
  ## Create a duration from nanoseconds
  SamplingDuration(value)

proc inSeconds*(duration: SamplingDuration): int64 {.inline.} =
  ## Get the duration in seconds
  int64(duration) div 1_000_000_000

proc inMilliseconds*(duration: SamplingDuration): int64 {.inline.} =
  ## Get the duration in milliseconds
  int64(duration) div 1_000_000

proc inMicroseconds*(duration: SamplingDuration): int64 {.inline.} =
  ## Get the duration in microseconds
  int64(duration) div 1_000

proc inNanoseconds*(duration: SamplingDuration): int64 {.inline.} =
  ## Get the duration in nanoseconds
  int64(duration)

proc newMetricError*(kind: MetricErrorKind, msg: string, source: MetricKind,
                    timestamp: UniversalTime): MetricError =
  ## Creates a new metric error with timestamp
  MetricError(
    kind: kind,
    msg: msg,
    source: source,
    timestamp: timestamp
  )

proc pruneSnapshots*(sampler: SamplerBase) =
  ## Removes old snapshots if we're over the limit
  if sampler.maxSnapshots > 0 and sampler.snapshots.len > sampler.maxSnapshots:
    let deleteCount = sampler.snapshots.len - sampler.maxSnapshots
    for i in 0 ..< deleteCount:
      sampler.snapshots.delete(0)

proc latestSnapshot*(sampler: SamplerBase): Option[MetricSnapshot] =
  ## Returns the most recent snapshot if available
  if sampler.snapshots.len > 0:
    some(sampler.snapshots[^1])
  else:
    none(MetricSnapshot)

# Interface definition (backends must implement these)
method start*(sampler: SamplerBase): Future[void] {.base.} =
  ## Starts the sampler
  ## Backend implementations must override this
  return newFuture[void]("SamplerBase.start")

method stop*(sampler: SamplerBase): Future[void] {.base.} =
  ## Stops the sampler
  ## Backend implementations must override this
  return newFuture[void]("SamplerBase.stop")

method sample*(sampler: SamplerBase): Future[void] {.base.} =
  ## Performs a single sample
  ## Backend implementations must override this
  return newFuture[void]("SamplerBase.sample")

method isRunning*(sampler: SamplerBase): Future[bool] {.base, async: (raises: [CatchableError]).} =
  ## Checks if the sampler is running
  ## Backend implementations must override this
  result = false

proc newSamplerConfig*(interval: SamplingDuration, callback: MetricCallback = nil): SamplerConfig =
  ## Creates a new sampler configuration
  SamplerConfig(
    interval: interval,
    callback: callback
  )

