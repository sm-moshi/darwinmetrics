## Power metrics module for Darwin
##
## This module provides access to battery and power information on Darwin-based
## systems (macOS). It offers functionality to:
##
## * Get battery status and charge level
## * Check charging state and estimated time remaining
## * Get battery health information
## * Detect power source (AC vs battery)
## * Monitor thermal pressure
##
## Example:
##
## ```nim
## import darwinmetrics/system/power
##
## # Get comprehensive power information
## let metrics = getPowerMetrics()
## echo "Battery present: ", metrics.isPresent
## if metrics.isPresent:
##   echo "Battery level: ", metrics.percentRemaining, "%"
##   echo "Power status: ", metrics.status
##
##   if metrics.timeRemaining.isSome:
##     echo "Time remaining: ", metrics.timeRemaining.get(), " minutes"
## ```
##
## Note: Some power management features require privileged access.

import std/[options, strformat, strutils, times]
import ../internal/[platform_darwin, power_types, mach_power]

export power_types.PowerMetrics, power_types.PowerStatus, power_types.PowerSource,
       power_types.ThermalPressure, power_types.BatteryHealth

proc getPowerMetrics*(): PowerMetrics {.raises: [].} =
  ## Returns comprehensive power and battery information.
  ##
  ## This includes battery presence, charge level, power source,
  ## charging status, and estimated times for battery operation.
  ##
  ## On systems without batteries (like desktop Macs), `isPresent`
  ## will be false, and battery-specific fields will contain default values.
  ##
  ## Returns:
  ##   A `PowerMetrics` object containing power system information
  ##
  ## Example:
  ##   ```nim
  ##   let metrics = getPowerMetrics()
  ##   if metrics.isPresent:
  ##     echo "Battery at ", metrics.percentRemaining, "%"
  ##     if metrics.status == Charging:
  ##       echo "Charging - ", metrics.timeToFull.get(), " minutes to full charge"
  ##     else:
  ##       echo "On battery - ", metrics.timeRemaining.get(), " minutes remaining"
  ##   else:
  ##     echo "No battery present, running on AC power"
  ##   ```
  try:
    checkDarwinVersion()
    var metrics = mach_power.getRawPowerMetrics()
    metrics.timestamp = getTime().toUnix * 1_000_000_000
    result = metrics
  except:
    result = PowerMetrics(
      isPresent: false,
      status: PowerStatus.Unknown,
      source: PowerSource.Unknown,
      percentRemaining: 0.0,
      timeRemaining: none(int),
      timeToFull: none(int),
      health: none(BatteryHealth),
      isLowPower: false,
      thermalPressure: ThermalPressure.Unknown,
      timestamp: getTime().toUnix * 1_000_000_000
    )

proc getBatteryPercentage*(): float {.raises: [].} =
  ## Returns the current battery percentage (0-100).
  ##
  ## On systems without batteries, returns 0.0.
  ##
  ## Returns:
  ##   Battery percentage between 0 and 100
  ##
  ## Example:
  ##   ```nim
  ##   let percent = getBatteryPercentage()
  ##   echo "Battery: ", percent, "%"
  ##   ```
  let metrics = getPowerMetrics()
  if metrics.isPresent:
    result = metrics.percentRemaining
  else:
    result = 0.0

proc isPowerAdapterConnected*(): bool {.raises: [].} =
  ## Checks if the system is connected to an external power source.
  ##
  ## Returns true if on AC power, false if on battery.
  ##
  ## Returns:
  ##   Boolean indicating AC power connection
  ##
  ## Example:
  ##   ```nim
  ##   if isPowerAdapterConnected():
  ##     echo "Connected to power adapter"
  ##   else:
  ##     echo "Running on battery"
  ##   ```
  let metrics = getPowerMetrics()
  result = metrics.source == PowerSource.AC

proc getRemainingTime*(): Option[int] {.raises: [].} =
  ## Returns the estimated time remaining in minutes for battery operation.
  ##
  ## If the system is on AC power or has no battery, returns None.
  ##
  ## Returns:
  ##   Option[int] with minutes remaining or None
  ##
  ## Example:
  ##   ```nim
  ##   let remaining = getRemainingTime()
  ##   if remaining.isSome:
  ##     echo "Time remaining: ", remaining.get() div 60, " hours, ",
  ##          remaining.get() mod 60, " minutes"
  ##   else:
  ##     echo "Not on battery or time remaining unknown"
  ##   ```
  let metrics = getPowerMetrics()
  if metrics.isPresent and metrics.status == PowerStatus.Discharging:
    result = metrics.timeRemaining
  else:
    result = none(int)

proc getBatteryHealth*(): Option[BatteryHealth] {.raises: [].} =
  ## Returns battery health information if available.
  ##
  ## This includes cycle count, condition, and capacity metrics.
  ##
  ## Returns:
  ##   Option[BatteryHealth] with health information or None if unavailable
  ##
  ## Example:
  ##   ```nim
  ##   let health = getBatteryHealth()
  ##   if health.isSome:
  ##     let h = health.get()
  ##     echo "Cycle count: ", h.cycleCount
  ##     echo "Condition: ", h.condition
  ##     echo "Capacity: ", (h.currentCapacity / h.designCapacity) * 100, "%"
  ##   else:
  ##     echo "Battery health information not available"
  ##   ```
  let metrics = getPowerMetrics()
  result = metrics.health

proc getThermalPressureLevel*(): ThermalPressure {.raises: [].} =
  ## Returns the current thermal pressure level.
  ##
  ## This indicates if the system is experiencing thermal issues.
  ##
  ## Returns:
  ##   ThermalPressure enum value
  ##
  ## Example:
  ##   ```nim
  ##   let thermal = getThermalPressureLevel()
  ##   case thermal
  ##   of Normal: echo "Thermal state is normal"
  ##   of Moderate: echo "System is experiencing moderate thermal pressure"
  ##   of Heavy: echo "System is experiencing heavy thermal pressure"
  ##   of Critical: echo "System is in critical thermal state"
  ##   of Unknown: echo "Thermal state cannot be determined"
  ##   ```
  let metrics = getPowerMetrics()
  result = metrics.thermalPressure

proc `$`*(metrics: PowerMetrics): string =
  ## String representation of power information
  var parts = @[fmt"Power Information:"]
  parts.add(fmt"  Battery present: {metrics.isPresent}")
  parts.add(fmt"  Power source: {metrics.source}")
  parts.add(fmt"  Status: {metrics.status}")
  parts.add(fmt"  Low power mode: {metrics.isLowPower}")
  parts.add(fmt"  Thermal pressure: {metrics.thermalPressure}")

  if metrics.isPresent:
    parts.add(fmt"  Battery level: {metrics.percentRemaining:.1f}%")
    if metrics.timeRemaining.isSome:
      let mins = metrics.timeRemaining.get()
      parts.add(fmt"  Time remaining: {mins div 60}h {mins mod 60}m")
    if metrics.timeToFull.isSome and metrics.status == PowerStatus.Charging:
      let mins = metrics.timeToFull.get()
      parts.add(fmt"  Time to full charge: {mins div 60}h {mins mod 60}m")
    if metrics.health.isSome:
      let health = metrics.health.get()
      parts.add(fmt"  Battery health:")
      parts.add(fmt"    Cycle count: {health.cycleCount}")
      parts.add(fmt"    Condition: {health.condition}")
      if health.temperature > 0:
        parts.add(fmt"    Temperature: {health.temperature:.1f}°C")
      parts.add(fmt"    Design capacity: {health.designCapacity} mAh")
      parts.add(fmt"    Current capacity: {health.currentCapacity} mAh")
      parts.add(fmt"    Maximum capacity: {health.maxCapacity} mAh")

  result = parts.join("\n")
