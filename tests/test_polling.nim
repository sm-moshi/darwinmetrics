## Tests for async polling helpers.
##
## This module tests the polling primitives with retry, timeout,
## and backoff support.

import std/[unittest, times, options]
import chronos
import ../src/internal/sampling/core
import ../src/internal/sampling/converters
import ../src/internal/sampling/sampling
import ./test_helpers

suite "Metric Sampling":
  test "sampler collects metrics successfully":
    proc runTest() {.async: (raises: [CatchableError]).} =
      var snapshotReceived = false
      let callback = proc(snapshot: MetricSnapshot): Future[void] {.closure, gcsafe, raises: [].} =
        result = newFuture[void]("callback")
        if snapshot == nil:
          result.complete()
          return
        if snapshot.timestamp <= 0:
          result.complete()
          return
        if snapshot.cpuMetrics.timestamp <= 0:
          result.complete()
          return
        if snapshot.memoryMetrics.timestamp <= 0:
          result.complete()
          return
        if snapshot.diskMetrics.timestamp <= 0:
          result.complete()
          return
        if snapshot.networkMetrics.timestamp <= 0:
          result.complete()
          return
        if snapshot.processMetrics.timestamp <= 0:
          result.complete()
          return
        if snapshot.powerMetrics.timestamp <= 0:
          result.complete()
          return
        snapshotReceived = true
        result.complete()

      let config = newSamplerConfig(
        interval = core.milliseconds(100),
        callback = callback
      )
      let sampler = newSampler(config)
      await sampler.start()
      await sleepAsync(chronos.milliseconds(150))
      await sampler.stop()
      assert snapshotReceived

    try:
      waitFor(runTest())
    except CatchableError as e:
      assert false, "Test failed: " & e.msg

  test "sampler handles errors gracefully":
    proc runTest() {.async: (raises: [CatchableError]).} =
      var errorCount = 0
      let callback = proc(snapshot: MetricSnapshot): Future[void] {.closure, gcsafe, raises: [].} =
        result = newFuture[void]("callback")
        inc errorCount
        result.fail(newException(CatchableError, "Test error"))

      let config = newSamplerConfig(
        interval = core.milliseconds(50),
        callback = callback
      )
      let sampler = newSampler(config)
      await sampler.start()
      await sleepAsync(chronos.milliseconds(150))
      await sampler.stop()
      assert errorCount > 0

    try:
      waitFor(runTest())
    except CatchableError as e:
      assert false, "Test failed: " & e.msg

  test "sampler respects interval":
    proc runTest() {.async: (raises: [CatchableError]).} =
      var lastTimestamp = 0'i64
      var intervals: seq[int64] = @[]
      let callback = proc(snapshot: MetricSnapshot): Future[void] {.closure, gcsafe, raises: [].} =
        result = newFuture[void]("callback")
        if lastTimestamp > 0:
          intervals.add(snapshot.timestamp - lastTimestamp)
        lastTimestamp = snapshot.timestamp
        result.complete()

      let config = newSamplerConfig(
        interval = core.milliseconds(500),  # 500ms interval
        callback = callback
      )
      let sampler = newSampler(config)
      await sampler.start()
      await sleepAsync(chronos.milliseconds(1500))  # Run for 1.5 seconds
      await sampler.stop()

      assert intervals.len >= 2
      for interval in intervals:
        # Allow some variance but ensure roughly correct interval
        assert interval >= 400_000_000 # 400ms in ns
        assert interval <= 600_000_000 # 600ms in ns

    try:
      waitFor(runTest())
    except CatchableError as e:
      assert false, "Test failed: " & e.msg

  test "sampler can be started and stopped multiple times":
    proc runTest() {.async: (raises: [CatchableError]).} =
      var snapshotCount = 0
      let callback = proc(snapshot: MetricSnapshot): Future[void] {.closure, gcsafe, raises: [].} =
        result = newFuture[void]("callback")
        inc snapshotCount
        result.complete()

      let config = newSamplerConfig(
        interval = core.milliseconds(50),
        callback = callback
      )
      let sampler = newSampler(config)

      # First run
      await sampler.start()
      await sleepAsync(chronos.milliseconds(100))
      await sampler.stop()
      let firstCount = snapshotCount

      # Second run
      await sampler.start()
      await sleepAsync(chronos.milliseconds(100))
      await sampler.stop()
      let secondCount = snapshotCount - firstCount

      assert firstCount > 0
      assert secondCount > 0

    try:
      waitFor(runTest())
    except CatchableError as e:
      assert false, "Test failed: " & e.msg

  test "sampler isRunning status is accurate":
    proc runTest() {.async: (raises: [CatchableError]).} =
      let config = newSamplerConfig(interval = core.milliseconds(50))
      let sampler = newSampler(config)

      assert not (await sampler.isRunning())
      await sampler.start()
      assert await sampler.isRunning()
      await sampler.stop()
      assert not (await sampler.isRunning())

    try:
      waitFor(runTest())
    except CatchableError as e:
      assert false, "Test failed: " & e.msg
