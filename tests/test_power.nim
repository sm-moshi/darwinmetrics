import unittest, strutils, options, os
import ../src/system/power

# Helper for test
proc almostEqual(a, b: float, epsilon = 0.001): bool =
  abs(a - b) <= epsilon

suite "Power API Tests":
  test "getPowerMetrics returns valid information":
    let info = getPowerMetrics()
    check:
      info.source in {PowerSource.AC, PowerSource.Battery, PowerSource.UPS,
          PowerSource.Unknown}
      info.status in {PowerStatus.Charging, PowerStatus.Discharging, PowerStatus.Full,
                      PowerStatus.ACPowered, PowerStatus.Unknown}
      info.percentRemaining >= 0.0 and info.percentRemaining <= 100.0
      info.thermalPressure in {ThermalPressure.Normal, ThermalPressure.Moderate,
                               ThermalPressure.Heavy, ThermalPressure.Critical,
                               ThermalPressure.Unknown}
      # If battery is present, ensure percentage is valid
      (if info.isPresent: info.percentRemaining >= 0.0 else: true)

  test "getBatteryPercentage returns valid value":
    let percent = getBatteryPercentage()
    check:
      percent >= 0.0 and percent <= 100.0

  test "isPowerAdapterConnected returns boolean":
    let connected = isPowerAdapterConnected()
    check:
      connected in [true, false]

    # Cross-check with main power info
    let info = getPowerMetrics()
    check:
      connected == (info.source == PowerSource.AC)

  test "getRemainingTime returns valid option":
    let remaining = getRemainingTime()
    if remaining.isSome():
      check:
        remaining.get() >= 0

    # Cross-check with main power info
    let info = getPowerMetrics()
    if info.isPresent and info.status == PowerStatus.Discharging and
        info.timeRemaining.isSome():
      check:
        remaining.isSome()
        remaining.get() == info.timeRemaining.get()
    else:
      check:
        remaining.isNone()

  test "getBatteryHealth returns valid option":
    let health = getBatteryHealth()
    if health.isSome():
      let h = health.get()
      check:
        h.cycleCount >= 0
        h.condition.len > 0
        h.designCapacity > 0
        h.currentCapacity > 0
        h.maxCapacity > 0
        h.temperature >= 0.0

  test "getThermalPressureLevel returns valid level":
    let pressure = getThermalPressureLevel()
    check:
      pressure in {ThermalPressure.Normal, ThermalPressure.Moderate,
                   ThermalPressure.Heavy, ThermalPressure.Critical,
                   ThermalPressure.Unknown}

  test "PowerMetrics string representation is formatted correctly":
    let info = getPowerMetrics()
    let str = $info

    # Basic info that should always be present
    check str.contains("Power Information:")
    check str.contains("Battery present:")
    check str.contains("Power source:")
    check str.contains("Status:")
    check str.contains("Low power mode:")
    check str.contains("Thermal pressure:")

    # Battery-specific info checks
    if info.isPresent:
      check str.contains("Battery level:")

      # Time remaining
      if info.timeRemaining.isSome():
        check str.contains("Time remaining:")

      # Time to full charge
      if info.timeToFull.isSome() and info.status == PowerStatus.Charging:
        check str.contains("Time to full charge:")

      # Battery health
      if info.health.isSome():
        check str.contains("Battery health:")

  test "Low power mode is a boolean value":
    let info = getPowerMetrics()
    check info.isLowPower in [true, false]

  test "Data consistency between multiple calls":
    # Create two snapshots and verify they have similar values
    let info1 = getPowerMetrics()
    os.sleep(10) # Brief pause to allow minimal change (in milliseconds)
    let info2 = getPowerMetrics()

    # Source and status should remain consistent during brief periods
    check info1.source == info2.source

    # Battery levels should be similar or identical in a brief period
    if info1.isPresent and info2.isPresent:
      # Allow small changes in battery percentage
      # Battery level change shouldn't exceed 0.5% in 10ms
      check almostEqual(info1.percentRemaining, info2.percentRemaining, 0.5)

  test "Stress test - multiple rapid calls":
    # Test the stability of the power API under repeated calls
    const numCalls = 10
    var errorCount = 0

    for i in 1..numCalls:
      try:
        let info = getPowerMetrics()
        check info.source in {PowerSource.AC, PowerSource.Battery,
            PowerSource.UPS, PowerSource.Unknown}
      except:
        inc errorCount

    check errorCount == 0 # Power API should handle repeated calls without errors

  test "Power status and source are logically consistent":
    let info = getPowerMetrics()

    # Test logical relationships between status and source
    if info.status == PowerStatus.ACPowered:
      check info.source == PowerSource.AC

    if info.source == PowerSource.Battery:
      check info.status in {PowerStatus.Charging, PowerStatus.Discharging,
          PowerStatus.Full}

    if not info.isPresent:
      check info.percentRemaining == 0.0 or info.status !=
          PowerStatus.Discharging

  test "Thermal pressure and power measures are related":
    let info = getPowerMetrics()
    let pressure = getThermalPressureLevel()

    # They should match
    check info.thermalPressure == pressure

  test "Format validation for energy and time values":
    let info = getPowerMetrics()

    # Battery percentage should be formatted as 0-100%
    check info.percentRemaining >= 0.0 and info.percentRemaining <= 100.0

    # Time values should be reasonable if present
    if info.timeRemaining.isSome():
      # Basic sanity check - time should be positive and under 24 hours
      check info.timeRemaining.get() > 0 and info.timeRemaining.get() < 24*60

    if info.timeToFull.isSome():
      check info.timeToFull.get() > 0 and info.timeToFull.get() < 12*60

    # Health check for battery health if available
    if info.health.isSome():
      let health = info.health.get()

      # Cycle count should be positive and under typical maximum (1000 is a typical max)
      check health.cycleCount >= 0 and health.cycleCount < 2000

      # Temperature should be reasonable for a battery (0-60°C)
      check health.temperature >= 0.0 and health.temperature < 60.0
