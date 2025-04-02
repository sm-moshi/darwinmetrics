## Tests for the sampling system.
##
## This module tests the metrics sampling functionality, ensuring that
## metrics can be collected properly at regular intervals.

import std/[unittest, options, asyncdispatch, times]
import chronos

import ../src/internal/sampling/core
import ../src/internal/sampling/sampling
import ../src/internal/[cpu_types, disk_types, memory_types, network_types, process_types]
import ../src/system/[
  cpu,
  memory,
  disk,
  network,
  process
]


# Helper proc to run an async test
template runAsyncTest(testName: string, testBody: untyped) =
  test testName:
    proc asyncTest() {.async.} =
      testBody
    waitFor asyncTest()

suite "Metric Sampling":
  runAsyncTest "can create a sampler":
    let interval = milliseconds(100)
    var callbackCalled = false

    proc callback(snapshot: MetricSnapshot): Future[void] {.async.} =
      callbackCalled = true

    let config = newSamplerConfig(interval, callback)
    let sampler = newSampler(config)

    check sampler != nil
    check sampler.interval == interval
    check sampler.isRunning() == false

  runAsyncTest "can start and stop sampling":
    let interval = milliseconds(100)
    var snapshotCount = 0

    proc callback(snapshot: MetricSnapshot): Future[void] {.async.} =
      inc snapshotCount

    let config = newSamplerConfig(interval, callback)
    let sampler = newSampler(config)

    check sampler.isRunning() == false
    sampler.start()
    check sampler.isRunning() == true

    # Let it collect a few samples
    await sleepAsync(350)

    sampler.stop()
    check sampler.isRunning() == false

    # Verify that samples were collected
    check snapshotCount > 0
    check sampler.snapshots.len > 0

  runAsyncTest "can collect correct metric types":
    let interval = milliseconds(100)
    var lastSnapshot: MetricSnapshot

    proc callback(snapshot: MetricSnapshot): Future[void] {.async.} =
      lastSnapshot = snapshot

    let config = newSamplerConfig(interval, callback)
    let sampler = newSampler(config)

    sampler.start()
    # Let it collect at least one sample
    await sleepAsync(150)
    sampler.stop()

    check lastSnapshot != nil
    check lastSnapshot.timestamp > 0
    # Check that metrics were collected
    check lastSnapshot.cpuMetrics != nil
    check lastSnapshot.memoryMetrics != nil
    check lastSnapshot.diskMetrics != nil
    check lastSnapshot.networkMetrics != nil
    check lastSnapshot.processMetrics != nil

  runAsyncTest "can handle callback errors":
    let interval = milliseconds(100)
    var errorCount = 0

    proc callback(snapshot: MetricSnapshot): Future[void] {.async.} =
      raise newException(ValueError, "Test error")

    proc errorHandler(err: MetricError) =
      inc errorCount

    let config = newSamplerConfig(interval, callback)
    let sampler = newSampler(config, errorHandler)

    sampler.start()
    # Let it generate some errors
    await sleepAsync(250)
    sampler.stop()

    # Verify errors were handled
    check errorCount > 0

  runAsyncTest "respects sampling interval":
    let interval = milliseconds(200)
    var timestamps: seq[int64]

    proc callback(snapshot: MetricSnapshot): Future[void] {.async.} =
      timestamps.add(getTime().toUnix())

    let config = newSamplerConfig(interval, callback)
    let sampler = newSampler(config)

    sampler.start()
    # Let it collect a few samples
    await sleepAsync(650)
    sampler.stop()

    # We should have at least 3 samples
    check timestamps.len >= 3

    # Verify intervals (allow some tolerance due to scheduler)
    for i in 1..<timestamps.len:
      let diff = timestamps[i] - timestamps[i-1]
      # Should be roughly 200ms apart (allow 50ms tolerance)
      check diff >= 0.15 and diff <= 0.25

  runAsyncTest "can perform single sample":
    let interval = milliseconds(100)
    let config = newSamplerConfig(interval)
    let sampler = newSampler(config)

    # Should have no snapshots initially
    check sampler.snapshots.len == 0

    # Perform a single sample
    sampler.sample()

    # Should have one snapshot now
    check sampler.snapshots.len == 1
    check sampler.snapshots[0] != nil

    # Sample should contain all metric types
    let snapshot = sampler.snapshots[0]
    check snapshot.timestamp > 0
    check snapshot.cpuMetrics != nil
    check snapshot.memoryMetrics != nil
    check snapshot.diskMetrics != nil
    check snapshot.networkMetrics != nil
    check snapshot.processMetrics != nil

  runAsyncTest "respects max snapshots limit":
    let interval = milliseconds(50)
    let config = newSamplerConfig(interval)
    let sampler = newSampler(config)

    # Override the max snapshots limit to something small for testing
    sampler.maxSnapshots = 3

    sampler.start()
    # Let it collect more than the limit
    await sleepAsync(300)
    sampler.stop()

    # Should respect the max snapshots limit
    check sampler.snapshots.len <= sampler.maxSnapshots
