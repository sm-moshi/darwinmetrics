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
let info = getCpuInfo()
echo info

# Get load averages
let load = getLoadAverageAsync().await
echo load
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
- `model`: CPU model identifier
- `brand`: Full CPU brand string (e.g., "Apple M2 Pro")
- `frequency`: CPU frequency information
- `usage`: Current CPU usage statistics

## ⚡ CPU Frequency

The `CpuFrequency` object provides detailed frequency information:

```nim
type CpuFrequency* = object
  nominal*: Option[float]  # Base frequency in MHz
  current*: Option[float]  # Current frequency in MHz
  min*: Option[float]     # Minimum frequency in MHz
  max*: Option[float]     # Maximum frequency in MHz
```

### 🖥️ Platform-Specific Behaviour

#### 🍎 Apple Silicon (M1/M2)

- Nominal frequency: Base frequency (3.5 GHz for M2, 3.2 GHz for M1)
- Min frequency: 600 MHz
- Max frequency: Matches nominal frequency
- Current frequency: Not available in user mode

#### 💻 Intel Processors

- Primary: Retrieves frequency via sysctl
- Fallback: Parses brand string if sysctl fails
- Defaults: Provides reasonable values if exact data unavailable

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

## ⚠️ Error Handling

The module implements graceful fallbacks instead of raising exceptions:

- Invalid/unavailable values: Represented as `none(float)` in `CpuFrequency`
- Core counts: Validated to be positive numbers
- Architecture strings: Validated against known values

## 📝 Examples

### 🔍 Basic CPU Information

```nim
let info = getCpuInfo()
echo "CPU: ", info.brand
echo "Cores: ", info.physicalCores, " physical, ", info.logicalCores, " logical"
echo "Architecture: ", info.architecture
```

### 📊 Monitoring Load Averages

```nim
let load = getLoadAverageAsync().await
echo "Load averages: ", load.oneMinute, " ", load.fiveMinutes, " ", load.fifteenMinutes
```

### 📈 Tracking Load History

```nim
let history = newLoadHistory()
history.add(getLoadAverageAsync().await)
echo "Recent load history: ", history
```

## 🔧 Platform Support

- **macOS**: Full support for both Apple Silicon and Intel processors
- **Minimum Version**: macOS 12.0+ (Darwin 21.0+)

## 🔗 See Also

- [📊 System Metrics Overview](./metrics.html)
- [⚙️ Configuration Options](./configuration.html)
- [📚 API Reference](./api.html)
