## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils]
import ../src/system/cpu
import ../src/internal/darwin_errors

when defined(darwin):
  suite "CPU Information Tests":
    test "getCpuInfo returns valid data":
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
      let
        info = newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "arm64",
          model = "MacBookPro18,2",
          brand = "Apple M1 Pro",
          maxFrequency = some(3200.0),
        )
        str = $info

      check:
        "Physical Cores: 8" in str
        "Logical Cores: 8" in str
        "Architecture: arm64" in str
        "Model: MacBookPro18,2" in str
        "Brand: Apple M1 Pro" in str
        "Max Frequency: 3200.0 MHz" in str

    test "getCpuInfo handles missing frequency gracefully":
      let
        info = newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "arm64",
          model = "MacBookPro18,2",
          brand = "Apple M1 Pro",
        )
        str = $info

      check "Max Frequency: Unknown" in str

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
else:
  echo "Skipping CPU tests on non-Darwin platform"
