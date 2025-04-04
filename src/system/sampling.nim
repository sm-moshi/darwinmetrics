## Async metric sampling infrastructure for darwinmetrics.
##
## This module provides types and procedures for periodic sampling of system metrics
## with proper async support and cancellation handling.

import std/[options, times]
import pkg/chronos
import pkg/chronos/timer
import pkg/chronos/futures

import ./cpu
import ./memory
import ./power
import ./disk
import ./network
import ./process
import ../internal/[
  network_types,
  process_types,
  power_types,
  disk_types,
  cpu_types,
  memory_types
]

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
    timestamp*: int64      ## When the metric was collected (Unix timestamp in nanoseconds)
    case kind*: MetricKind
    of mkCPU: cpuMetrics*: cpu_types.CpuMetrics
    of mkMemory: memoryMetrics*: memory.MemoryMetrics
    of mkPower: powerMetrics*: power_types.PowerMetrics
    of mkDisk: diskMetrics*: disk_types.DiskMetrics
    of mkNetwork: networkMetrics*: network_types.NetworkMetrics
    of mkProcess: processMetrics*: process_types.ProcessMetrics

  MetricSnapshot* = ref object
    ## A snapshot of all metrics at a point in time
    timestamp*: int64      ## When the snapshot was taken (Unix timestamp in nanoseconds)
    metrics*: seq[MetricValue]  ## Collection of metric values

proc collectMetric*(kind: MetricKind): Future[MetricValue] {.async.} =
  ## Collects a single metric value asynchronously.
  ## Returns a MetricValue containing the collected data.
  result = MetricValue(kind: kind, timestamp: getTime().toUnix * 1_000_000_000)
  try:
    case kind
    of mkCPU:
      result.cpuMetrics = await getCpuMetrics()
    of mkMemory:
      result.memoryMetrics = getMemoryMetrics()
    of mkPower:
      result.powerMetrics = getPowerMetrics()
    of mkDisk:
      result.diskMetrics = await getDiskMetrics()
    of mkNetwork:
      result.networkMetrics = await getNetworkMetrics()
    of mkProcess:
      result.processMetrics = await getProcessMetrics()
  except Exception as e:
    raise newException(ValueError, "Failed to collect metric: " & e.msg)

proc collectSnapshot*(kinds: openArray[MetricKind]): Future[MetricSnapshot] {.async.} =
  ## Collects multiple metrics in parallel and returns a snapshot.
  ## Returns a MetricSnapshot containing all collected metrics.
  var futures = newSeq[Future[MetricValue]](kinds.len)
  for i, kind in kinds:
    futures[i] = collectMetric(kind)

  let values = await chronos.all(futures)
  result = MetricSnapshot(
    timestamp: getTime().toUnix * 1_000_000_000,
    metrics: @values
  )

when defined(useChronos):
  import ../internal/sampling/chronos_backend
else:
  import ../internal/sampling/core
