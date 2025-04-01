---
layout: doc
title: 🔌 API Reference
permalink: /docs/api/
---

## 🖥️ Core Functions

The DarwinMetrics API is designed to be safe, efficient, and thread-aware. All functions correctly handle memory management, particularly when dealing with Mach kernel interfaces. Thread-safe operations are implemented using locks where appropriate.

### CPU Information

```nim
proc getCpuInfo*(): CpuInfo {.raises: [DarwinError, DarwinVersionError].}
```

Returns detailed CPU information including architecture, cores, frequency, and current usage.
Supports both Apple Silicon and Intel processors.

```nim
proc getCpuUsage*(): CpuUsage {.raises: [DarwinError].}
```

Returns current CPU usage percentages across different states (user, system, idle, nice).

```nim
proc getPerCoreCpuLoadInfo*(): seq[HostCpuLoadInfo] {.raises: [DarwinError].}
```

Returns per-core CPU load information, with user/system/idle/nice tick counts for each CPU core.
Correctly manages memory allocated by Mach kernel functions.

### Load Average Monitoring

```nim
proc getLoadAverageAsync*(): Future[LoadAverage]
```

Asynchronously retrieves current system load averages. Thread-safe.

```nim
proc startLoadMonitoring*(history: LoadHistory, interval: float = 60.0): Future[void]
```

Starts monitoring load averages at the specified interval, storing samples in the provided history.

```nim
proc newLoadHistory*(maxSamples: int = DefaultMaxSamples): LoadHistory
```

Creates a new thread-safe load history tracker with the specified maximum sample size.

```nim
proc add*(history: LoadHistory, load: LoadAverage)
```

Adds a load average sample to the history in a thread-safe manner.

### Memory Statistics

```nim
proc getMemoryInfo*(): MemoryInfo
```

Returns system memory statistics including RAM and swap usage.

### Power Management

```nim
proc getPowerInfo*(): PowerInfo {.raises: [].}
```

Returns comprehensive power and battery information including battery presence, charge level,
power source, charging status, and estimated times for battery operation.

```nim
proc getBatteryPercentage*(): float {.raises: [].}
```

Returns the current battery percentage (0-100). On systems without batteries, returns 0.0.

```nim
proc isPowerAdapterConnected*(): bool {.raises: [].}
```

Checks if the system is connected to an external power source.
Returns true if on AC power, false if on battery.

```nim
proc getRemainingTime*(): Option[int] {.raises: [].}
```

Returns the estimated time remaining in minutes for battery operation.
If the system is on AC power or has no battery, returns None.

```nim
proc getBatteryHealth*(): Option[BatteryHealth] {.raises: [].}
```

Returns battery health information if available, including cycle count, condition, and capacity metrics.

```nim
proc getThermalPressureLevel*(): ThermalPressure {.raises: [].}
```

Returns the current thermal pressure level, indicating if the system is experiencing thermal issues.

### Temperature Sensors

```nim
proc getTemperature*(): TempInfo
```

Returns temperature readings from various system sensors.

### Network Statistics

```nim
proc getNetworkInfo*(): NetworkInfo
```

Returns network interface statistics and traffic information.

### Process Information

```nim
proc getProcessInfo*(pid: int): ProcessInfo
```

Returns detailed information about a specific process.

## 📊 Types

### CpuInfo

```nim
type CpuInfo* = object
  physicalCores*: int          ## Number of physical CPU cores
  logicalCores*: int           ## Number of logical CPU cores (including hyperthreading)
  architecture*: string        ## CPU architecture (e.g., "arm64" or "x86_64")
  model*: string              ## Machine model identifier
  brand*: string              ## CPU brand string
  frequency*: CpuFrequency    ## CPU frequency information
  usage*: CpuUsage           ## Current CPU usage information
```

### CpuFrequency

```nim
type CpuFrequency* = object
  nominal*: float             ## Nominal (base) frequency in MHz
  current*: Option[float]     ## Current frequency in MHz (if available)
  max*: Option[float]         ## Maximum frequency in MHz (if available)
  min*: Option[float]         ## Minimum frequency in MHz (if available)
```

### CpuUsage

```nim
type CpuUsage* = object
  user*: float                ## Percentage of time spent in user mode (0-100)
  system*: float              ## Percentage of time spent in system mode (0-100)
  idle*: float                ## Percentage of time spent idle (0-100)
  nice*: float                ## Percentage of time spent in nice priority (0-100)
  total*: float               ## Total CPU usage percentage (0-100)
```

### LoadAverage

```nim
type LoadAverage* = object
  oneMinute*: float          ## 1-minute load average
  fiveMinute*: float         ## 5-minute load average
  fifteenMinute*: float      ## 15-minute load average
  timestamp*: Time           ## When this measurement was taken
```

### LoadHistory

```nim
type LoadHistory* = ref object
  samples*: Deque[LoadAverage] ## Load average samples
  maxSamples*: int            ## Maximum number of samples to keep
  # Thread synchronization handled internally with locks
```

### PowerInfo

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

```nim
type PowerStatus* = enum
  Charging        ## Battery is currently charging
  Discharging     ## Battery is discharging (on battery power)
  Full            ## Battery is fully charged
  ACPowered       ## System is AC powered with no battery
  Unknown         ## Status cannot be determined
```

### PowerSource

```nim
type PowerSource* = enum
  Battery         ## Running on battery power
  AC              ## Running on AC power (mains electricity)
  UPS             ## Running on uninterruptible power supply
  Unknown         ## Power source cannot be determined
```

### BatteryHealth

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

```nim
type ThermalPressure* = enum
  Normal          ## System thermal state is normal
  Moderate        ## System under moderate thermal pressure
  Heavy           ## System under heavy thermal pressure
  Critical        ## System experiencing critical thermal issues
  Unknown         ## Thermal state cannot be determined
```

## 🛠️ Constants

```nim
const DefaultMaxSamples* = 60  ## Default number of load average samples to keep
```

## ⚠️ Error Types

```nim
type DarwinError* = object of Exception
  ## Raised when a Darwin-specific operation fails

type DarwinVersionError* = object of Exception
  ## Raised when running on an unsupported Darwin version

type PowerError* = object of Exception
  ## Raised when a power-related operation fails
```

## 🔗 See Also

- [💻 CPU Metrics Documentation](./cpu.html)
- [🔋 Power Metrics Documentation](./power.html)
- [📊 System Metrics Overview](./metrics.html)
- [⚙️ Configuration Options](./configuration.html)
