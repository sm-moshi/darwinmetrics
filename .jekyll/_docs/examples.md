---
layout: doc
title: 📚 Usage Examples
permalink: /docs/examples/
---

This page provides practical examples of using darwinmetrics in your applications.

## Basic Usage

### Getting CPU Information

```nim
import darwinmetrics

# Get current CPU information
let cpuInfo = getCpuInfo()
echo "CPU Architecture: ", cpuInfo.architecture
echo "Number of cores: ", cpuInfo.cores
echo "Current usage: ", cpuInfo.usage, "%"
```

### Monitoring System Memory

```nim
import darwinmetrics

# Get memory statistics
let memInfo = getMemoryInfo()
echo "Total RAM: ", memInfo.totalRam div 1024 div 1024, " MB"
echo "Used RAM: ", memInfo.usedRam div 1024 div 1024, " MB"
echo "Free RAM: ", memInfo.freeRam div 1024 div 1024, " MB"
```

## Advanced Usage

### Continuous System Monitoring

```nim
import darwinmetrics
import asyncdispatch
import times

proc monitorSystem() {.async.} =
  while true:
    let
      cpu = getCpuInfo()
      mem = getMemoryInfo()
      temp = getTemperature()

    echo "=== System Status ==="
    echo "CPU Usage: ", cpu.usage, "%"
    echo "Memory Used: ", mem.usedRam div 1024 div 1024, " MB"
    echo "CPU Temperature: ", temp.cpuTemp, "°C"
    echo "Fan Speed: ", temp.fanSpeed, " RPM"

    await sleepAsync(1000) # Update every second

waitFor monitorSystem()
```

### Process Monitoring

```nim
import darwinmetrics
import os

# Monitor specific process
let pid = getCurrentProcessId()
let procInfo = getProcessInfo(pid)

echo "Process Name: ", procInfo.name
echo "CPU Usage: ", procInfo.cpuUsage, "%"
echo "Memory Usage: ", procInfo.memoryUsage div 1024, " KB"
```

### Network Statistics

```nim
import darwinmetrics

# Get network information
let netInfo = getNetworkInfo()

echo "Network Interfaces:"
for interface in netInfo.interfaces:
  echo "  Name: ", interface.name
  echo "  IP: ", interface.ipAddress
  echo "  Active: ", interface.isActive

echo "Total Data:"
echo "  Received: ", netInfo.bytesReceived div 1024, " KB"
echo "  Sent: ", netInfo.bytesSent div 1024, " KB"
```

### Power Monitoring

```nim
import darwinmetrics

# Get comprehensive power information
let powerInfo = getPowerInfo()

if powerInfo.isPresent:
  echo "Battery Status:"
  echo "  Level: ", powerInfo.percentRemaining, "%"
  echo "  Status: ", powerInfo.status
  echo "  Source: ", powerInfo.source

  if powerInfo.timeRemaining.isSome():
    let mins = powerInfo.timeRemaining.get()
    echo "  Time remaining: ", mins div 60, "h ", mins mod 60, "m"

  if powerInfo.health.isSome():
    let health = powerInfo.health.get()
    echo "  Health:"
    echo "    Cycle count: ", health.cycleCount
    echo "    Condition: ", health.condition
    echo "    Capacity: ", (health.currentCapacity.float / health.designCapacity.float) * 100, "%"
else:
  echo "No battery present - running on AC power"

# Quick battery percentage check
let percent = getBatteryPercentage()
echo "Battery at ", percent, "%"

# Check power source
if isPowerAdapterConnected():
  echo "Connected to power adapter"
else:
  echo "Running on battery power"

# Monitor thermal pressure
let thermal = getThermalPressureLevel()
echo "Thermal pressure: ", thermal
```

### Continuous Power Monitoring

```nim
import darwinmetrics
import asyncdispatch
import times

proc monitorPower() {.async.} =
  while true:
    let power = getPowerInfo()
    echo "=== Power Status ==="

    if power.isPresent:
      echo "Battery: ", power.percentRemaining, "%"
      case power.status
      of PowerStatus.Charging:
        if power.timeToFull.isSome():
          echo "Charging - ", power.timeToFull.get(), " minutes to full"
      of PowerStatus.Discharging:
        if power.timeRemaining.isSome():
          echo "On battery - ", power.timeRemaining.get(), " minutes remaining"
      of PowerStatus.Full:
        echo "Fully charged"
      else:
        echo "Status: ", power.status

      echo "Thermal state: ", power.thermalPressure
    else:
      echo "No battery - running on AC power"

    await sleepAsync(5000) # Update every 5 seconds

waitFor monitorPower()
```

## Error Handling

```nim
import darwinmetrics

try:
  let cpuInfo = getCpuInfo()
  # Process information...
except MetricsError as e:
  echo "Error getting CPU info: ", e.msg
  echo "Error code: ", e.code
  echo "Context: ", e.context
```

## Best Practices

1. **Sampling Rate**: Avoid sampling faster than necessary. The default interval (1 second) is suitable for most use cases.

```nim
const SampleInterval = 5.0 # Sample every 5 seconds
```

2. **Resource Usage**: Be mindful of resource usage when monitoring multiple metrics simultaneously.

3. **Error Handling**: Always implement proper error handling to manage potential failures gracefully.

4. **Memory Management**: The library handles memory management automatically, but be aware of resource usage in long-running applications.

## Additional Examples

For more examples and advanced usage scenarios, check out our [GitHub repository](https://github.com/sm-moshi/darwinmetrics/examples).
