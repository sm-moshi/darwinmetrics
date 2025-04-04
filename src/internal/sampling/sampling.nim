## Unified sampling implementation for Darwin metrics.
##
## This module provides the high-level interface for metric sampling,
## delegating the actual collection work to the Chronos backend.
## It follows the async/await paradigm for efficient concurrent collection.
##
## Architecture:
## * Core types and interfaces are defined in `core.nim`
## * Metric collection implementation is in `metric_collector.nim`
## * Chronos-specific backend code is in `chronos_backend.nim`
## * Timer utilities are in `chronos_timer.nim`
##
## Basic Example:
##
## ```nim
## import chronos
## import darwinmetrics/internal/sampling/[types, metric_collector]
##
## proc main() {.async.} =
##   # Create a collector with 5-second timeout
##   let collector = newMetricCollector(seconds(5))
##
##   # Collect individual metrics
##   let cpuResult = await collector.collectCpu()
##   echo "CPU Usage: ", cpuResult.value.cpuValue, "%"
##
##   # Collect all metrics
##   let snapshot = await collector.collectAll()
##   echo "Memory Used: ", snapshot.metrics["memory"].value.memoryBytes div 1024'u64 ^ 2, " MB"
##
##   # Start periodic sampling
##   await collector.startPeriodicSampling(milliseconds(500)) do (snapshot: MetricSnapshot):
##     if snapshot.error.isSome:
##       echo "Error: ", snapshot.error.get
##     else:
##       echo "CPU Usage: ", snapshot.metrics["cpu"].value.cpuValue, "%"
##       echo "Memory Used: ", snapshot.metrics["memory"].value.memoryBytes div 1024'u64 ^ 2, " MB"
##       if "power" in snapshot.metrics:
##         echo "Battery: ", snapshot.metrics["power"].value.powerWatts, "%"
##
## waitFor main()
## ```
##
## Error Handling:
## Each metric collection returns a `MetricResult` that includes both the value
## and any potential error. The sampling system will continue running even if
## individual metrics fail to collect.
##
## Thread Safety:
## The sampling system is designed to be thread-safe, using appropriate locking
## mechanisms where needed. However, the main collection loop runs in a single
## async context for efficiency.
##
## Performance:
## * Collection is done concurrently using Chronos async/await
## * Timeouts prevent hanging on slow system calls
## * Metrics are collected in parallel where possible
## * Memory allocations are minimized in the collection path

