# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

## Darwin Metrics - System metric collection for macOS
##
## This module provides a unified interface for collecting various system metrics
## on Darwin-based systems (macOS). It wraps platform-specific APIs to collect
## CPU, memory, disk, network, and process metrics.
##
## The library supports both one-time collection and continuous sampling via the
## built-in async sampling system.
##
## Example:
##
## .. code-block:: nim
##   import darwinmetrics, asyncdispatch
##
##   # One-time collection
##   let cpu = darwinmetrics.collectCPUMetrics()
##   echo "CPU usage: ", cpu.overallUsage.total, "%"
##
##   # Continuous sampling
##   proc onMetrics(snapshot: MetricSnapshot) {.async.} =
##     echo "Memory used: ", snapshot.memoryMetrics.memoryStats.used, " bytes"
##
##   let config = newSamplerConfig(milliseconds(1000), onMetrics)
##   let sampler = newSampler(config)
##   sampler.start()
##   # ... later ...
##   sampler.stop()

import std/[options, asyncdispatch]

# Import types
import internal/[
  cpu_types,
  memory_types,
  disk_types,
  network_types,
  process_types
]

# Export types
export cpu_types
export memory_types
export disk_types
export network_types
export process_types

# Import system metrics
import system/[
  cpu,
  memory,
  disk,
  network,
  process
]

export cpu
export memory
export disk
export network
export process

# Export sampling
import internal/sampling/[
  core,
  sampling
]

export core.SamplingDuration
export core.milliseconds
export core.seconds
export core.nanoseconds
export core.microseconds
export core.MetricSnapshot
export core.SamplerConfig
export core.newSamplerConfig
export core.MetricError

export sampling.Sampler
export sampling.newSampler

# Core functions
proc collectCPUMetrics*(): CPUMetrics =
  ## Collect CPU metrics
  # Real implementation would populate these with real data
  result = CPUMetrics()

proc collectMemoryMetrics*(): MemoryMetrics =
  ## Collect memory metrics
  # Real implementation would populate these with real data
  result = MemoryMetrics()

proc collectDiskMetrics*(): DiskMetrics =
  ## Collect disk metrics
  # Real implementation would populate these with real data
  result = DiskMetrics()

proc collectNetworkMetrics*(): NetworkMetrics =
  ## Collect network metrics
  # Real implementation would populate these with real data
  result = NetworkMetrics()

proc collectProcessMetrics*(): ProcessMetrics =
  ## Collect process metrics
  # Real implementation would populate these with real data
  result = ProcessMetrics()

proc collectAllMetrics*(): MetricSnapshot =
  ## Collect all metrics in a single snapshot
  result = new MetricSnapshot
  result.timestamp = 0 # Would be set properly in real implementation
  result.cpuMetrics = collectCPUMetrics()
  result.memoryMetrics = collectMemoryMetrics()
  result.diskMetrics = collectDiskMetrics()
  result.networkMetrics = collectNetworkMetrics()
  result.processMetrics = collectProcessMetrics()
