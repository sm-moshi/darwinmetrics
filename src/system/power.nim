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
## let powerInfo = getPowerInfo()
## echo "Battery present: ", powerInfo.isPresent
## if powerInfo.isPresent:
##   echo "Battery level: ", powerInfo.percentRemaining, "%"
##   echo "Power status: ", powerInfo.status
##
##   if powerInfo.timeRemaining.isSome:
##     echo "Time remaining: ", powerInfo.timeRemaining.get(), " minutes"
## ```
##
## Note: Some power management features require privileged access.

import std/[options, strformat, strutils]
import ../internal/[platform_darwin, power_types, mach_power]

export power_types

proc getPowerInfo*(): PowerInfo {.raises: [].} =
  ## Returns comprehensive power and battery information.
  ##
  ## This includes battery presence, charge level, power source,
  ## charging status, and estimated times for battery operation.
  ##
  ## On systems without batteries (like desktop Macs), `isPresent`
  ## will be false, and battery-specific fields will contain default values.
  ##
  ## Returns:
  ##   A `PowerInfo` object containing power system information
  ##
  ## Example:
  ##   ```nim
  ##   let info = getPowerInfo()
  ##   if info.isPresent:
  ##     echo "Battery at ", info.percentRemaining, "%"
  ##     if info.status == Charging:
  ##       echo "Charging - ", info.timeToFull.get(), " minutes to full charge"
  ##     else:
  ##       echo "On battery - ", info.timeRemaining.get(), " minutes remaining"
  ##   else:
  ##     echo "No battery present, running on AC power"
  ##   ```
  try:
    checkDarwinVersion()
    result = mach_power.getRawPowerInfo()
  except:
    result = PowerInfo(
      isPresent: false,
      status: PowerStatus.Unknown,
      source: PowerSource.Unknown,
      percentRemaining: 0.0,
      timeRemaining: none(int),
      timeToFull: none(int),
      health: none(BatteryHealth),
      isLowPower: false,
      thermalPressure: ThermalPressure.Unknown
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
  let info = getPowerInfo()
  if info.isPresent:
    result = info.percentRemaining
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
  let info = getPowerInfo()
  result = info.source == PowerSource.AC

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
  let info = getPowerInfo()
  if info.isPresent and info.status == PowerStatus.Discharging:
    result = info.timeRemaining
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
  let info = getPowerInfo()
  result = info.health

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
  let info = getPowerInfo()
  result = info.thermalPressure

proc `$`*(info: PowerInfo): string =
  ## String representation of power information
  var parts = @[fmt"Power Information:"]
  parts.add(fmt"  Battery present: {info.isPresent}")
  parts.add(fmt"  Power source: {info.source}")
  parts.add(fmt"  Status: {info.status}")

  if info.isPresent:
    parts.add(fmt"  Battery level: {info.percentRemaining:.1f}%")
    if info.timeRemaining.isSome:
      let mins = info.timeRemaining.get()
      parts.add(fmt"  Time remaining: {mins div 60}h {mins mod 60}m")
    if info.timeToFull.isSome and info.status == PowerStatus.Charging:
      let mins = info.timeToFull.get()
      parts.add(fmt"  Time to full charge: {mins div 60}h {mins mod 60}m")
    if info.health.isSome:
      let health = info.health.get()
      parts.add(fmt"  Battery health:")
      parts.add(fmt"    Cycle count: {health.cycleCount}")
      parts.add(fmt"    Condition: {health.condition}")
      parts.add(fmt"    Capacity: {(health.currentCapacity.float / health.designCapacity.float) * 100:.1f}%")

  parts.add(fmt"  Low power mode: {info.isLowPower}")
  parts.add(fmt"  Thermal pressure: {info.thermalPressure}")

  result = parts.join("\n")
