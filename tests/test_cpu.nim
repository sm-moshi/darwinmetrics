import std/[unittest, strutils]
import ../src/system/cpu
import ../src/internal/platform_darwin

when defined(macosx):
  suite "CPU Information":
    test "getCpuInfo returns valid information":
      let info = getCpuInfo()
      check:
        info.architecture in ["arm64", "x86_64"]
        info.model.len > 0
        info.model.startsWith("Mac")
        info.brand.len > 0
        ("Intel" in info.brand) or ("Apple" in info.brand)

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      check:
        str.contains("Architecture: arm64")
        str.contains("Model: MacBookPro18,3")
        str.contains("Brand: Apple M1 Pro")

when isMainModule:
  when not defined(macosx):
    echo "Tests skipped: Not running on macOS"
