import std/[unittest, options, tables]
import internal/sampling/types

suite "Metric Types":
  test "MetricValue handles different types correctly":
    let cpuValue = MetricValue(kind: mkCPU, cpuValue: 0.75)
    check cpuValue.kind == mkCPU
    check cpuValue.cpuValue == 0.75

    let memValue = MetricValue(kind: mkMemory, memoryBytes: 1024'u64)
    check memValue.kind == mkMemory
    check memValue.memoryBytes == 1024'u64

  test "MetricResult creation and access":
    let value = MetricValue(kind: mkCPU, cpuValue: 0.75)
    let result = newMetricResult(value)

    check result.value.kind == mkCPU
    check result.value.cpuValue == 0.75
    check result.error.isNone
    check int64(result.timestamp) > 0 # Should be a valid timestamp

  test "MetricSnapshot creation and management":
    let snapshot = newMetricSnapshot()
    check snapshot.metrics.len == 0
    check snapshot.error.isNone
    check int64(snapshot.timestamp) > 0

    let cpuResult = newMetricResult(MetricValue(kind: mkCPU, cpuValue: 0.75))
    let memResult = newMetricResult(MetricValue(kind: mkMemory,
        memoryBytes: 1024'u64))

    snapshot.metrics["cpu"] = cpuResult
    snapshot.metrics["memory"] = memResult

    check snapshot.metrics.len == 2
    check snapshot.metrics["cpu"].value.kind == mkCPU
    check snapshot.metrics["memory"].value.kind == mkMemory

  test "MetricResult handles errors":
    let value = MetricValue(kind: mkCPU, cpuValue: 0.75)
    var result = newMetricResult(value)
    result.error = some("Test error")
    check result.error.get() == "Test error"

  test "MetricSnapshot handles errors":
    var snapshot = newMetricSnapshot()
    snapshot.error = some("Collection error")
    check snapshot.error.get() == "Collection error"
