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

### PowerMetrics

The main information structure containing all power-related data:

```nim
type PowerMetrics* = object
  isPresent*: bool         ## Whether battery is present
  status*: PowerStatus     ## Current power status
  source*: PowerSource     ## Current power source
  percentRemaining*: float ## Battery percentage (0-100)
  timeRemaining*: Option[int] ## Estimated minutes remaining on battery
  timeToFull*: Option[int] ## Estimated minutes until full charge
  health*: Option[BatteryHealth] ## Battery health if available
  isLowPower*: bool        ## Whether low power mode is active
  thermalPressure*: ThermalPressure ## Current thermal pressure level
  timestamp*: int64        ## When these metrics were collected (nanoseconds)
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

### getPowerMetrics

```nim
proc getPowerMetrics*(): PowerMetrics {.raises: [].}
```

Returns comprehensive power and battery information. This includes battery presence, charge level, power source, charging status, and estimated times for battery operation.

On systems without batteries (like desktop Macs), `isPresent` will be false, and battery-specific fields will contain default values.

**Example:**

```nim
let metrics = getPowerMetrics()
if metrics.isPresent:
  echo "Battery at ", metrics.percentRemaining, "%"
  if metrics.status == PowerStatus.Charging:
    echo "Charging - ", metrics.timeToFull.get(), " minutes to full charge"
  else:
    echo "On battery - ", metrics.timeRemaining.get(), " minutes remaining"
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

## PowerMetrics String Representation

The `PowerMetrics` type implements a string conversion that produces a formatted representation of all power metrics:

```nim
let metrics = getPowerMetrics()
echo $metrics
```

Example output:

```
Power Information:
  Battery present: true
  Power source: Battery
  Status: Discharging
  Low power mode: false
  Thermal pressure: Normal
  Battery level: 75.2%
  Time remaining: 3h 45m
  Battery health:
    Cycle count: 142
    Condition: Normal
    Temperature: 35.2°C
    Design capacity: 5000 mAh
    Current capacity: 4635 mAh
    Maximum capacity: 4800 mAh
  Timestamp: 2025-04-04 14:30:45
```

## Implementation Details

The power module uses several IOKit and CoreFoundation APIs:

- `IOPSCopyPowerSourcesInfo` - For power source information
- `IOPSCopyPowerSourcesList` - To enumerate power sources
- `IOPSGetPowerSourceDescription` - To get detailed battery information

These functions are wrapped in a Nim-friendly interface that handles all memory management and error conditions correctly.

## Thread Safety

All functions in the power module are thread-safe and can be called from multiple threads simultaneously. The module uses internal synchronization to ensure consistent access to system power information.

## Error Handling

The module implements robust error handling:

```nim
type PowerError* = object of Exception
```

- Power-related errors are captured in `PowerError`
- Invalid power metrics raise descriptive errors
- Battery information failures include error codes
- Resource cleanup is guaranteed even on errors

## See Also

- [CPU Metrics](./cpu.html)
- [Memory Metrics](./memory.html)
- [API Reference](./api.html)
