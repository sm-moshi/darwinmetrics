## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils, times]
import ../src/system/cpu
import ../src/internal/darwin_errors

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
        load.oneMinute >= load.fiveMinute or load.oneMinute <= load.fiveMinute * 2.0
        load.fiveMinute >= load.fifteenMinute or
          load.fiveMinute <= load.fifteenMinute * 2.0

    test "getLoadAverage handles errors appropriately":
      try:
        discard getLoadAverage()
      except DarwinError:
        check false # Should not raise DarwinError on valid system
      except CatchableError:
        check false # Should not raise unexpected exceptions
else:
  echo "Skipping CPU tests on non-Darwin platform"
