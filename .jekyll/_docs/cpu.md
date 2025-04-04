---
title: 💻 CPU Metrics
description: Documentation for CPU metrics collection in darwinmetrics
layout: doc
nav_order: 3
---

The CPU metrics module provides detailed information about your system's CPU, including frequency, load averages, and core counts. It supports both Apple Silicon (M1/M2) and Intel processors with graceful fallbacks.

## 🚀 Quick Start

```nim
import darwinmetrics/system/cpu
import chronos

proc main() {.async.} =
  # Get CPU metrics
  let metrics = await getCpuMetrics()
  echo metrics

  # Get CPU usage
  let usage = await getCpuUsage()
  echo "Total CPU usage: ", usage.total, "%"

  # Monitor per-core statistics
  let coreStats = await getPerCoreCpuLoadInfo()
  for i, core in coreStats:
    echo "Core ", i, " usage: ", core

  # Track load averages
  let history = newLoadHistory()
  let load = await getLoadAverage()
  echo "1-minute load: ", load.oneMinute

  # Start continuous monitoring
  let usageHistory = newCpuUsageHistory()
  asyncCheck startCpuUsageTracking(usageHistory)

waitFor main()
```

## 📊 CPU Metrics

The `CpuMetrics` object provides comprehensive CPU details:

```nim
type CpuMetrics* = object
  physicalCores*: int        # Physical CPU cores
  logicalCores*: int         # Logical cores (including hyperthreading)
  architecture*: string      # CPU architecture (e.g., "arm64", "x86_64")
  model*: string            # CPU model identifier
  brand*: string           # Full CPU brand string
  frequency*: CpuFrequency  # Detailed frequency information
  usage*: CpuUsage         # Current CPU usage statistics
  loadAverage*: LoadAverage # Current load average information
  timestamp*: int64        # Timestamp in nanoseconds
```

### 🔍 Field Details

- `physicalCores`: Number of physical CPU cores
- `logicalCores`: Number of logical CPU cores (including hyperthreading)
- `architecture`: CPU architecture (e.g., "arm64" for Apple Silicon, "x86_64" for Intel)
- `model`: CPU model identifier (e.g., "MacBookPro18,2")
- `brand`: Full CPU brand string (e.g., "Apple M2 Pro")
- `frequency`: CPU frequency information
- `usage`: Current CPU usage statistics with user, system, idle, and nice percentages
- `loadAverage`: Current system load averages
- `timestamp`: When these metrics were collected (nanoseconds since Unix epoch)

## ⚡ CPU Frequency

The `CpuFrequency` object provides detailed frequency information:

```nim
type CpuFrequency* = object
  nominal*: float           # Base frequency in MHz
  current*: Option[float]   # Current frequency in MHz (if available)
  min*: Option[float]       # Minimum frequency in MHz (if available)
  max*: Option[float]       # Maximum frequency in MHz (if available)
```

### 🖥️ Platform-Specific Behaviour

#### 🍎 Apple Silicon (M1/M2)

- Nominal frequency: Base frequency (3.5 GHz for M2, 3.2 GHz for M1)
- Min frequency: 600 MHz (fixed)
- Max frequency: Matches nominal frequency
- Current frequency: Not available in user mode (requires powermetrics with root)

#### 💻 Intel Processors

- Primary: Retrieves frequency via sysctl
- Fallback: Parses brand string if sysctl fails
- Defaults: Provides reasonable values if exact data unavailable
- Current frequency: Not available in user mode

## 📈 Load Averages

The `LoadAverage` object provides system load information:

```nim
type LoadAverage* = object
  oneMinute*: float        # 1-minute load average
  fiveMinute*: float       # 5-minute load average
  fifteenMinute*: float    # 15-minute load average
  timestamp*: Time         # When this measurement was taken
```

### 📊 Historical Load Tracking

The `LoadHistory` type maintains a chronological record of load averages:

```nim
# Create a history tracker with default 60 samples
let history = newLoadHistory(maxSamples = DefaultMaxSamples)

# Start tracking load averages every minute
asyncCheck startLoadTracking(history)

# Or manually add samples
let load = await getLoadAverage()
history.add(load)
```

## 🧮 CPU Usage Tracking

The module provides comprehensive CPU usage tracking:

```nim
# Get current CPU usage
let usage = await getCpuUsage()
echo "Total CPU usage: ", usage.total, "%"
echo "User: ", usage.user, "%"
echo "System: ", usage.system, "%"
echo "Idle: ", usage.idle, "%"

# Track CPU usage history
let usageHistory = newCpuUsageHistory(maxSamples = DefaultCpuSamples)
asyncCheck startCpuUsageTracking(usageHistory)
```

## 🔢 Per-Core CPU Metrics

The `getPerCoreCpuLoadInfo()` function provides detailed CPU usage statistics for each individual core:

```nim
let coreStats = await getPerCoreCpuLoadInfo()
echo "Number of cores reporting: ", coreStats.len

# Access individual core data
for i, core in coreStats:
  echo "Core ", i, " user: ", core.userTicks[0], " system: ", core.systemTicks[0]

# Track per-core history
let coreHistory = newPerCoreHistory()
asyncCheck startPerCoreTracking(coreHistory)
```

This function properly manages memory allocated by the Mach kernel, ensuring no leaks occur when retrieving per-core metrics.

### 🔒 Thread Safety

The CPU module provides thread-safe operations:

- All history types (`LoadHistory`, `CpuUsageHistory`, `PerCoreHistory`) use locks for safe concurrent access
- `add()` methods can be called from multiple threads
- All Mach kernel bindings are properly managed for memory safety
- Asynchronous operations are thread-safe
- Per-core statistics collection is thread-safe

## ⚠️ Error Handling

The module implements graceful fallbacks and clear error handling:

- Invalid/unavailable values: Represented as `none(float)` in `CpuFrequency`
- Core counts: Validated to be positive numbers
- Architecture strings: Validated against known values ("arm64", "x86_64")
- Mach kernel errors: Properly propagated with descriptive messages
- Memory management: Automatic cleanup of Mach kernel resources

## 📝 Examples

### 🔍 Basic CPU Information

```nim
proc main() {.async.} =
  let metrics = await getCpuMetrics()
  echo "CPU: ", metrics.brand
  echo "Cores: ", metrics.physicalCores, " physical, ", metrics.logicalCores, " logical"
  echo "Architecture: ", metrics.architecture
  echo "Load averages: ", metrics.loadAverage

waitFor main()
```

### 📊 Continuous Monitoring

```nim
proc main() {.async.} =
  # Setup history trackers
  let loadHistory = newLoadHistory()
  let usageHistory = newCpuUsageHistory()
  let coreHistory = newPerCoreHistory()

  # Start tracking with different intervals
  asyncCheck startLoadTracking(loadHistory)
  asyncCheck startCpuUsageTracking(usageHistory)
  asyncCheck startPerCoreTracking(coreHistory)

  # Your monitoring logic here
  while true:
    await sleepAsync(seconds(1))
    echo "Load samples: ", loadHistory.len
    echo "Usage samples: ", usageHistory.len
    echo "Core samples: ", coreHistory.len

waitFor main()
```

## 🔧 Platform Support

- **macOS**: Full support for both Apple Silicon and Intel processors
- **Minimum Version**: macOS 12.0+ (Darwin 21.0+)
- **Architecture**: Native support for arm64 and x86_64
- **Privileges**: User-mode operation (no root required)
- **Memory Safety**: Automatic resource management
- **Async Support**: Built on Chronos for efficient async operations

## 🔗 See Also

- [💾 Memory Metrics](./memory.html)
- [🔋 Power Metrics](./power.html)
- [⚙️ Configuration Options](./configuration.html)
- [📚 API Reference](./api.html)
