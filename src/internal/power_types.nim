## Power types module for Darwin systems.
##
## This module defines the core types used for power and battery metrics in Darwin-based systems.
## It provides type definitions for battery status, power sources, and health information
## to support the power metrics API.
##
## Example:
##
## .. code-block:: nim
##   # Check battery status
##   var info = PowerMetrics()
##   if info.isPresent:
##     echo "Battery level: ", info.percentRemaining, "%"
##
##   # Check if on AC power
##   if info.source == PowerSource.AC:
##     echo "Connected to power adapter"

import std/options

type
  PowerStatus* = enum
    ## Current power status as reported by the system.
    ## Indicates charging state and power connection status.
    Charging        ## Battery is currently charging
    Discharging     ## Battery is discharging (on battery power)
    Full            ## Battery is fully charged
    ACPowered       ## System is AC powered with no battery
    Unknown         ## Status cannot be determined

  PowerSource* = enum
    ## The current source of power for the system.
    ## Indicates whether running on battery, AC, or other power source.
    Battery         ## Running on battery power
    AC              ## Running on AC power (mains electricity)
    UPS             ## Running on uninterruptible power supply
    Unknown         ## Power source cannot be determined

  ThermalPressure* = enum
    ## System thermal state as reported by the Darwin kernel.
    ## Indicates the current thermal condition of the system.
    Normal          ## System thermal state is normal
    Moderate        ## System under moderate thermal pressure
    Heavy           ## System under heavy thermal pressure
    Critical        ## System experiencing critical thermal issues
    Unknown         ## Thermal state cannot be determined

  BatteryHealth* = object
    ## Battery health information including cycle count and condition.
    ##
    ## Provides detailed battery health metrics for monitoring
    ## battery performance and lifetime.
    cycleCount*: int         ## Battery charge cycles completed
    condition*: string       ## Condition (Normal, Poor, etc.)
    temperature*: float      ## Battery temperature in °C if available
    designCapacity*: int     ## Design capacity in mAh
    currentCapacity*: int    ## Current maximum capacity in mAh
    maxCapacity*: int        ## Maximum capacity in mAh

  PowerMetrics* = object
    ## Comprehensive power information structure combining
    ## battery status, charge level, and health metrics.
    isPresent*: bool         ## Whether battery is present
    status*: PowerStatus     ## Current power status
    source*: PowerSource     ## Current power source
    percentRemaining*: float ## Battery percentage (0-100)
    timeRemaining*: Option[int] ## Estimated minutes remaining on battery
    timeToFull*: Option[int] ## Estimated minutes until full charge
    health*: Option[BatteryHealth] ## Battery health if available
    isLowPower*: bool        ## Whether low power mode is active
    thermalPressure*: ThermalPressure ## Current thermal pressure level
    timestamp*: int64        ## Unix timestamp in nanoseconds

  PowerError* = object of CatchableError
    ## Error type for power-related operations.
    ## Provides detailed information about power operation failures.
    code*: int       ## Error code from the failed operation
    operation*: string  ## Name of the operation that failed
