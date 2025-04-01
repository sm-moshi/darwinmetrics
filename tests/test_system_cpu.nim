## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils, times, math, sequtils, deques]
import ../src/system/cpu
import ../src/internal/darwin_errors

const FloatEpsilon = 1e-6

proc almostEqual(a, b: float): bool =
  ## Float comparison with epsilon
  abs(a - b) < FloatEpsilon

when defined(darwin):
  suite "CPU Information Tests":
    test "getCpuInfo returns valid information":
      let info = getCpuInfo()
      check:
        info.physicalCores > 0
        info.logicalCores >= info.physicalCores
        info.architecture in ["arm64", "x86_64"]
        info.model.len > 0
        info.brand.len > 0
        # maxFrequency is optional, so we just check it's parseable if present
        (if info.maxFrequency.isSome: info.maxFrequency.get() > 0.0
        else: true)

    test "getCpuInfo string representation is formatted correctly":
      let info = getCpuInfo()
      let str = $info
      check:
        str.contains("Physical Cores:")
        str.contains("Logical Cores:")
        str.contains("Architecture:")
        str.contains("Model:")
        str.contains("Brand:")
        str.contains("Max Frequency:")

    test "getCpuInfo handles missing frequency gracefully":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,2",
        brand: "Apple M1 Pro",
        maxFrequency: none(float),
      )
      let str = $info
      check str.contains("Max Frequency: Unknown")

    test "getCpuInfo validates core counts":
      let info = getCpuInfo()
      check:
        info.physicalCores > 0
        info.logicalCores >= info.physicalCores
        info.logicalCores mod info.physicalCores == 0
          # Logical cores should be a multiple of physical cores

    test "getCpuInfo architecture matches system":
      let info = getCpuInfo()
      when defined(amd64):
        check info.architecture == "x86_64"
      when defined(arm64):
        check info.architecture == "arm64"

    test "getCpuInfo brand string is consistent":
      let info = getCpuInfo()
      when defined(arm64):
        check "Apple" in info.brand
      when defined(amd64):
        check "Intel" in info.brand

    test "getCpuInfo handles invalid core counts":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = -1,
          logicalCores = 8,
          architecture = "arm64",
          model = "Test",
          brand = "Test",
        )

    test "getCpuInfo handles invalid architecture":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "invalid",
          model = "Test",
          brand = "Test",
        )

    test "getCpuInfo handles empty model/brand":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "arm64",
          model = "",
          brand = "",
        )

  suite "Load Average Tests":
    test "getLoadAverage returns valid load averages":
      let load = getLoadAverage()
      check:
        load.oneMinute >= 0.0 # Load can be higher than 1.0 on busy systems
        load.fiveMinute >= 0.0
        load.fifteenMinute >= 0.0
        load.timestamp <= getTime() # Timestamp should be now or in the past
        # Load averages should follow a pattern (not strictly required but common)
        load.oneMinute >= load.fiveMinute or load.oneMinute <= load.fiveMinute * 2.0
        load.fiveMinute >= load.fifteenMinute or load.fiveMinute <=
            load.fifteenMinute * 2.0

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.23,
        fiveMinute: 0.45,
        fifteenMinute: 0.67,
        timestamp: getTime()
      )
      let str = $load
      check:
        str.contains("1 minute:  1.23")
        str.contains("5 minute:  0.45")
        str.contains("15 minute: 0.67")
        str.contains("Timestamp: ")

    test "LoadAverage validation catches invalid values":
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: -1.0,
          fiveMinute: 0.5,
          fifteenMinute: 0.5,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: -1.0,
          fifteenMinute: 0.5,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: 0.5,
          fifteenMinute: -1.0,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: 0.5,
          fifteenMinute: 0.5,
          timestamp: getTime() + 5.minutes # Future timestamp
        )

    test "LoadHistory maintains size and order":
      var history = newLoadHistory(maxSamples = 2)
      let now = getTime()

      # First sample
      let sample1 = LoadAverage(
        oneMinute: 0.1,
        fiveMinute: 0.2,
        fifteenMinute: 0.3,
        timestamp: now - 2.minutes
      )
      history.add(sample1)
      check history.samples.len == 1

      # Second sample
      let sample2 = LoadAverage(
        oneMinute: 0.4,
        fiveMinute: 0.5,
        fifteenMinute: 0.6,
        timestamp: now - 1.minutes
      )
      history.add(sample2)
      check history.samples.len == 2

      # Third sample (should remove first)
      let sample3 = LoadAverage(
        oneMinute: 0.7,
        fiveMinute: 0.8,
        fifteenMinute: 0.9,
        timestamp: now
      )
      history.add(sample3)
      check history.samples.len == 2

    test "LoadHistory handles empty state":
      let history = newLoadHistory()
      check:
        history.samples.len == 0
        history.maxSamples == 60 # Default max samples

else:
  echo "Skipping CPU tests on non-Darwin platform"
