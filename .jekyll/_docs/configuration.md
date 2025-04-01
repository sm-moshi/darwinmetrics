---
layout: doc
title: ⚙️ Configuration
permalink: /docs/configuration/
---

darwinmetrics provides various configuration options to customize its behavior for your specific needs.

## Basic Configuration

The default configuration works for most use cases, but you can customize it by creating a configuration file:

```nim
import darwinmetrics

let config = MetricsConfig(
  pollInterval: 2.0,  # Poll system metrics every 2 seconds
  enableCpuMetrics: true,
  enableMemoryMetrics: true,
  enableDiskMetrics: true,
  enableNetworkMetrics: true,
  enableTemperatureMetrics: true
)

# Initialize with custom config
initMetrics(config)
```

## Available Options

The following options can be set in the `MetricsConfig` object:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pollInterval` | float | 1.0 | Time in seconds between metric polls |
| `enableCpuMetrics` | bool | true | Enable CPU metrics collection |
| `enableMemoryMetrics` | bool | true | Enable memory metrics collection |
| `enableDiskMetrics` | bool | true | Enable disk metrics collection |
| `enableNetworkMetrics` | bool | true | Enable network metrics collection |
| `enableTemperatureMetrics` | bool | true | Enable temperature sensor data |
| `maxHistorySize` | int | 60 | Number of historical data points to keep |
| `logLevel` | LogLevel | LogLevel.Info | Logging verbosity |

## Logger Configuration

You can configure the logger separately:

```nim
import darwinmetrics
import logging

# Set log level to Debug
setLogLevel(LogLevel.Debug)

# Use a custom logger
let customLogger = newConsoleLogger()
setLogger(customLogger)
```

## Environment Variables

darwinmetrics also respects the following environment variables:

| Variable | Description |
|----------|-------------|
| `darwinmetrics_LOG_LEVEL` | Sets the log level (DEBUG, INFO, WARN, ERROR) |
| `darwinmetrics_POLL_INTERVAL` | Sets the default poll interval in seconds |
| `darwinmetrics_DISABLE_METRICS` | Comma-separated list of metrics to disable |

## Advanced Configuration

### Custom Metric Sources

You can register custom metric sources:

```nim
import darwinmetrics
import darwinmetrics/metrics

# Create a custom metric source
type CustomMetricSource = ref object of MetricSource

proc collectMetrics(source: CustomMetricSource): seq[Metric] =
  # Your custom metrics collection logic
  result = @[
    Metric(name: "custom.metric1", value: 42.0),
    Metric(name: "custom.metric2", value: 100.0)
  ]

# Register your custom source
let customSource = CustomMetricSource()
registerMetricSource(customSource)
```

### Using Configuration Files

You can also load configuration from a TOML file:

```nim
import darwinmetrics
import parsetoml

# Load config from file
let config = loadConfigFromFile("metrics_config.toml")
initMetrics(config)
```

Example `metrics_config.toml`:

```toml
[metrics]
poll_interval = 5.0
enable_cpu_metrics = true
enable_memory_metrics = true
enable_disk_metrics = false
enable_network_metrics = true
max_history_size = 120

[logging]
log_level = "INFO"
```
