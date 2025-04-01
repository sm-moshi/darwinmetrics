# 🐹 darwinmetrics

[![nimble](https://img.shields.io/badge/nimble-develop-orange)](https://github.com/sm-moshi/darwinmetrics)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml/badge.svg?branch=develop)](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%20(Darwin)-lightblue.svg)](#)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735)](docs/CHANGELOG.md)

> A pure Nim library for accessing macOS system metrics, ported from [`darwin-metrics`](https://github.com/sm-moshi/darwin-metrics) in Rust and [`dmetrics-go`](https://github.com/sm-moshi/dmetrics-go) in Go.

---

## 📦 Features

- [x] 🧠 Architecture detection (`arm64`, `x86_64`)
- [x] 🖥️ CPU:
  - [x] Load average monitoring (1/5/15-minute)
  - [x] Per-core usage stats
  - [x] Frequency info
  - [x] Thread-safe, async-compatible
- [x] 💾 Memory:
  - [x] RAM and swap statistics
- [ ] 🔋 Power:
  - [ ] Battery state, charging status, health, time estimate
- [ ] 🌡️ Temperature:
  - [ ] CPU/GPU thermal sensors (SMC)
  - [ ] Fan speeds
- [ ] 📡 Network:
  - [ ] Interface enumeration, traffic stats
- [ ] 🧵 Process:
  - [ ] Per-process usage, uptime, hierarchy
- [ ] 📊 Disk:
  - [ ] Space usage and I/O

---

## 🚀 Quick Start

```nim
import darwinmetrics
import asyncdispatch

# Get CPU information
let cpuInfo = getCpuInfo()
echo "CPU cores: ", cpuInfo.physicalCores, " physical, ", cpuInfo.logicalCores, " logical"
echo "CPU usage: ", cpuInfo.usage.total, "% (", cpuInfo.usage.user, "% user, ", cpuInfo.usage.system, "% system)"

# Get per-core CPU metrics
let coreStats = getPerCoreCpuLoadInfo()
echo "Per-core stats for ", coreStats.len, " cores:"
for i, core in coreStats:
  echo "  Core ", i, ": user=", core.userTicks[0], ", system=", core.systemTicks[0]

# Load averages with async support
let loadAvg = waitFor getLoadAverageAsync()
echo "Load averages: ", loadAvg.oneMinute, " (1m), ", loadAvg.fiveMinute, " (5m), ", loadAvg.fifteenMinute, " (15m)"

# Use the load history for tracking changes over time
var history = newLoadHistory(maxSamples = 60)  # Keep 60 most recent samples
history.add(loadAvg)
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
│   │   ├── memory.nim           # Memory metrics
│   │   ├── disk.nim             # Disk metrics
│   │   ├── network.nim          # Network metrics
│   │   ├── power.nim            # Power metrics
│   │   └── process.nim          # Process metrics
│   ├── internal/                # Internal implementation
│   │   ├── mach_stats.nim       # Mach kernel interfaces
│   │   ├── platform_darwin.nim  # Darwin platform detection
│   │   ├── darwin_errors.nim    # Error types
│   │   └── utils.nim            # Utility functions
│   └── doctools/                # Documentation tools
│       ├── sync.nim             # Doc sync library
│       └── docsync_cli.nim      # CLI for doc sync
├── tests/                       # Test suite
│   ├── test_cpu.nim             # CPU module tests
│   ├── test_system_cpu.nim      # System CPU tests
│   ├── test_docsync.nim         # Documentation tool tests
│   └── test_all.nim             # Combined test runner
├── darwinmetrics.nimble         # Nimble package file
└── README.md                    # This file
```

---

## 🛠 Requirements

- macOS 12.0 or newer (Darwin 21+)
- Nim 2.2.2+
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

---

## 📜 License

MIT © 2025 [Stuart Meya](https://github.com/sm-moshi)

---

## 🤝 Contributing

- Create issues or pull requests
- Check the [TODO](docs/TODO.md)
- Follow the [Code of Conduct](docs/CODE_OF_CONDUCT.md)
