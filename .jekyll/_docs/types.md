---
layout: doc
title: 📊 Type Reference
permalink: /docs/types/
---

This page documents all the core types used in darwinmetrics.

## System Information Types

### CpuInfo

```nim
type CpuInfo* = object
  architecture*: string  # arm64 or x86_64
  cores*: int           # Number of CPU cores
  threads*: int         # Number of threads
  frequency*: float     # Current CPU frequency in MHz
  usage*: float        # Current CPU usage percentage
```

### MemoryInfo

```nim
type MemoryInfo* = object
  totalRam*: int64      # Total RAM in bytes
  usedRam*: int64       # Used RAM in bytes
  freeRam*: int64       # Free RAM in bytes
  totalSwap*: int64     # Total swap space in bytes
  usedSwap*: int64      # Used swap space in bytes
  freeSwap*: int64      # Free swap space in bytes
```

### PowerInfo

```nim
type PowerInfo* = object
  isCharging*: bool     # Whether the device is charging
  batteryLevel*: float  # Battery level percentage
  timeRemaining*: int   # Estimated minutes of battery life remaining
  powerSource*: string  # Current power source (battery/AC)
```

### TempInfo

```nim
type TempInfo* = object
  cpuTemp*: float      # CPU temperature in Celsius
  fanSpeed*: int       # Fan speed in RPM
  gpuTemp*: float     # GPU temperature in Celsius (if available)
```

### NetworkInfo

```nim
type NetworkInfo* = object
  interfaces*: seq[NetworkInterface]  # List of network interfaces
  bytesReceived*: int64              # Total bytes received
  bytesSent*: int64                  # Total bytes sent
```

### NetworkInterface

```nim
type NetworkInterface* = object
  name*: string        # Interface name
  ipAddress*: string   # IP address
  macAddress*: string  # MAC address
  isActive*: bool      # Whether the interface is active
```

### ProcessInfo

```nim
type ProcessInfo* = object
  pid*: int           # Process ID
  name*: string       # Process name
  cpuUsage*: float   # CPU usage percentage
  memoryUsage*: int64 # Memory usage in bytes
  status*: string    # Process status (running/sleeping/etc)
```

## Error Types

### MetricsError

```nim
type MetricsError* = object of Exception
  code*: int          # Error code
  context*: string    # Additional error context
```

## Constants

```nim
const
  MaxSampleRate* = 1000  # Maximum samples per second
  DefaultInterval* = 1.0 # Default sampling interval in seconds
```
