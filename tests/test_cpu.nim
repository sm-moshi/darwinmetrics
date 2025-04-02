import std/[unittest, strutils, times, deques]
import pkg/chronos
import pkg/chronos/timer
import ../src/system/cpu
import ../src/internal/darwin_errors
import ../src/internal/cpu_types

when defined(macosx):
  suite "CPU Information":
    test "getCpuMetrics returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        check:
          metrics.architecture in ["arm64", "x86_64"]
          metrics.model.len > 0
          metrics.brand.len > 0
          ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
      waitFor testAsync()

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      check:
        str.contains("Architecture: arm64")
        str.contains("Model: MacBookPro18,3")
        str.contains("Brand: Apple M1 Pro")
        str.contains("Physical Cores: 8")
        str.contains("Logical Cores: 8")

  suite "Load Average":
    test "getLoadAverage returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        let load = metrics.loadAverage
        check:
          load.oneMinute >= 0.0
          load.fiveMinute >= 0.0
          load.fifteenMinute >= 0.0
          load.timestamp <= getTime()
      waitFor testAsync()

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.5,
        fiveMinute: 2.0,
        fifteenMinute: 1.8,
        timestamp: getTime()
      )
      let str = $load
      check:
        str.contains("1 minute:  1.50")
        str.contains("5 minute:  2.00")
        str.contains("15 minute: 1.80")
        str.contains("Timestamp:")

    test "LoadAverage validation catches invalid values":
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: -1.0,
          fiveMinute: 1.0,
          fifteenMinute: 1.0,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 1.0,
          fiveMinute: -1.0,
          fifteenMinute: 1.0,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 1.0,
          fiveMinute: 1.0,
          fifteenMinute: -1.0,
          timestamp: getTime()
        )

  suite "Load History":
    test "newLoadHistory creates history with correct size":
      let history = newLoadHistory(maxSamples = 5)
      check:
        history.maxSamples == 5
        history.len == 0

    test "add respects maxSamples limit":
      var history = newLoadHistory(maxSamples = 3)
      let now = getTime()

      # Add 4 samples
      for i in 0..3:
        history.add(LoadAverage(
          oneMinute: float(i),
          fiveMinute: float(i),
          fifteenMinute: float(i),
          timestamp: now
        ))

      check history.len == 3 # Should maintain max size

    test "add validates samples before adding":
      var history = newLoadHistory()
      let now = getTime()

      expect DarwinError:
        history.add(LoadAverage(
          oneMinute: -1.0,
          fiveMinute: 1.0,
          fifteenMinute: 1.0,
          timestamp: now
        ))

      check history.len == 0 # Invalid sample should not be added

when isMainModule:
  when not defined(macosx):
    echo "Tests skipped: Not running on macOS"
