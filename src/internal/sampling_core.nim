## Core types and interfaces for metric sampling.
##
## This module provides the fundamental types and interfaces used by both
## async backend implementations (chronos and stdlib).

import std/[times, options]
import ../system/[cpu, memory, power, disk, network, process]

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
    of mkCPU: cpuInfo*: CPUInfo
    of mkMemory: memInfo*: MemoryStats
    of mkPower: powerInfo*: PowerInfo
    of mkDisk: diskInfo*: DiskInfo
    of mkNetwork: networkInfo*: NetworkInfo
    of mkProcess: processInfo*: ProcessInfo

  MetricSnapshot* = ref object
    ## A point-in-time collection of multiple metrics
    timestamp*: Time                ## When the snapshot was taken
    values*: seq[MetricValue]       ## Successfully collected metrics
    errors*: seq[MetricError]       ## Any collection errors

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

  MetricSampler* = ref object of RootObj
    ## Base type for metric samplers
    kinds*: set[MetricKind]         ## Which metrics to collect
    interval*: Duration             ## How often to sample
    snapshots*: seq[MetricSnapshot] ## Historical snapshots (if enabled)
    maxSnapshots*: int             ## Maximum snapshots to retain (0 = unlimited)
    running*: bool                 ## Whether sampling is active

proc newMetricError*(kind: MetricErrorKind, msg: string, source: MetricKind): MetricError =
  ## Creates a new metric error with current timestamp
  MetricError(
    kind: kind,
    msg: msg,
    source: source,
    timestamp: getTime()
  )

proc pruneSnapshots*(sampler: MetricSampler) =
  ## Removes old snapshots if we're over the limit
  if sampler.maxSnapshots > 0 and sampler.snapshots.len > sampler.maxSnapshots:
    let deleteCount = sampler.snapshots.len - sampler.maxSnapshots
    for i in 0 ..< deleteCount:
      sampler.snapshots.delete(0)

proc latestSnapshot*(sampler: MetricSampler): Option[MetricSnapshot] =
  ## Returns the most recent snapshot if available
  if sampler.snapshots.len > 0:
    some(sampler.snapshots[^1])
  else:
    none(MetricSnapshot)
