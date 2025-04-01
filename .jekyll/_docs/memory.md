---
title: 💾 Memory Metrics
description: Documentation for memory metrics collection in darwinmetrics
layout: doc
nav_order: 4
---

The Memory metrics module provides detailed information about your system's memory usage, including physical memory, memory pressure, and per-process memory statistics. It supports both Apple Silicon and Intel processors with consistent behaviour across platforms.

## 🚀 Quick Start

```nim
import darwinmetrics/system/memory

# Get system memory statistics
let stats = getMemoryStats()
echo "Total RAM: ", stats.totalPhysical div GB, " GB"
echo "Available: ", stats.availablePhysical div GB, " GB"
echo "Used: ", stats.usedPhysical div GB, " GB"

# Check memory pressure
let pressure = getMemoryPressureLevel()
case pressure
of Normal: echo "Memory pressure is normal"
of Warning: echo "System is experiencing memory pressure"
of Critical: echo "System is under critical memory pressure"
of Error: echo "Unable to determine memory pressure"

# Get current process memory info
let procInfo = getProcessMemoryInfo()
echo "Process RSS: ", procInfo.residentSize div MB, " MB"
```

## 📊 Memory Statistics

The `MemoryStats` object provides comprehensive system memory information:

```nim
type MemoryStats* = object
  totalPhysical*: uint64      ## Total physical memory in bytes
  availablePhysical*: uint64  ## Available physical memory in bytes
  usedPhysical*: uint64       ## Used physical memory in bytes
  pressureLevel*: MemoryPressureLevel  ## Current memory pressure level
  pageSize*: uint32           ## System page size in bytes
  pagesFree*: uint64         ## Number of free pages
  pagesActive*: uint64       ## Number of active pages in use
  pagesInactive*: uint64     ## Number of inactive pages that can be reclaimed
  pagesWired*: uint64        ## Number of wired (locked) pages
  pagesCompressed*: uint64   ## Number of compressed pages
```

### 🔍 Field Details

- `totalPhysical`: Total installed physical memory
- `availablePhysical`: Memory available for allocation
- `usedPhysical`: Currently used physical memory
- `pressureLevel`: System memory pressure state
- `pageSize`: System memory page size (typically 16KB on Apple Silicon)
- `pagesFree`: Number of unallocated pages
- `pagesActive`: Pages currently in active use
- `pagesInactive`: Pages that can be reclaimed if needed
- `pagesWired`: Pages locked in memory (cannot be paged out)
- `pagesCompressed`: Pages in the compression pool

## 🎯 Process Memory Information

The `ProcessMemoryInfo` object provides memory statistics for individual processes:

```nim
type ProcessMemoryInfo* = object
  virtualSize*: uint64      ## Virtual memory size in bytes
  residentSize*: uint64     ## Resident set size (RSS) in bytes
  residentPeak*: uint64     ## Peak resident size in bytes
```

### 🔍 Field Details

- `virtualSize`: Total virtual memory allocated
- `residentSize`: Current physical memory in use (RSS)
- `residentPeak`: Maximum RSS reached during process lifetime

## 🌡️ Memory Pressure

The `MemoryPressure` enum indicates system memory availability:

```nim
type MemoryPressure* = enum
  Normal    ## System operating normally
  Warning   ## Beginning to experience memory pressure
  Critical  ## Under significant memory pressure
  Error     ## Unable to determine memory pressure
```

### 📊 Pressure Levels

- **Normal**: System has sufficient free memory
- **Warning**: Memory pressure is elevated (< 15% free)
- **Critical**: Severe memory pressure (< 10% free)
- **Error**: Failed to determine pressure level

## 📏 Memory Units

The module provides convenient constants for memory units:

```nim
const
  KB* = 1024'u64              ## Kilobyte (1024 bytes)
  MB* = KB * 1024'u64         ## Megabyte (1,048,576 bytes)
  GB* = MB * 1024'u64         ## Gigabyte (1,073,741,824 bytes)
  TB* = GB * 1024'u64         ## Terabyte (1,099,511,627,776 bytes)
```

## 🔒 Thread Safety

The memory module ensures thread-safe operation:

- All memory statistics functions are thread-safe
- Process memory information retrieval is atomic
- Memory pressure monitoring is safe for concurrent access
- Mach kernel resource management is properly synchronized

## ⚠️ Error Handling

The module implements robust error handling:

- Memory-related errors are captured in `MemoryError`
- Invalid memory statistics raise descriptive errors
- Process information failures include error codes
- Memory pressure errors default to `Error` state
- Resource cleanup is guaranteed even on errors

## 📝 Examples

### 🔍 Basic Memory Information

```nim
let stats = getMemoryStats()
echo "Memory Usage:"
echo "  Total: ", stats.totalPhysical div GB, " GB"
echo "  Available: ", stats.availablePhysical div GB, " GB"
echo "  Used: ", stats.usedPhysical div GB, " GB"
echo "  Pressure: ", stats.pressureLevel
```

### 📊 Process Memory Tracking

```nim
let procInfo = getProcessMemoryInfo()
echo "Process Memory:"
echo "  RSS: ", procInfo.residentSize div MB, " MB"
echo "  Virtual: ", procInfo.virtualSize div GB, " GB"
echo "  Peak RSS: ", procInfo.residentPeak div MB, " MB"
```

### 🌡️ Memory Pressure Monitoring

```nim
while true:
  let pressure = getMemoryPressureLevel()
  case pressure
  of Normal:
    echo "Memory pressure normal"
  of Warning:
    echo "Warning: Memory pressure elevated"
  of Critical:
    echo "Critical: System under memory pressure"
  of Error:
    echo "Error checking memory pressure"
  sleep(1000) # Check every second
```

## 🔧 Platform Support

- **macOS**: Full support for both Apple Silicon and Intel processors
- **Minimum Version**: macOS 12.0+ (Darwin 21.0+)
- **Architecture**: Native support for arm64 and x86_64
- **Privileges**: User-mode operation (no root required)
- **Memory Safety**: Automatic resource management

## 🔗 See Also

- [💻 CPU Metrics](./cpu.html)
- [📊 System Metrics Overview](./metrics.html)
- [⚙️ Configuration Options](./configuration.html)
- [📚 API Reference](./api.html)
