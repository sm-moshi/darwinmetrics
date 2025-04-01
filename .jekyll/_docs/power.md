---
layout: doc
title: 🔋 Power Metrics
permalink: /docs/power/
---

The power module provides comprehensive monitoring for battery status, power sources, and thermal information on macOS systems. This module allows applications to track battery levels, charging status, power source changes, and thermal conditions.

## Overview

The power module uses IOKit to retrieve battery and power management information, giving you access to:

- Battery charge level and health
- Power source (AC/battery/UPS)
- Charging status
- Time remaining on battery or time to full charge
- Low power mode status
- Thermal pressure level

## Core Types

### PowerInfo

The main information structure containing all power-related data:

```nim
type PowerInfo* = object
  isPresent*: bool         ## Whether battery is present
  status*: PowerStatus     ## Current power status
  source*: PowerSource     ## Current power source
  percentRemaining*: float ## Battery percentage (0-100)
  timeRemaining*: Option[int] ## Estimated minutes remaining on battery
  timeToFull*: Option[int] ## Estimated minutes until full charge
  health*: Option[BatteryHealth] ## Battery health if available
  isLowPower*: bool        ## Whether low power mode is active
  thermalPressure*: ThermalPressure ## Current thermal pressure level
```

### PowerStatus

Enum representing the current power status:

```nim
type PowerStatus* = enum
  Charging        ## Battery is currently charging
  Discharging     ## Battery is discharging (on battery power)
  Full            ## Battery is fully charged
  ACPowered       ## System is AC powered with no battery
  Unknown         ## Status cannot be determined
```

### PowerSource

Enum representing the power source:

```nim
type PowerSource* = enum
  Battery         ## Running on battery power
  AC              ## Running on AC power (mains electricity)
  UPS             ## Running on uninterruptible power supply
  Unknown         ## Power source cannot be determined
```

### BatteryHealth

Information about battery condition and health:

```nim
type BatteryHealth* = object
  cycleCount*: int         ## Battery charge cycles completed
  condition*: string       ## Condition (Normal, Poor, etc.)
  temperature*: float      ## Battery temperature in °C if available
  designCapacity*: int     ## Design capacity in mAh
  currentCapacity*: int    ## Current maximum capacity in mAh
  maxCapacity*: int        ## Maximum capacity in mAh
```

### ThermalPressure

Enum representing the system's thermal state:

```nim
type ThermalPressure* = enum
  Normal          ## System thermal state is normal
  Moderate        ## System under moderate thermal pressure
  Heavy           ## System under heavy thermal pressure
  Critical        ## System experiencing critical thermal issues
  Unknown         ## Thermal state cannot be determined
```

## API Functions

### getPowerInfo

```nim
proc getPowerInfo*(): PowerInfo {.raises: [].}
```

Returns comprehensive power and battery information. This includes battery presence, charge level, power source, charging status, and estimated times for battery operation.

On systems without batteries (like desktop Macs), `isPresent` will be false, and battery-specific fields will contain default values.

**Example:**

```nim
let info = getPowerInfo()
if info.isPresent:
  echo "Battery at ", info.percentRemaining, "%"
  if info.status == PowerStatus.Charging:
    echo "Charging - ", info.timeToFull.get(), " minutes to full charge"
  else:
    echo "On battery - ", info.timeRemaining.get(), " minutes remaining"
else:
  echo "No battery present, running on AC power"
```

### getBatteryPercentage

```nim
proc getBatteryPercentage*(): float {.raises: [].}
```

Returns the current battery percentage (0-100). On systems without batteries, returns 0.0.

**Example:**

```nim
let percent = getBatteryPercentage()
echo "Battery: ", percent, "%"
```

### isPowerAdapterConnected

```nim
proc isPowerAdapterConnected*(): bool {.raises: [].}
```

Checks if the system is connected to an external power source. Returns true if on AC power, false if on battery.

**Example:**

```nim
if isPowerAdapterConnected():
  echo "Connected to power adapter"
else:
  echo "Running on battery"
```

### getRemainingTime

```nim
proc getRemainingTime*(): Option[int] {.raises: [].}
```

Returns the estimated time remaining in minutes for battery operation. If the system is on AC power or has no battery, returns None.

**Example:**

```nim
let remaining = getRemainingTime()
if remaining.isSome():
  echo "Time remaining: ", remaining.get() div 60, " hours, ",
       remaining.get() mod 60, " minutes"
else:
  echo "Not on battery or time remaining unknown"
```

### getBatteryHealth

```nim
proc getBatteryHealth*(): Option[BatteryHealth] {.raises: [].}
```

Returns battery health information if available. This includes cycle count, condition, and capacity metrics.

**Example:**

```nim
let health = getBatteryHealth()
if health.isSome():
  let h = health.get()
  echo "Cycle count: ", h.cycleCount
  echo "Condition: ", h.condition
  echo "Capacity: ", (h.currentCapacity.float / h.designCapacity.float) * 100, "%"
else:
  echo "Battery health information not available"
```

### getThermalPressureLevel

```nim
proc getThermalPressureLevel*(): ThermalPressure {.raises: [].}
```

Returns the current thermal pressure level. This indicates if the system is experiencing thermal issues.

**Example:**

```nim
let thermal = getThermalPressureLevel()
case thermal
of ThermalPressure.Normal:
  echo "Thermal state is normal"
of ThermalPressure.Moderate:
  echo "System is experiencing moderate thermal pressure"
of ThermalPressure.Heavy:
  echo "System is experiencing heavy thermal pressure"
of ThermalPressure.Critical:
  echo "System is in critical thermal state"
of ThermalPressure.Unknown:
  echo "Thermal state cannot be determined"
```

## PowerInfo String Representation

The `PowerInfo` type implements a string conversion that produces a formatted representation of all power metrics:

```nim
let info = getPowerInfo()
echo $info
```

Example output:

```
Power Information:
  Battery present: true
  Power source: Battery
  Status: Discharging
  Battery level: 75.2%
  Time remaining: 3h 45m
  Battery health:
    Cycle count: 142
    Condition: Normal
    Capacity: 92.7%
  Low power mode: false
  Thermal pressure: Normal
```

## Implementation Details

The power module uses several IOKit and CoreFoundation APIs:

- `IOPSCopyPowerSourcesInfo` - For power source information
- `IOPSCopyPowerSourcesList` - To enumerate power sources
- `IOPSGetPowerSourceDescription` - To get detailed battery information

These functions are wrapped in a Nim-friendly interface that handles all memory management and error conditions correctly.

## Thread Safety

All functions in the power module are thread-safe and can be called from multiple threads simultaneously.

## See Also

- [CPU Metrics](./cpu.html)
- [Memory Metrics](./memory.html)
- [API Reference](./api.html)
