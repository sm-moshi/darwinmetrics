import std/[unittest, options, tables]
import chronos
import chronos/unittest2/asynctests
import ../src/internal/sampling/[types, metric_collector]

suite "Metric Collector":
  test "MetricCollector creation":
    let collector = newMetricCollector()
    check collector.timeout == types.seconds(5) # Default timeout

    let customCollector = newMetricCollector(types.seconds(10))
    check customCollector.timeout == types.seconds(10)

  asyncTest "CPU metric collection":
    let collector = newMetricCollector()
    let result = await collector.collectCpu()

    check result.value.kind == mkCPU
    check result.value.cpuValue >= 0.0
    check result.value.cpuValue <= 100.0
    check result.error.isNone
    check int64(result.timestamp) > 0

  asyncTest "Memory metric collection":
    let collector = newMetricCollector()
    let result = await collector.collectMemory()

    check result.value.kind == mkMemory
    check result.value.memoryBytes > 0'u64
    check result.error.isNone
    check int64(result.timestamp) > 0

  asyncTest "Power metric collection":
    let collector = newMetricCollector()
    let result = await collector.collectPower()

    check result.value.kind == mkPower
    check result.value.powerWatts >= 0.0
    check result.error.isNone
    check int64(result.timestamp) > 0

  asyncTest "Process metric collection":
    let collector = newMetricCollector()
    let pid: int32 = 1 # System process
    let result = await collector.collectProcess(pid)

    check result.value.kind == mkProcess
    check result.value.pid == pid
    check int64(result.timestamp) > 0

  asyncTest "Parallel collection of all metrics":
    let collector = newMetricCollector()
    let snapshot = await collector.collectAll()

    check snapshot.metrics.len >= 3 # At least CPU, memory, and power
    check "cpu" in snapshot.metrics
    check "memory" in snapshot.metrics
    check "power" in snapshot.metrics
    check snapshot.error.isNone
    check int64(snapshot.timestamp) > 0

    # Verify individual metrics
    let cpuMetric = snapshot.metrics["cpu"]
    check cpuMetric.value.kind == mkCPU
    check cpuMetric.value.cpuValue >= 0.0
    check cpuMetric.value.cpuValue <= 100.0

    let memMetric = snapshot.metrics["memory"]
    check memMetric.value.kind == mkMemory
    check memMetric.value.memoryBytes > 0'u64

    let powerMetric = snapshot.metrics["power"]
    check powerMetric.value.kind == mkPower
    check powerMetric.value.powerWatts >= 0.0

  asyncTest "Error handling in collection":
    let collector = newMetricCollector(types.milliseconds(1)) # Very short timeout
    let snapshot = await collector.collectAll()

    # Even with errors, we should get a valid snapshot
    check int64(snapshot.timestamp) > 0
    check snapshot.metrics.len >= 0

  asyncTest "Periodic sampling":
    let collector = newMetricCollector()
    var sampleCount = 0
    var lastCpuValue = 0.0

    # Start sampling every 100ms
    let samplingFuture = collector.startPeriodicSampling(types.milliseconds(
        100)) do (snapshot: MetricSnapshot):
      inc sampleCount
      if "cpu" in snapshot.metrics:
        lastCpuValue = snapshot.metrics["cpu"].value.cpuValue

    # Let it run for ~250ms to get ~2-3 samples
    await sleepAsync(chronos.milliseconds(250))
    await collector.stopSampling()

    check sampleCount >= 2
    check lastCpuValue >= 0.0
    check lastCpuValue <= 100.0
    check not collector.isSampling

  asyncTest "Periodic sampling with error handling":
    let collector = newMetricCollector()
    var errorCount = 0
    var successCount = 0

    # Start sampling with a callback that sometimes fails
    let samplingFuture = collector.startPeriodicSampling(types.milliseconds(
        100)) do (snapshot: MetricSnapshot):
      if successCount == 1: # Fail on second sample
        inc errorCount
        raise newException(ValueError, "Test error")
      else:
        inc successCount

    # Let it run for ~250ms
    await sleepAsync(chronos.milliseconds(250))
    await collector.stopSampling()

    check errorCount >= 1 # At least one error occurred
    check successCount >= 1 # At least one success
    check not collector.isSampling

  asyncTest "Multiple start/stop cycles":
    let collector = newMetricCollector()
    var sampleCount = 0

    # First cycle
    let future1 = collector.startPeriodicSampling(types.milliseconds(100)) do (
      snapshot: MetricSnapshot):
      inc sampleCount
    await sleepAsync(chronos.milliseconds(150))
    await collector.stopSampling()
    let count1 = sampleCount

    # Second cycle
    let future2 = collector.startPeriodicSampling(types.milliseconds(100)) do (
      snapshot: MetricSnapshot):
      inc sampleCount
    await sleepAsync(chronos.milliseconds(150))
    await collector.stopSampling()

    check count1 >= 1 # First cycle collected samples
    check sampleCount > count1 # Second cycle added more samples
    check not collector.isSampling
