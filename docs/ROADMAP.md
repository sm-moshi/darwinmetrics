# 🛣 ROADMAP — darwinmetrics (Nim)

This document defines the long-term development goals and phased milestones for the `darwinmetrics` library. It reflects the functional parity target with [`darwin-metrics`](https://github.com/sm-moshi/darwin-metrics) (Rust) and [`dmetrics-go`](https://github.com/sm-moshi/dmetrics-go), while embracing idiomatic Nim practices.

---

## 📍 Phase 1: Bootstrap & Core API ✅

🎯 Goal: Establish working structure, entry point, and baseline modules

- [x] Initialise `nimble` project and structure
- [x] Create public API scaffold (`src/darwinmetrics.nim`)
- [x] Implement architecture detection with version validation
- [x] Set minimum macOS requirement to 12.0+ (Darwin 21.0+)
- [x] Stub core metric modules (CPU, Memory, Power, Disk, Network, Process)
- [x] Setup LSP, formatter (`nph`, `nimpretty`)
- [x] Setup GitHub Actions CI

---

## 📍 Phase 2: CPU, Memory, and Power Support

🎯 Goal: Implement reliable synchronous metrics for system monitoring

- [x] CPU:
  - [x] Load average
  - [x] Per-core usage
  - [x] Frequency
  - [x] Architecture-specific optimisations (arm64/x86_64)
- [x] Memory:
  - [x] RAM + Swap
  - [x] Pressure (if available)
- [x] Power:
  - [x] Battery state, charge, time remaining
  - [x] Power source detection
  - [x] Thermal pressure monitoring
  - [x] Battery health information

---

## 📍 Phase 3: Async Sampling & Struct Design

🎯 Goal: Add async interfaces and shared metric model structures

- [ ] Define `MetricResult` / `MetricSnapshot` types
- [ ] Build async polling helpers
- [ ] Add cancellation support
- [ ] Enable periodic sampling for all core metrics

---

## 📍 Phase 4: GPU, Temperature, Fan Sensors

🎯 Goal: Expand visibility into hardware-level conditions via SMC & IOKit

- [ ] GPU model + usage
- [ ] Fan speeds
- [ ] Temperature zones
- [ ] SMC and CoreFoundation wrappers

---

## 📍 Phase 5: Process & Network Visibility

🎯 Goal: Enable process-level and network-level introspection

- [ ] Enumerate processes
- [ ] Per-process resource tracking
- [ ] Build parent/child tracking
- [ ] Network interfaces and traffic stats

---

## 📍 Phase 6: Metrics Exporters & CLI Tooling

🎯 Goal: Enable use of library as backend for monitoring tools

- [ ] JSON/CSV output formats
- [ ] Prometheus exporter
- [ ] InfluxDB support
- [ ] CLI: `nmetrics` sampling daemon

---

## 📍 Phase 7: Polish & Publication

🎯 Goal: Clean up, document, and publish usable version

- [x] Write `README.md`, `CHANGELOG.md`, and module-level docs
- [ ] 100% test coverage on CI for macOS
- [ ] Release `v0.1.0` via GitHub
- [ ] Tag as parity-complete with Rust/Go versions

---

## 🚨 Post-Release (v0.2+)

- [ ] Cross-platform abstraction for Linux
- [ ] Daemon-mode metrics streaming
- [ ] gRPC + WebSocket support
- [ ] Advanced async sampling manager
- [ ] Dashboard UI (via Tauri or Dioxus)
