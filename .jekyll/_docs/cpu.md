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

# Get CPU information
let metrics = getCpuMetrics().await
echo metrics.info

# Get load averages
echo metrics.loadAverage

# Monitor per-core statistics
let coreStats = getPerCoreCpuLoadInfo()
for i, core in coreStats:
  echo "Core ", i, " usage: ", core
```

## 📊 CPU Information

The `CpuInfo` object provides comprehensive CPU details:

```nim
type CpuInfo* = object
  physicalCores*: int        # Physical CPU cores
  logicalCores*: int         # Logical cores (including hyperthreading)
  architecture*: string      # CPU architecture (e.g., "arm64", "x86_64")
  model*: string            # CPU model identifier
  brand*: string           # Full CPU brand string
  frequency*: CpuFrequency  # Detailed frequency information
  usage*: CpuUsage         # Current CPU usage statistics
```

### 🔍 Field Details

- `physicalCores`: Number of physical CPU cores
- `logicalCores`: Number of logical CPU cores (including hyperthreading)
- `architecture`: CPU architecture (e.g., "arm64" for Apple Silicon, "x86_64" for Intel)
- `model`: CPU model identifier (e.g., "MacBookPro18,2")
- `brand`: Full CPU brand string (e.g., "Apple M2 Pro")
- `frequency`: CPU frequency information
- `usage`: Current CPU usage statistics with user, system, idle, and nice percentages

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
  oneMinute*: float
  fiveMinutes*: float
  fifteenMinutes*: float
```

### 📊 Historical Load Tracking

The `LoadHistory` type maintains a chronological record of load averages:

```nim
let history = newLoadHistory(maxSamples = 60)  # Keep last 60 samples
history.add(loadAvg)
```

## 🧮 Per-Core CPU Metrics

The `getPerCoreCpuLoadInfo()` function provides detailed CPU usage statistics for each individual core:

```nim
let coreStats = getPerCoreCpuLoadInfo()
echo "Number of cores reporting: ", coreStats.len

# Access individual core data
for i, core in coreStats:
  echo "Core ", i, " user: ", core.userTicks[0], " system: ", core.systemTicks[0]
```

This function properly manages memory allocated by the Mach kernel, ensuring no leaks occur when retrieving per-core metrics.

### 🔒 Thread Safety

The CPU module provides thread-safe operations:

- `LoadHistory` uses locks for safe concurrent access
- `add()` can be called from multiple threads
- All Mach kernel bindings are properly managed for memory safety
- Asynchronous operations like `getLoadAverageAsync()` are thread-safe
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
let metrics = getCpuMetrics().await
echo "CPU: ", metrics.info.brand
echo "Cores: ", metrics.info.physicalCores, " physical, ", metrics.info.logicalCores, " logical"
echo "Architecture: ", metrics.info.architecture
```

### 📊 Monitoring Load Averages

```nim
let metrics = getCpuMetrics().await
echo "Load averages: ", metrics.loadAverage.oneMinute, " ", metrics.loadAverage.fiveMinute, " ", metrics.loadAverage.fifteenMinute
```

### 📈 Tracking Load History

```nim
let history = newLoadHistory()
let metrics = getCpuMetrics().await
history.add(metrics.loadAverage)
echo "Recent load history: ", history
```

## 🔧 Platform Support

- **macOS**: Full support for both Apple Silicon and Intel processors
- **Minimum Version**: macOS 12.0+ (Darwin 21.0+)
- **Architecture**: Native support for arm64 and x86_64
- **Privileges**: User-mode operation (no root required)
- **Memory Safety**: Automatic resource management

## 🔗 See Also

- [💾 Memory Metrics](./memory.html)
- [📊 System Metrics Overview](./metrics.html)
- [⚙️ Configuration Options](./configuration.html)
- [📚 API Reference](./api.html)
