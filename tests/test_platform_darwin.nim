import std/[unittest, strutils]
import ../src/internal/platform_darwin
import ../src/internal/darwin_errors
from std/strutils import Letters, Digits

when defined(darwin):
  suite "Darwin Platform Detection":
    test "getDarwinVersion returns valid version":
      let (major, minor) = getDarwinVersion()
      check:
        major >= 21 # Darwin 21.0 (macOS 12.0) or later
        minor >= 0
        $major & "." & $minor ==
          getSysctlString("kern.osrelease").split('.')[0 .. 1].join(".")

    test "checkDarwinVersion succeeds on supported versions":
      # Should not raise an exception
      checkDarwinVersion()
      check true # Test passes if we reach this point

    test "getMachineArchitecture returns valid architecture":
      let arch = getMachineArchitecture()
      check:
        arch in ["arm64", "x86_64"] # Only valid architectures on modern macOS

    test "getMachineModel returns valid model":
      let model = getMachineModel()
      echo "Debug - Model string: [" & model & "]"
      var nonAlphaNum = ""
      for c in model:
        if c notin Letters + Digits + {'-', '_', ' '}:
          nonAlphaNum.add(c)
      echo "Debug - Non-alphanumeric chars: [" & nonAlphaNum & "]"
      check:
        model.len > 0  # Model string should not be empty
        # Model should be a valid identifier - allow commas for Apple model IDs (e.g. "Mac14,9")
        model.allCharsInSet(Letters + Digits + {'-', '_', ' ', ','})

    test "getCpuBrand returns valid brand":
      let brand = getCpuBrand()
      check:
        brand.len > 0
        # Should contain either Intel or Apple
        ("Intel" in brand) or ("Apple" in brand)

    test "getSysctlString handles empty strings":
      # kern.nisdomainname is reliably empty on macOS systems
      let value = getSysctlString("kern.nisdomainname")
      check value.len == 0

    test "getSysctlString raises on invalid key":
      expect (ref DarwinError):
        discard getSysctlString("invalid.key.that.does.not.exist")

when isMainModule:
  when not defined(darwin):
    echo "Tests skipped: Not running on Darwin platform"
