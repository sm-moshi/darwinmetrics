---
layout: doc
title: 📊 Type Reference
permalink: /docs/types/
---

This page documents all the core types used in darwinmetrics.

## 💻 CPU Types

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

### HostCpuLoadInfo

```nim
type HostCpuLoadInfo* = object
  userTicks*: array[2, natural]    ## User CPU ticks
  systemTicks*: array[2, natural]  ## System CPU ticks
  idleTicks*: array[2, natural]    ## Idle CPU ticks
  niceTicks*: array[2, natural]    ## Nice priority CPU ticks
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

## 🧠 Memory Types

### MemoryInfo

```nim
type MemoryInfo* = object
  totalRam*: int64      ## Total RAM in bytes
  usedRam*: int64       ## Used RAM in bytes
  freeRam*: int64       ## Free RAM in bytes
  totalSwap*: int64     ## Total swap space in bytes
  usedSwap*: int64      ## Used swap space in bytes
  freeSwap*: int64      ## Free swap space in bytes
```

## ⚡ Power Types

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

## 🌡️ Temperature Types

### TempInfo

```nim
type TempInfo* = object
  cpuTemp*: float      ## CPU temperature in Celsius
  fanSpeed*: int       ## Fan speed in RPM
  gpuTemp*: float      ## GPU temperature in Celsius (if available)
```

## 🌐 Network Types

### NetworkInfo

```nim
type NetworkInfo* = object
  interfaces*: seq[NetworkInterface]  ## List of network interfaces
  bytesReceived*: int64              ## Total bytes received
  bytesSent*: int64                  ## Total bytes sent
```

### NetworkInterface

```nim
type NetworkInterface* = object
  name*: string        ## Interface name
  ipAddress*: string   ## IP address
  macAddress*: string  ## MAC address
  isActive*: bool      ## Whether the interface is active
```

## 📊 Process Types

### ProcessInfo

```nim
type ProcessInfo* = object
  pid*: int           ## Process ID
  name*: string       ## Process name
  cpuUsage*: float    ## CPU usage percentage
  memoryUsage*: int64 ## Memory usage in bytes
  status*: string     ## Process status (running/sleeping/etc)
```

## ⚠️ Error Types

### DarwinError

```nim
type DarwinError* = object of Exception
  ## Raised when a Darwin-specific operation fails
```

### DarwinVersionError

```nim
type DarwinVersionError* = object of Exception
  ## Raised when running on an unsupported Darwin version
```

## 🔧 Constants

```nim
const
  DefaultMaxSamples* = 60    ## Default number of load average samples to keep
  MaxSampleRate* = 1000      ## Maximum samples per second
  DefaultInterval* = 1.0     ## Default sampling interval in seconds
```

## 🔗 See Also

- [💻 CPU Metrics](./cpu.html)
- [🔌 API Reference](./api.html)
- [⚙️ Configuration](./configuration.html)
