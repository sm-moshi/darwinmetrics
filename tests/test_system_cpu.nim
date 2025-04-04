## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[options, strutils, times]
import chronos
import chronos/unittest2/asynctests
import ../src/system/cpu
import ../src/internal/darwin_errors
import ../src/internal/cpu_types

const FloatEpsilon = 1e-6

proc almostEqual(a, b: float): bool =
  ## Float comparison with epsilon
  abs(a - b) < FloatEpsilon

when defined(darwin):
  suite "CPU Information Tests":
    asyncTest "getCpuMetrics returns valid information":
      let metrics = await getCpuMetrics()
      check metrics.architecture in ["arm64", "x86_64"]
      check metrics.model.len > 0
      check metrics.brand.len > 0
      check ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
      check metrics.frequency.nominal > 0.0
      check metrics.frequency.current.isNone
      check (if metrics.frequency.max.isSome: metrics.frequency.max.get() >=
          metrics.frequency.nominal else: true)
      check (if metrics.frequency.min.isSome: metrics.frequency.min.get() <=
          metrics.frequency.nominal else: true)
      check metrics.usage.user >= 0.0 and metrics.usage.user <= 100.0
      check metrics.usage.system >= 0.0 and metrics.usage.system <= 100.0
      check metrics.usage.idle >= 0.0 and metrics.usage.idle <= 100.0
      check metrics.usage.nice >= 0.0 and metrics.usage.nice <= 100.0
      check metrics.usage.total >= 0.0 and metrics.usage.total <= 100.0
      check almostEqual(metrics.usage.total, 100.0 - metrics.usage.idle)
      check almostEqual(metrics.usage.user + metrics.usage.system +
          metrics.usage.idle + metrics.usage.nice, 100.0)

    asyncTest "getCpuUsage returns valid percentages":
      let usage = await getCpuUsage()
      check usage.user >= 0.0 and usage.user <= 100.0
      check usage.system >= 0.0 and usage.system <= 100.0
      check usage.idle >= 0.0 and usage.idle <= 100.0
      check usage.nice >= 0.0 and usage.nice <= 100.0
      check usage.total >= 0.0 and usage.total <= 100.0
      check almostEqual(usage.total, 100.0 - usage.idle)
      check almostEqual(usage.user + usage.system + usage.idle + usage.nice, 100.0)

    asyncTest "getCpuUsage string representation is formatted correctly":
      let usage = await getCpuUsage()
      let str = $usage
      check str.contains("CPU Usage:")
      check str.contains("User:")
      check str.contains("System:")
      check str.contains("Nice:")
      check str.contains("Idle:")
      check str.contains("Total:")

    asyncTest "getLoadAverage returns valid values":
      let load = await getLoadAverage()
      check load.oneMinute >= 0.0
      check load.fiveMinute >= 0.0
      check load.fifteenMinute >= 0.0
      check load.timestamp <= getTime()

    asyncTest "getLoadAverage string representation is formatted correctly":
      let load = await getLoadAverage()
      let str = $load
      check str.contains("Load Averages:")
      check str.contains("1 minute:")
      check str.contains("5 minute:")
      check str.contains("15 minute:")
      check str.contains("Timestamp:")

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      check str.contains("Architecture: arm64")
      check str.contains("Model: MacBookPro18,3")
      check str.contains("Brand: Apple M1 Pro")
      check str.contains("Physical Cores: 8")
      check str.contains("Logical Cores: 8")

    test "newCpuMetrics handles missing frequency gracefully":
      var freq = CpuFrequency()
      freq.nominal = 3500.0
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)

      var metrics = newCpuMetrics(8, 8, "arm64", "MacBookPro18,2",
          "Apple M2 Pro", freq)
      metrics.usage = CpuUsage(
        user: 0.0,
        system: 0.0,
        idle: 100.0,
        nice: 0.0,
        total: 0.0
      )
      let str = $metrics
      check str.contains("Frequency:")
      check str.contains("MHz")
      check str.contains("Current: Not available")

    test "newCpuMetrics handles invalid core counts":
      expect (ref DarwinError):
        discard newCpuMetrics(-1, 8, "arm64", "Test", "Test", CpuFrequency())
else:
  echo "Skipping CPU tests on non-Darwin platform"
