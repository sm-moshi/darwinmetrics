## Core types for metric sampling.
##
## This module provides the fundamental types and interfaces used by both
## async backend implementations (chronos and stdlib) without importing
## any backend-specific code.
##
## Example:
##
## .. code-block:: nim
##   let interval = milliseconds(500)
##   let config = newSamplerConfig(interval)
##   let sampler = newChronosSampler(config)
##   await sampler.start()

import std/[times, options, tables]
import chronos/timer
import chronos

type
  SamplingDuration* = distinct int64 ## \
    ## Platform-agnostic duration type using nanoseconds.
    ## This allows us to avoid importing either backend's time library.
    ##
    ## See also:
    ## * `milliseconds proc<#milliseconds,int64>`_
    ## * `seconds proc<#seconds,int64>`_

  UniversalTime* = distinct int64 ## \
    ## Platform-agnostic timestamp (nanoseconds since Unix epoch).
    ## Used to avoid depending on std/times or chronos/timer.

  ChronosCallback* = proc(): Future[void] {.async, closure, gcsafe.} ## \
    ## Callback type for timer ticks.

  MetricCallback* = proc(timestamp: UniversalTime): Future[void] {.closure, gcsafe, raises: [CatchableError].} ## \
    ## Callback type for handling collected metrics.

  SamplerConfig* = ref object ## \
    ## Configuration for metric samplers.
    interval*: SamplingDuration  ## How often to sample metrics
    callback*: MetricCallback    ## Optional callback for handling metrics

  MetricKind* = enum ## \
    ## Type of metric being collected
    mkCPU        ## CPU usage metrics
    mkMemory     ## Memory usage metrics
    mkDisk       ## Disk usage metrics
    mkNetwork    ## Network usage metrics
    mkPower      ## Power usage metrics
    mkProcess    ## Process metrics

  MetricValue* = object ## \
    ## Variant type to hold different metric values.
    case kind*: MetricKind
    of mkCPU: cpuValue*: float64
    of mkMemory: memoryBytes*: uint64
    of mkDisk: diskBytes*: uint64
    of mkNetwork: networkBytes*: uint64
    of mkPower: powerWatts*: float64
    of mkProcess: pid*: int32

  MetricResult* = ref object ## \
    ## A single metric measurement result.
    ##
    ## Example:
    ## .. code-block:: nim
    ##   let result = MetricResult(
    ##     timestamp: now(),
    ##     value: MetricValue(kind: mkCPU, cpuValue: 0.75),
    ##     error: none(string)
    ##   )
    timestamp*: UniversalTime  ## When the metric was collected
    value*: MetricValue       ## The metric value
    error*: Option[string]    ## Any error that occurred during collection

  MetricSnapshot* = ref object ## \
    ## A collection of metrics taken at a specific time.
    ##
    ## Example:
    ## .. code-block:: nim
    ##   var snapshot = MetricSnapshot(
    ##     timestamp: now(),
    ##     metrics: initTable[string, MetricResult]()
    ##   )
    ##   snapshot.metrics["cpu"] = cpuResult
    ##   snapshot.metrics["memory"] = memoryResult
    timestamp*: UniversalTime                    ## When the snapshot was taken
    metrics*: Table[string, MetricResult]        ## Collection of metrics
    error*: Option[string]                       ## Any collection-wide errors

# Duration helpers
proc nanoseconds*(value: int64): SamplingDuration {.inline, raises: [].} =
  ## Create a duration from nanoseconds.
  ##
  ## .. code-block:: nim
  ##   let dur = nanoseconds(1_000_000) # 1ms
  SamplingDuration(value)

proc microseconds*(value: int64): SamplingDuration {.inline, raises: [].} =
  ## Create a duration from microseconds.
  ##
  ## .. code-block:: nim
  ##   let dur = microseconds(1_000) # 1ms
  nanoseconds(value * 1_000)

proc milliseconds*(value: int64): SamplingDuration {.inline, raises: [].} =
  ## Create a duration from milliseconds.
  ##
  ## .. code-block:: nim
  ##   let dur = milliseconds(500) # 500ms
  nanoseconds(value * 1_000_000)

proc seconds*(value: int64): SamplingDuration {.inline, raises: [].} =
  ## Create a duration from seconds.
  ##
  ## .. code-block:: nim
  ##   let dur = seconds(1) # 1s
  milliseconds(value * 1_000)

# Duration accessors
proc inNanoseconds*(duration: SamplingDuration): int64 {.inline, raises: [].} =
  ## Get the duration in nanoseconds.
  int64(duration)

proc inMicroseconds*(duration: SamplingDuration): int64 {.inline, raises: [].} =
  ## Get the duration in microseconds.
  inNanoseconds(duration) div 1_000

proc inMilliseconds*(duration: SamplingDuration): int64 {.inline, raises: [].} =
  ## Get the duration in milliseconds.
  inNanoseconds(duration) div 1_000_000

proc inSeconds*(duration: SamplingDuration): int64 {.inline, raises: [].} =
  ## Get the duration in seconds.
  inNanoseconds(duration) div 1_000_000_000

# Time helpers
proc now*(): UniversalTime {.inline, raises: [].} =
  ## Get the current time as UniversalTime.
  UniversalTime(times.getTime().toUnix * 1_000_000_000)

proc `$`*(duration: SamplingDuration): string =
  ## String representation of a duration.
  let ns = inNanoseconds(duration)
  if ns mod 1_000_000_000 == 0:
    $inSeconds(duration) & "s"
  elif ns mod 1_000_000 == 0:
    $inMilliseconds(duration) & "ms"
  elif ns mod 1_000 == 0:
    $inMicroseconds(duration) & "µs"
  else:
    $ns & "ns"

proc `$`*(time: UniversalTime): string =
  ## String representation of a timestamp.
  $times.fromUnix(int64(time) div 1_000_000_000)

# Chronos integration
when defined(useChronos):
  proc toChronosDuration*(duration: SamplingDuration): timer.Duration {.inline.} =
    ## Convert a SamplingDuration to a Chronos Duration.
    timer.milliseconds(inMilliseconds(duration))

  proc fromChronosDuration*(duration: timer.Duration): SamplingDuration {.inline.} =
    ## Convert a Chronos Duration to a SamplingDuration.
    nanoseconds(int64(duration.nanoseconds))

proc newSamplerConfig*(interval: SamplingDuration; callback: MetricCallback = nil): SamplerConfig =
  ## Creates a new sampler configuration.
  ##
  ## Parameters:
  ## - interval: How often to sample metrics
  ## - callback: Optional callback for handling metrics
  ##
  ## Returns: A new SamplerConfig instance
  SamplerConfig(
    interval: interval,
    callback: callback
  )

proc newMetricResult*(value: MetricValue, timestamp: UniversalTime = now()): MetricResult =
  ## Creates a new metric result.
  ##
  ## Parameters:
  ## - value: The metric value to store
  ## - timestamp: When the metric was collected (defaults to now)
  ##
  ## Returns: A new MetricResult instance
  ##
  ## Example:
  ## .. code-block:: nim
  ##   let value = MetricValue(kind: mkCPU, cpuValue: 0.75)
  ##   let result = newMetricResult(value)
  MetricResult(
    timestamp: timestamp,
    value: value,
    error: none(string)
  )

proc newMetricSnapshot*(timestamp: UniversalTime = now()): MetricSnapshot =
  ## Creates a new metric snapshot.
  ##
  ## Parameters:
  ## - timestamp: When the snapshot was taken (defaults to now)
  ##
  ## Returns: A new MetricSnapshot instance with an empty metrics table
  ##
  ## Example:
  ## .. code-block:: nim
  ##   let snapshot = newMetricSnapshot()
  ##   snapshot.metrics["cpu"] = cpuResult
  MetricSnapshot(
    timestamp: timestamp,
    metrics: initTable[string, MetricResult](),
    error: none(string)
  )
