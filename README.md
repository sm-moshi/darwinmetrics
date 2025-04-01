# 🐹 darwinmetrics

[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735)](docs/CHANGELOG.md)
[![nimble](https://img.shields.io/badge/nimble-develop-orange)](https://github.com/sm-moshi/darwinmetrics)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml)
[![Coverage](https://codecov.io/gh/sm-moshi/darwinmetrics/branch/main/graph/badge.svg)](https://codecov.io/gh/sm-moshi/darwinmetrics)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%20(Darwin)-lightgrey.svg)](#)

> A pure Nim library for accessing macOS system metrics, ported from [`darwin-metrics`](https://github.com/sm-moshi/darwin-metrics) in Rust and [`dmetrics-go`](https://github.com/sm-moshi/dmetrics-go) in Go.

---

## 📦 Features (TODO)

- [x] 🧠 Architecture detection (`arm64`, `x86_64`)
- [~] 🖥️ CPU:
  - [x] Load average monitoring (1/5/15-minute)
  - [ ] Per-core usage stats
  - [x] Frequency info
  - [ ] Thread-safe, async-compatible
- [ ] 💾 Memory:
  - [ ] RAM and swap statistics
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

echo getCpuInfo()
echo getMemoryInfo()
echo getPowerInfo()
```

---

## 📁 Project Layout

```
darwinmetrics/
├── docs/                        # Documentation
├── src/
│   ├── darwinmetrics.nim        # Public API entry
│   ├── system/                  # CPU, memory, disk, etc.
│   └── internal/                # Darwin FFI bindings & utils
├── tests/                       # Unit and integration tests
├── darwinmetrics.nimble         # Nimble project file
└── README.md
```

---

## 🛠 Requirements

- macOS 12.0 or newer (Darwin 21+)
- Nim 2.22+
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
- GC: ARC by default

---

## 📜 License

MIT © 2025 [Stuart Meya](https://github.com/sm-moshi)

---

## 🤝 Contributing

- Create issues or pull requests
- Check the [TODO](docs/TODO.md)
- Follow the [Code of Conduct](docs/CODE_OF_CONDUCT.md)
