import std/[unittest, strutils]
import ../src/internal/platform_darwin

when defined(macosx):
  suite "Darwin Platform Detection":
    test "getMachineArchitecture returns valid architecture":
      let arch = getMachineArchitecture()
      check:
        arch in ["arm64", "x86_64"] # Only valid architectures on modern macOS

    test "getMachineModel returns non-empty model":
      let model = getMachineModel()
      check:
        model.len > 0
        model.startsWith("Mac") # All Mac models start with "Mac"

    test "getCpuBrand returns non-empty brand":
      let brand = getCpuBrand()
      check:
        brand.len > 0
        # Should contain either Intel or Apple
        brand.contains("Intel") or brand.contains("Apple")

    test "getSysctlString raises on invalid key":
      expect SysctlError:
        discard getSysctlString("invalid.key.that.does.not.exist")

    test "getSysctlString handles empty strings":
      # kern.nisdomainname is reliably empty on macOS systems
      let value = getSysctlString("kern.nisdomainname")
      check value.len == 0

when isMainModule:
  when not defined(macosx):
    echo "Tests skipped: Not running on macOS"
