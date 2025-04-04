# 🐹 darwinmetrics

[![nimble](https://img.shields.io/badge/nimble-main-green)](https://github.com/sm-moshi/darwinmetrics)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%20(Darwin)-lightblue.svg)](#)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735)](docs/CHANGELOG.md)

> A pure Nim library for accessing macOS system metrics, ported from [`darwin-metrics`](https://github.com/sm-moshi/darwin-metrics) in Rust and [`dmetrics-go`](https://github.com/sm-moshi/dmetrics-go) in Go.

---

## 📦 Features

- [x] 🧠 Architecture detection (`arm64`, `x86_64`)
- [x] 🖥️ CPU:
  - [x] Load average monitoring (1/5/15-minute)
  - [x] Per-core usage stats
  - [x] Frequency info (nominal, min, max)
  - [x] Thread-safe history tracking
  - [x] Async-first design with Chronos
- [x] 💾 Memory:
  - [x] Physical memory statistics
  - [x] Memory pressure monitoring
  - [x] Page-level memory details
  - [x] Process memory tracking
  - [x] Thread-safe operations
- [x] 🔋 Power:
  - [x] Battery state and charging status
  - [x] Battery health and capacity
  - [x] Time estimates (remaining/to full)
  - [x] Thermal pressure monitoring
  - [x] Low power mode detection
- [ ] 🌡️ Temperature:
  - [ ] CPU/GPU thermal sensors (SMC)
  - [ ] Fan speeds
- [ ] 📡 Network:
  - [ ] Interface enumeration
  - [ ] Traffic statistics
  - [ ] Interface types and states
- [ ] 🧵 Process:
  - [ ] Process metrics and resources
  - [ ] Thread counts and states
  - [ ] File descriptor tracking
- [ ] 📊 Disk:
  - [ ] Volume information
  - [ ] Space usage tracking
  - [ ] I/O statistics

---

## 🚀 Quick Start

```nim
import darwinmetrics/system/[cpu, memory, power]
import chronos

proc main() {.async.} =
  # Get CPU metrics
  let cpuMetrics = await getCpuMetrics()
  echo "CPU cores: ", cpuMetrics.physicalCores, " physical, ", cpuMetrics.logicalCores, " logical"
  echo "CPU usage: ", cpuMetrics.usage.total, "% (", cpuMetrics.usage.user, "% user, ", cpuMetrics.usage.system, "% system)"
  echo "Load average (1min): ", cpuMetrics.loadAverage.oneMinute

  # Get memory metrics
  let memMetrics = getMemoryMetrics()
  echo "Memory: ", memMetrics.usedPhysical div GB, "GB used of ", memMetrics.totalPhysical div GB, "GB total"
  echo "Memory pressure: ", memMetrics.pressureLevel

  # Get power metrics
  let powerMetrics = getPowerMetrics()
  if powerMetrics.isPresent:
    echo "Battery: ", powerMetrics.percentRemaining, "%"
    echo "Status: ", powerMetrics.status
    if powerMetrics.timeRemaining.isSome:
      echo "Time remaining: ", powerMetrics.timeRemaining.get(), " minutes"
    echo "Thermal state: ", powerMetrics.thermalPressure

  # Use history tracking
  let
    cpuHistory = newCpuUsageHistory()
    loadHistory = newLoadHistory()

  # Start background tracking
  asyncCheck startCpuUsageTracking(cpuHistory)
  asyncCheck startLoadTracking(loadHistory)

waitFor main()
```

---

## 📁 Project Layout

```
darwinmetrics/
├── docs/                        # Generated documentation
│   ├── CHANGELOG.md             # Project changelog
│   ├── ROADMAP.md               # Development roadmap
│   └── TODO.md                  # Pending tasks
├── src/
│   ├── darwinmetrics.nim        # Public API entry
│   ├── system/                  # System metrics modules
│   │   ├── cpu.nim              # CPU metrics (complete)
│   │   ├── memory.nim           # Memory metrics (complete)
│   │   ├── power.nim            # Power metrics (complete)
│   │   ├── disk.nim             # Disk metrics (planned)
│   │   ├── network.nim          # Network metrics (planned)
│   │   └── process.nim          # Process metrics (planned)
│   ├── internal/                # Internal implementation
│   │   ├── mach_stats.nim       # Mach kernel interfaces
│   │   ├── platform_darwin.nim  # Darwin platform detection
│   │   ├── darwin_errors.nim    # Error types
│   │   ├── cpu_types.nim        # CPU type definitions
│   │   ├── memory_types.nim     # Memory type definitions
│   │   ├── power_types.nim      # Power type definitions
│   │   └── utils.nim            # Utility functions
│   └── doctools/                # Documentation tools
│       ├── sync.nim             # Doc sync library
│       └── docsync_cli.nim      # CLI for doc sync
├── tests/                       # Test suite
│   ├── test_cpu.nim             # CPU module tests
│   ├── test_system_cpu.nim      # System CPU tests
│   ├── test_memory.nim          # Memory module tests
│   ├── test_power.nim           # Power module tests
│   ├── test_docsync.nim         # Documentation tool tests
│   └── test_all.nim             # Combined test runner
├── darwinmetrics.nimble         # Nimble package file
└── README.md                    # This file
```

---

## 🛠 Requirements

- macOS 12.0 or newer (Darwin 21+)
- Nim 2.2.2+
- Chronos 3.2.0+
- Xcode Command Line Tools (`xcode-select --install`)

---

## 🧪 Testing

```bash
nimble test
```

---

## 🔍 Development

1. Clone the repo:

    ```sh
    git clone https://github.com/sm-moshi/darwinmetrics
    cd darwinmetrics
    ```

2. Setup:

    ```sh
    xcode-select --install
    nimble develop
    ```

3. Build:

    ```sh
    nim c -r src/darwinmetrics.nim
    ```

---

## ✨ Code Quality

- CI: GitHub Actions
- Format: `nimpretty`
- Lint: `nim check` / `staticcheck`
- Coverage: Codecov
- GC: ORC by default
- Thread Safety: All metrics modules are thread-safe
- Async Support: Chronos-based async operations

---

## 📜 License

MIT © 2025 [Stuart Meya](https://github.com/sm-moshi)

---

## 🤝 Contributing

- Create issues or pull requests
- Check the [TODO](docs/TODO.md)
- Follow the [Code of Conduct](docs/CODE_OF_CONDUCT.md)
