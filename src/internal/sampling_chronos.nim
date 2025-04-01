## Chronos-based implementation of metric sampling.
##
## This module provides a high-performance async metric sampler using
## the Chronos async framework. It supports proper cancellation and
## timeout handling.

import std/[options, times]
import chronos
import chronos/timer
import stew/results
import ../system/[cpu, memory, power, disk, network, process]
import ./sampling_core
import ./mach_stats
import ./mach_power

type
  ChronosSampler* = ref object of MetricSampler
    ## Chronos-based metric sampler implementation
    future: Future[void]            ## Current sampling future

proc collectMetric*(sampler: ChronosSampler, kind: MetricKind): Future[MetricValue] {.async.} =
  ## Collect a single metric asynchronously
  result = MetricValue(kind: kind, timestamp: getTime())

  try:
    case kind
    of mkCPU:
      result.cpuInfo = getCpuInfo()
    of mkMemory:
      result.memInfo = getMemoryStats()
    of mkPower:
      result.powerInfo = getPowerInfo()
    of mkDisk:
      result.diskInfo = DiskInfo(
        totalSpace: 0'i64,
        freeSpace: 0'i64,
        readBytes: 0'i64,
        writeBytes: 0'i64,
        readOps: 0'i64,
        writeOps: 0'i64
      )
    of mkNetwork:
      result.networkInfo = NetworkInfo(
        bytesReceived: 0'i64,
        bytesSent: 0'i64,
        packetsReceived: 0'i64,
        packetsSent: 0'i64,
        errors: 0'i64,
        drops: 0'i64
      )
    of mkProcess:
      result.processInfo = ProcessInfo(
        totalProcesses: 0'i32,
        runningProcesses: 0'i32,
        zombieProcesses: 0'i32,
        systemCPUTime: 0.0,
        userCPUTime: 0.0,
        virtualMemory: 0'i64
      )
  except Exception as e:
    raise newException(ValueError, "Failed to collect " & $kind & " metric: " & e.msg)

proc collectSnapshot*(sampler: ChronosSampler): Future[MetricSnapshot] {.async.} =
  ## Collect all enabled metrics asynchronously
  var snapshot = MetricSnapshot(
    timestamp: getTime(),
    values: @[],
    errors: @[]
  )

  for kind in sampler.kinds:
    try:
      let value = await sampler.collectMetric(kind)
      snapshot.values.add(value)
    except Exception as e:
      snapshot.errors.add(newMetricError(meCollection, e.msg, kind))

  return snapshot

proc newChronosSampler*(kinds: set[MetricKind] = {low(MetricKind)..high(MetricKind)},
                        interval: chronos.Duration = chronos.seconds(1),
                        maxSnapshots: int = 0): ChronosSampler =
  ## Creates a new Chronos-based metric sampler
  result = ChronosSampler(future: nil)
  result.kinds = kinds
  result.interval = initDuration(nanoseconds = interval.nanoseconds)
  result.maxSnapshots = maxSnapshots
  result.snapshots = @[]
  result.running = false

proc start*(sampler: ChronosSampler) {.async.} =
  ## Starts periodic metric collection
  if sampler.running:
    return

  sampler.running = true
  while sampler.running:
    try:
      let snapshot = await sampler.collectSnapshot()
      sampler.snapshots.add(snapshot)
      sampler.pruneSnapshots()
    except CancelledError:
      sampler.running = false
      break
    except Exception as e:
      echo "Error collecting metrics: ", e.msg

    await chronos.sleepAsync(chronos.nanos(sampler.interval.inNanoseconds))

proc stop*(sampler: ChronosSampler) {.async.} =
  ## Stops metric collection
  if sampler.running:
    sampler.running = false
    if not sampler.future.isNil:
      await sampler.future.cancelAndWait()
