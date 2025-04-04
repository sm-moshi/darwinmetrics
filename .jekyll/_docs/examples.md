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
import chronos

proc main() {.async.} =
  # Get current CPU information
  let cpuMetrics = await getCpuMetrics()
  echo "CPU Architecture: ", cpuMetrics.architecture
  echo "Physical cores: ", cpuMetrics.physicalCores
  echo "Logical cores: ", cpuMetrics.logicalCores
  echo "Current usage: ", cpuMetrics.usage.total, "%"
  echo "Load average (1min): ", cpuMetrics.loadAverage.oneMinute

waitFor main()
```

### Monitoring System Memory

```nim
import darwinmetrics
import chronos

proc main() {.async.} =
  # Get memory statistics
  let memMetrics = getMemoryMetrics()
  echo "Total RAM: ", memMetrics.totalPhysical div GB, " GB"
  echo "Used RAM: ", memMetrics.usedPhysical div GB, " GB"
  echo "Available RAM: ", memMetrics.availablePhysical div GB, " GB"
  echo "Memory Pressure: ", memMetrics.pressureLevel

waitFor main()
```

## Advanced Usage

### Continuous System Monitoring

```nim
import darwinmetrics
import chronos

proc monitorSystem() {.async.} =
  # Create history trackers
  let
    cpuHistory = newCpuUsageHistory()
    loadHistory = newLoadHistory()

  # Start tracking in background
  asyncCheck startCpuUsageTracking(cpuHistory)
  asyncCheck startLoadTracking(loadHistory)

  while true:
    let
      cpuMetrics = await getCpuMetrics()
      memMetrics = getMemoryMetrics()
      powerMetrics = getPowerMetrics()

    echo "=== System Status ==="
    echo "CPU Usage: ", cpuMetrics.usage.total, "%"
    echo "Memory Used: ", memMetrics.usedPhysical div GB, " GB"
    echo "Load Average: ", cpuMetrics.loadAverage.oneMinute
    if powerMetrics.isPresent:
      echo "Battery Level: ", powerMetrics.percentRemaining, "%"
      echo "Power Status: ", powerMetrics.status
      echo "Thermal State: ", powerMetrics.thermalPressure

    await sleepAsync(seconds(1))

waitFor monitorSystem()
```

### Process Monitoring

```nim
import darwinmetrics
import chronos
import os

proc main() {.async.} =
  # Monitor specific process
  let procMetrics = await getProcessMetrics()

  echo "Process Information:"
  echo "PID: ", procMetrics.info.pid
  echo "Name: ", procMetrics.info.name
  echo "CPU Usage: ", procMetrics.resources.cpuPercent, "%"
  echo "Memory RSS: ", procMetrics.resources.memoryRSS div MB, " MB"
  echo "Memory Virtual: ", procMetrics.resources.memoryVirtual div MB, " MB"
  echo "Threads: ", procMetrics.threads
  echo "Open Files: ", procMetrics.openFiles

waitFor main()
```

### Network Statistics

```nim
import darwinmetrics
import chronos

proc main() {.async.} =
  # Get network information
  let netMetrics = await getNetworkMetrics()

  echo "Network Interfaces:"
  for iface in netMetrics.interfaces:
    let info = iface.networkInterface
    echo "  Name: ", info.name
    echo "  Display Name: ", info.displayName
    echo "  IPv4: ", info.ipv4Address
    echo "  IPv6: ", info.ipv6Address
    echo "  MAC: ", info.macAddress
    echo "  Status: ", if info.isUp: "Up" else: "Down"

    let stats = iface.stats
    echo "  Statistics:"
    echo "    Bytes Received: ", stats.bytesReceived div MB, " MB"
    echo "    Bytes Sent: ", stats.bytesSent div MB, " MB"
    echo "    Packets Received: ", stats.packetsReceived
    echo "    Packets Sent: ", stats.packetsSent

waitFor main()
```

### Power Monitoring

```nim
import darwinmetrics
import chronos

proc main() {.async.} =
  # Get comprehensive power information
  let powerMetrics = getPowerMetrics()

  if powerMetrics.isPresent:
    echo "Battery Status:"
    echo "  Level: ", powerMetrics.percentRemaining, "%"
    echo "  Status: ", powerMetrics.status
    echo "  Source: ", powerMetrics.source

    if powerMetrics.timeRemaining.isSome():
      let mins = powerMetrics.timeRemaining.get()
      echo "  Time remaining: ", mins div 60, "h ", mins mod 60, "m"

    if powerMetrics.health.isSome():
      let health = powerMetrics.health.get()
      echo "  Health:"
      echo "    Cycle count: ", health.cycleCount
      echo "    Condition: ", health.condition
      echo "    Capacity: ", (health.currentCapacity.float / health.designCapacity.float) * 100, "%"
  else:
    echo "No battery present - running on AC power"

  # Check thermal pressure
  let thermal = getThermalPressureLevel()
  echo "Thermal pressure: ", thermal

waitFor main()
```

### Continuous Power Monitoring

```nim
import darwinmetrics
import chronos

proc monitorPower() {.async.} =
  while true:
    let powerMetrics = getPowerMetrics()
    echo "=== Power Status ==="

    if powerMetrics.isPresent:
      echo "Battery: ", powerMetrics.percentRemaining, "%"
      case powerMetrics.status
      of PowerStatus.Charging:
        if powerMetrics.timeToFull.isSome():
          echo "Charging - ", powerMetrics.timeToFull.get(), " minutes to full"
      of PowerStatus.Discharging:
        if powerMetrics.timeRemaining.isSome():
          echo "On battery - ", powerMetrics.timeRemaining.get(), " minutes remaining"
      of PowerStatus.Full:
        echo "Fully charged"
      else:
        echo "Status: ", powerMetrics.status

      echo "Thermal state: ", powerMetrics.thermalPressure
    else:
      echo "No battery - running on AC power"

    await sleepAsync(seconds(5)) # Update every 5 seconds

waitFor monitorPower()
```

## Error Handling

```nim
import darwinmetrics
import chronos

proc main() {.async.} =
  try:
    let cpuMetrics = await getCpuMetrics()
    # Process information...
  except DarwinError as e:
    echo "Error getting CPU info: ", e.msg
  except DarwinVersionError as e:
    echo "Unsupported Darwin version: ", e.msg

waitFor main()
```

## Best Practices

1. **Async/Await**: Always use async/await with Chronos for proper concurrency.

```nim
import chronos

const SampleInterval = seconds(5) # Sample every 5 seconds
```

2. **History Tracking**: Use the built-in history trackers for time-series data:

```nim
let
  cpuHistory = newCpuUsageHistory()
  loadHistory = newLoadHistory()
  perCoreHistory = newPerCoreHistory()

# Start tracking in background
asyncCheck startCpuUsageTracking(cpuHistory)
asyncCheck startLoadTracking(loadHistory)
asyncCheck startPerCoreTracking(perCoreHistory)
```

3. **Resource Management**:
   - Be mindful of sampling rates
   - Use appropriate history sizes
   - Clean up resources when done

4. **Error Handling**: Always implement proper error handling for all async operations.

## Additional Examples

For more examples and advanced usage scenarios, check out our [GitHub repository](https://github.com/sm-moshi/darwinmetrics/examples).
