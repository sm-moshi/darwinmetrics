---
layout: doc
title: 🔌 API Reference
permalink: /docs/api/
---

# API Reference

## Core Functions

### CPU Information

```nim
proc getCpuInfo*(): CpuInfo
```

Returns detailed CPU information including architecture, cores, and current usage.

### Memory Statistics

```nim
proc getMemoryInfo*(): MemoryInfo
```

Returns system memory statistics including RAM and swap usage.

### Power Management

```nim
proc getPowerInfo*(): PowerInfo
```

Returns power-related information including battery status and charging state.

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

## Types

### CpuInfo

```nim
type CpuInfo* = object
  architecture*: string  # arm64 or x86_64
  cores*: int           # Number of CPU cores
  threads*: int         # Number of threads
  frequency*: float     # Current CPU frequency in MHz
  usage*: float        # Current CPU usage percentage
```

[View more types...]({% link _docs/types.md %})
