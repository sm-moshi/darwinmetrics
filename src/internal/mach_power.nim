## Low-level power management module for Darwin systems.
##
## This module provides bindings to IOKit's power management APIs to retrieve
## battery and power information on macOS. It handles the CoreFoundation object
## lifecycle and converts raw power data into Nim types.
##
## The module primarily works with IOPowerSources API to extract power source
## details and system power states.
##
## Note: This is an internal module not meant for direct use. Use the high-level
## power module API instead.

import std/options
import power_types

# CoreFoundation and IOKit imports
{.passL: "-framework CoreFoundation -framework IOKit".}
{.pragma: cf, importc, header: "<CoreFoundation/CoreFoundation.h>".}
{.pragma: iokit, importc, header: "<IOKit/ps/IOPowerSources.h>".}
{.pragma: iopsskeys, importc, header: "<IOKit/ps/IOPSKeys.h>".}

# CoreFoundation types
type
  CFTypeRef* = pointer
  CFArrayRef* = pointer
  CFDictionaryRef* = pointer
  CFStringRef* = pointer
  CFNumberRef* = pointer
  CFBooleanRef* = pointer
  CFRunLoopSourceRef* = pointer

# IOPowerSources API
proc IOPSCopyPowerSourcesInfo(): CFTypeRef {.iokit.}
proc IOPSCopyPowerSourcesList(blob: CFTypeRef): CFArrayRef {.iokit.}
proc IOPSGetPowerSourceDescription(blob: CFTypeRef, ps: pointer): CFDictionaryRef {.iokit.}

# CoreFoundation API
proc CFRelease(cf: CFTypeRef) {.cf.}
proc CFRetain(cf: CFTypeRef): CFTypeRef {.cf.}
proc CFArrayGetCount(theArray: CFArrayRef): clong {.cf.}
proc CFArrayGetValueAtIndex(theArray: CFArrayRef, idx: clong): pointer {.cf.}
proc CFDictionaryGetValue(theDict: CFDictionaryRef, key: CFStringRef): pointer {.cf.}
proc CFStringGetCStringPtr(theString: CFStringRef, encoding: uint32): cstring {.cf.}
proc CFStringCreateWithCString(alloc: pointer, str: cstring, encoding: uint32): CFStringRef {.cf.}
proc CFBooleanGetValue(boolean: CFBooleanRef): bool {.cf.}
proc CFNumberGetValue(number: CFNumberRef, theType: int32, valuePtr: pointer): bool {.cf.}

# Constants
const
  kCFStringEncodingUTF8* = 0x08000100.uint32
  kCFNumberIntType* = 9.int32

# Keys for power source dictionaries
let
  kIOPSNameKey = CFStringCreateWithCString(nil, "Name", kCFStringEncodingUTF8)
  kIOPSTypeKey = CFStringCreateWithCString(nil, "Type", kCFStringEncodingUTF8)
  kIOPSPowerSourceStateKey = CFStringCreateWithCString(nil, "Power Source State", kCFStringEncodingUTF8)
  kIOPSIsChargingKey = CFStringCreateWithCString(nil, "Is Charging", kCFStringEncodingUTF8)
  kIOPSIsPresentKey = CFStringCreateWithCString(nil, "Is Present", kCFStringEncodingUTF8)
  kIOPSCurrentCapacityKey = CFStringCreateWithCString(nil, "Current Capacity", kCFStringEncodingUTF8)
  kIOPSMaxCapacityKey = CFStringCreateWithCString(nil, "Max Capacity", kCFStringEncodingUTF8)
  kIOPSDesignCapacityKey = CFStringCreateWithCString(nil, "Design Capacity", kCFStringEncodingUTF8)
  kIOPSTimeToEmptyKey = CFStringCreateWithCString(nil, "Time to Empty", kCFStringEncodingUTF8)
  kIOPSTimeToFullChargeKey = CFStringCreateWithCString(nil, "Time to Full Charge", kCFStringEncodingUTF8)
  kIOPSBatteryHealthKey = CFStringCreateWithCString(nil, "BatteryHealth", kCFStringEncodingUTF8)
  kIOPSBatteryHealthConditionKey = CFStringCreateWithCString(nil, "BatteryHealthCondition", kCFStringEncodingUTF8)
  kIOPSInternalBattery = CFStringCreateWithCString(nil, "InternalBattery", kCFStringEncodingUTF8)
  kIOPSACPower = CFStringCreateWithCString(nil, "AC Power", kCFStringEncodingUTF8)
  kIOPSCycleCountKey = CFStringCreateWithCString(nil, "Cycle Count", kCFStringEncodingUTF8)
  kIOPSTemperatureKey = CFStringCreateWithCString(nil, "Temperature", kCFStringEncodingUTF8)

proc getString(dict: CFDictionaryRef, key: CFStringRef): string =
  ## Retrieves a string value from a CFDictionary
  if dict == nil or key == nil:
    return ""

  let valueRef = CFDictionaryGetValue(dict, key)
  if valueRef == nil:
    return ""

  let cstr = CFStringGetCStringPtr(cast[CFStringRef](valueRef), kCFStringEncodingUTF8)
  if cstr == nil:
    return ""

  result = $cstr

proc getBoolean(dict: CFDictionaryRef, key: CFStringRef): bool =
  ## Retrieves a boolean value from a CFDictionary
  if dict == nil or key == nil:
    return false

  let valueRef = CFDictionaryGetValue(dict, key)
  if valueRef == nil:
    return false

  result = CFBooleanGetValue(cast[CFBooleanRef](valueRef))

proc getInteger(dict: CFDictionaryRef, key: CFStringRef): int =
  ## Retrieves an integer value from a CFDictionary
  if dict == nil or key == nil:
    return 0

  let valueRef = CFDictionaryGetValue(dict, key)
  if valueRef == nil:
    return 0

  var intValue: int32 = 0
  if CFNumberGetValue(cast[CFNumberRef](valueRef), kCFNumberIntType, addr intValue):
    result = int(intValue)
  else:
    result = 0

proc getThermalPressure*(): ThermalPressure =
  ## Gets the current thermal pressure level from the system
  ## For now, just return Normal as we don't have direct access to NSProcessInfo
  return ThermalPressure.Normal

proc isLowPowerMode*(): bool =
  ## Checks if low power mode is enabled on the system
  ## For now, return false as we don't have direct access to NSProcessInfo
  return false

proc mapPowerSource(sourceType: string): PowerSource =
  ## Maps a power source string to the PowerSource enum
  if sourceType == "InternalBattery":
    return PowerSource.Battery
  elif sourceType == "AC Power":
    return PowerSource.AC
  elif sourceType == "UPS":
    return PowerSource.UPS
  else:
    return PowerSource.Unknown

proc mapPowerStatus(source: PowerSource, isCharging: bool, percentage: float): PowerStatus =
  ## Maps power source information to a PowerStatus enum value
  if source == PowerSource.AC and not isCharging:
    return PowerStatus.ACPowered

  if isCharging:
    if percentage >= 95.0:
      return PowerStatus.Full
    else:
      return PowerStatus.Charging
  else:
    return PowerStatus.Discharging

proc getBatteryHealth(dict: CFDictionaryRef): Option[BatteryHealth] =
  ## Extracts battery health information from a power source dictionary
  if dict == nil:
    return none(BatteryHealth)

  let cycleCount = getInteger(dict, kIOPSCycleCountKey)
  if cycleCount <= 0:
    # If we can't get cycle count, battery health info is likely unavailable
    return none(BatteryHealth)

  var health = BatteryHealth(
    cycleCount: cycleCount,
    condition: getString(dict, kIOPSBatteryHealthConditionKey),
    temperature: 0.0,  # Convert from int if available
    designCapacity: getInteger(dict, kIOPSDesignCapacityKey),
    currentCapacity: getInteger(dict, kIOPSCurrentCapacityKey),
    maxCapacity: getInteger(dict, kIOPSMaxCapacityKey)
  )

  # Convert temperature from raw value if available
  let tempRaw = getInteger(dict, kIOPSTemperatureKey)
  if tempRaw > 0:
    health.temperature = float(tempRaw) / 100.0  # Convert to degrees

  # Set meaningful defaults if values are missing
  if health.condition.len == 0:
    health.condition = "Unknown"

  if health.maxCapacity <= 0:
    health.maxCapacity = 100

  if health.currentCapacity <= 0:
    health.currentCapacity = health.maxCapacity

  if health.designCapacity <= 0:
    health.designCapacity = health.maxCapacity

  result = some(health)

proc getRawPowerMetrics*(): PowerMetrics =
  ## Retrieves raw power information from the system using IOPowerSources API

  # Create default result with safe values
  result = PowerMetrics(
    isPresent: false,
    status: PowerStatus.Unknown,
    source: PowerSource.Unknown,
    percentRemaining: 0.0,
    timeRemaining: none(int),
    timeToFull: none(int),
    health: none(BatteryHealth),
    isLowPower: isLowPowerMode(),
    thermalPressure: getThermalPressure(),
    timestamp: 0
  )

  # Get power sources info
  let powerSourcesInfo = IOPSCopyPowerSourcesInfo()
  if powerSourcesInfo == nil:
    return result

  defer: CFRelease(powerSourcesInfo)

  # Get list of power sources
  let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo)
  if powerSources == nil:
    return result

  defer: CFRelease(powerSources)

  # Check if we have any power sources
  let count = CFArrayGetCount(powerSources)
  if count <= 0:
    result.source = PowerSource.AC
    result.status = PowerStatus.ACPowered
    return result

  # Process first power source (typically we only care about the main one)
  let powerSource = CFArrayGetValueAtIndex(powerSources, 0)
  let description = IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource)
  if description == nil:
    return result

  # Extract power source type
  let sourceType = getString(description, kIOPSTypeKey)
  result.source = mapPowerSource(sourceType)

  # Check if it's a battery and if it's present
  result.isPresent = result.source == PowerSource.Battery and
                     getBoolean(description, kIOPSIsPresentKey)

  # If battery present, get detailed information
  if result.isPresent:
    let isCharging = getBoolean(description, kIOPSIsChargingKey)
    let currentCapacity = getInteger(description, kIOPSCurrentCapacityKey)
    let maxCapacity = getInteger(description, kIOPSMaxCapacityKey)

    # Calculate percentage
    if maxCapacity > 0:
      result.percentRemaining = float(currentCapacity) / float(maxCapacity) * 100.0

    # Map to power status
    result.status = mapPowerStatus(result.source, isCharging, result.percentRemaining)

    # Get time remaining/to full
    if isCharging:
      let timeToFull = getInteger(description, kIOPSTimeToFullChargeKey)
      if timeToFull > 0:
        result.timeToFull = some(timeToFull)
    else:
      let timeRemaining = getInteger(description, kIOPSTimeToEmptyKey)
      if timeRemaining > 0:
        result.timeRemaining = some(timeRemaining)

    # Get battery health information
    result.health = getBatteryHealth(description)

  # Get low power mode and thermal pressure
  result.isLowPower = isLowPowerMode()
  result.thermalPressure = getThermalPressure()

  return result
