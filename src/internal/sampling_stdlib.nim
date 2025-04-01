## Standard library async implementation of metric sampling.
##
## This module provides a simpler async metric sampler using
## the standard library's async framework.

import std/[times, options, asyncdispatch]
import ./sampling_core
import ../system/[cpu, memory, power, disk, network, process]

type
  StdlibSampler* = ref object of MetricSampler
    ## Standard library async metric sampler implementation
    future: Future[void]         ## Current sampling future

proc collectMetric(kind: MetricKind): Future[MetricValue] {.async.} =
  ## Collects a single metric asynchronously
  let timestamp = getTime()
  var value = MetricValue(timestamp: timestamp, kind: kind)

  try:
    case kind
    of mkCPU: value.cpuInfo = await getCPUInfo()
    of mkMemory: value.memInfo = await getMemoryStats()
    of mkPower: value.powerInfo = await getPowerInfo()
    of mkDisk: value.diskInfo = await getDiskInfo()
    of mkNetwork: value.networkInfo = await getNetworkInfo()
    of mkProcess: value.processInfo = await getProcessInfo()
    return value
  except CatchableError as e:
    raise newException(OSError, "Failed to collect " & $kind & ": " & e.msg)

proc newStdlibSampler*(kinds: set[MetricKind] = {low(MetricKind)..high(MetricKind)},
                       interval = initDuration(seconds = 1),
                       maxSnapshots: int = 0): StdlibSampler =
  ## Creates a new standard library async metric sampler
  StdlibSampler(
    kinds: kinds,
    interval: interval,
    maxSnapshots: maxSnapshots,
    snapshots: @[],
    running: false
  )

proc stop*(sampler: StdlibSampler) {.async.} =
  ## Stops metric collection
  if sampler.running:
    sampler.running = false
    if not sampler.future.isNil:
      await sampler.future.cancelAndWait()

proc collectSnapshot(sampler: StdlibSampler): Future[MetricSnapshot] {.async.} =
  ## Collects a single snapshot of all requested metrics
  var snapshot = MetricSnapshot(
    timestamp: getTime(),
    values: @[],
    errors: @[]
  )

  var futures: seq[Future[MetricValue]] = @[]

  # Start collectors for each metric type
  for kind in sampler.kinds:
    try:
      futures.add(collectMetric(kind))
    except CatchableError as e:
      snapshot.errors.add(newMetricError(meCollection, e.msg, kind))

  # Wait for all collectors with timeout
  try:
    let values = await all(futures)
    snapshot.values.extend(values)
  except AsyncTimeoutError:
    for kind in sampler.kinds:
      snapshot.errors.add(newMetricError(meTimeout, "Collection timed out", kind))
  except CancelledError:
    for kind in sampler.kinds:
      snapshot.errors.add(newMetricError(meCancellation, "Collection cancelled", kind))
  except CatchableError as e:
    for kind in sampler.kinds:
      snapshot.errors.add(newMetricError(meCollection, e.msg, kind))

  return snapshot

proc sample(sampler: StdlibSampler) {.async.} =
  ## Main sampling loop
  while sampler.running:
    try:
      let snapshot = await sampler.collectSnapshot()
      sampler.snapshots.add(snapshot)
      sampler.pruneSnapshots()
      await sleepAsync(sampler.interval.inMilliseconds.int)
    except CancelledError:
      break
    except CatchableError as e:
      # Log error but continue sampling
      echo "Sampling error: " & e.msg
      await sleepAsync(1000) # Brief pause before retry

proc start*(sampler: StdlibSampler) {.async.} =
  ## Starts metric collection
  if not sampler.running:
    sampler.running = true
    sampler.future = sample(sampler)

proc isRunning*(sampler: StdlibSampler): bool =
  ## Returns whether the sampler is currently running
  sampler.running and not sampler.future.isNil and not sampler.future.finished
