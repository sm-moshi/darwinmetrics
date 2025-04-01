---
layout: doc
title: 🚀 Getting Started
permalink: /docs/getting-started/
---


darwinmetrics is a Nim library for collecting system metrics on macOS. This guide will help you quickly get up and running with the basics.

Before you begin, ensure you have:

* Nim 2.2.2 or higher
* macOS 12.0+ (Monterey or higher)
* Nimble package manager

## Installation

The simplest way to install darwinmetrics is via Nimble:

```bash
nimble install darwinmetrics
```

Alternatively, you can add it as a dependency in your .nimble file:

```nim
requires "darwinmetrics >= 0.1.0"
```

For more detailed installation instructions, see the [Installation Guide]({% link _docs/installation.md %}).

## Basic Usage

Here's a simple example of using darwinmetrics to fetch system information:

```nim
import darwinmetrics

# Initialize the metrics system
initMetrics()

# Get CPU information
let cpuInfo = getCpuInfo()
echo "CPU Cores: ", cpuInfo.cores
echo "CPU Usage: ", cpuInfo.usage, "%"

# Get memory information
let memInfo = getMemoryInfo()
echo "Total RAM: ", memInfo.totalRam div 1024 div 1024, " MB"
echo "Used RAM: ", memInfo.usedRam div 1024 div 1024, " MB"
echo "Free RAM: ", memInfo.freeRam div 1024 div 1024, " MB"

# Get temperature information
let tempInfo = getTemperature()
echo "CPU Temperature: ", tempInfo.cpuTemp, "°C"
echo "Fan Speed: ", tempInfo.fanSpeed, " RPM"

# Clean up
shutdownMetrics()
```

## Next Steps
<!-- markdownlint-disable MD037 -->
* Explore the [API Reference]({% link _docs/api.md %}) for detailed information about available functions
* Check out the [Usage Examples]({% link _docs/examples.md %}) for more advanced usage patterns
* Learn how to [Configure]({% link _docs/configuration.md %}) darwinmetrics for your specific needs

## Getting Help

If you encounter any issues or have questions:

* File an issue on our [GitHub repository](https://github.com/sm-moshi/darwinmetrics/issues)
* Check existing documentation for solutions
* Contribute to the project by following our [Contributing Guide]({% link _docs/contributing.md %})
