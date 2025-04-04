---
layout: doc
title: 📊 Type Reference
permalink: /docs/types/
---

This page documents all the core types used in darwinmetrics.

## 💻 CPU Types

### CpuMetrics

```nim
type CpuMetrics* = object
  physicalCores*: int          ## Number of physical CPU cores
  logicalCores*: int           ## Number of logical CPU cores (including hyperthreading)
  architecture*: string        ## CPU architecture (e.g., "arm64" or "x86_64")
  model*: string              ## Machine model identifier
  brand*: string              ## CPU brand string
  frequency*: CpuFrequency    ## CPU frequency information
  usage*: CpuUsage           ## Current CPU usage information
  loadAverage*: LoadAverage   ## Current load average information
  timestamp*: int64          ## When these metrics were collected (nanoseconds)
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
  ## Tracks CPU load average history with thread-safe access
  samples*: Deque[LoadAverage] ## Load average samples
  maxSamples*: int            ## Maximum number of samples to keep
```

### CpuUsageHistory

```nim
type CpuUsageHistory* = ref object
  ## Tracks CPU usage history with thread-safe access
  samples*: Deque[CpuUsage]   ## CPU usage samples
  maxSamples*: int            ## Maximum number of samples to keep
```

### PerCoreHistory

```nim
type PerCoreHistory* = ref object
  ## Tracks per-core CPU load information history with thread-safe access
  samples*: Deque[seq[HostCpuLoadInfo]] ## Per-core load samples
  maxSamples*: int                      ## Maximum number of samples to keep
```

## 🧠 Memory Types

### MemoryMetrics

```nim
type MemoryMetrics* = object
  totalPhysical*: uint64     ## Total physical memory in bytes
  availablePhysical*: uint64 ## Available physical memory in bytes
  usedPhysical*: uint64      ## Used physical memory in bytes
  pressureLevel*: MemoryPressure  ## Current memory pressure level
  pageSize*: uint32          ## System page size in bytes
  pagesFree*: uint64        ## Number of free pages
  pagesActive*: uint64      ## Number of active pages in use
  pagesInactive*: uint64    ## Number of inactive pages that can be reclaimed
  pagesWired*: uint64       ## Number of wired (locked) pages
  pagesCompressed*: uint64  ## Number of compressed pages
  timestamp*: int64         ## When these metrics were collected (nanoseconds)
```

### ProcessMemoryInfo

```nim
type ProcessMemoryInfo* = object
  virtualSize*: uint64     ## Virtual memory size in bytes
  residentSize*: uint64    ## Resident set size (RSS) in bytes
  residentPeak*: uint64    ## Peak resident size in bytes
```

### MemoryPressure

```nim
type MemoryPressure* = enum
  Normal     ## Normal memory pressure - system operating normally
  Warning    ## Warning level - system beginning to experience memory pressure
  Critical   ## Critical level - system under significant memory pressure
  Error      ## Error state - unable to determine memory pressure
```

## ⚡ Power Types

### PowerMetrics

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

## 🌐 Network Types

### NetworkMetrics

```nim
type NetworkMetrics* = object
  interfaces*: seq[NetworkInfo]  ## List of network interfaces with stats
  timestamp*: int64             ## When these metrics were collected (nanoseconds)
```

### NetworkInfo

```nim
type NetworkInfo* = object
  networkInterface*: NetworkInterfaceInfo  ## Interface information
  stats*: NetworkStats                     ## Interface statistics
```

### NetworkInterfaceInfo

```nim
type NetworkInterfaceInfo* = object
  name*: string        ## Interface name
  displayName*: string ## User-friendly interface name
  macAddress*: string  ## MAC address
  ipv4Address*: string ## IPv4 address
  ipv6Address*: string ## IPv6 address
  interfaceType*: NetworkInterfaceType ## Type of interface
  isUp*: bool         ## Whether the interface is up
```

### NetworkStats

```nim
type NetworkStats* = object
  bytesReceived*: int64    ## Total bytes received
  bytesSent*: int64        ## Total bytes sent
  packetsReceived*: int64  ## Total packets received
  packetsSent*: int64      ## Total packets sent
```

### NetworkInterfaceType

```nim
type NetworkInterfaceType* = enum
  nitUnknown      ## Unknown interface type
  nitEthernet     ## Ethernet interface
  nitWiFi         ## WiFi interface
  nitLoopback     ## Loopback interface
  nitVirtual      ## Virtual interface
  nitBluetooth    ## Bluetooth interface
  nitCellular     ## Cellular interface
```

## 📊 Process Types

### ProcessMetrics

```nim
type ProcessMetrics* = object
  info*: ProcessInfo               ## Basic process information
  resources*: ProcessResourceUsage ## Resource usage statistics
  threads*: int                    ## Number of threads
  openFiles*: int                  ## Number of open files
  timestamp*: int64               ## When these metrics were collected (nanoseconds)
```

### ProcessInfo

```nim
type ProcessInfo* = object
  pid*: int           ## Process ID
  ppid*: int          ## Parent process ID
  name*: string       ## Process name
  executable*: string ## Full path to executable
  status*: ProcessStatus ## Current process status
  startTime*: int64   ## Process start time (Unix timestamp)
```

### ProcessResourceUsage

```nim
type ProcessResourceUsage* = object
  cpuUser*: float     ## CPU time in user mode (seconds)
  cpuSystem*: float   ## CPU time in system mode (seconds)
  cpuTotal*: float    ## Total CPU time (seconds)
  cpuPercent*: float  ## CPU usage percentage (0-100)
  memoryRSS*: int64   ## Resident set size in bytes
  memoryVirtual*: int64 ## Virtual memory size in bytes
  memoryShared*: int64  ## Shared memory size in bytes
  ioRead*: int64      ## Bytes read from disk
  ioWrite*: int64     ## Bytes written to disk
```

### ProcessStatus

```nim
type ProcessStatus* = enum
  psUnknown    ## Unknown process status
  psRunning    ## Process is running
  psSleeping   ## Process is sleeping
  psStopped    ## Process is stopped
  psZombie     ## Process is zombie
  psDead       ## Process is dead
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

### MemoryError

```nim
type MemoryError* = object of Exception
  ## Raised when a memory-related operation fails
```

## 🔧 Constants

```nim
const
  DefaultMaxSamples* = 60    ## Default number of load average samples to keep
  DefaultCpuSamples* = 60    ## Default number of CPU usage samples to keep
  KB* = 1024'u64            ## Kilobyte in bytes
  MB* = KB * 1024           ## Megabyte in bytes
  GB* = MB * 1024           ## Gigabyte in bytes
  TB* = GB * 1024           ## Terabyte in bytes
```

## 🔗 See Also

- [💻 CPU Metrics](./cpu.html)
- [🔌 API Reference](./api.html)
- [⚙️ Configuration](./configuration.html)
