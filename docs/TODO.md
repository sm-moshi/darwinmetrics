# 📝 TODO — darwinmetrics (Nim)

This document outlines the planned implementation steps for the `darwinmetrics` Nim library, modeled after the Rust-based [`darwin-metrics`](https://github.com/sm-moshi/darwin-metrics) and Go-based [`dmetrics-go`](https://github.com/sm-moshi/dmetrics-go) projects.

---

## 🧱 Foundation

- [x] Initialise `nimble` package: `darwinmetrics`
- [x] Setup `src/` and `tests/` structure
- [x] Add basic public API in `src/darwinmetrics.nim`
- [x] Setup GitHub Actions CI with `nimble test`
- [x] Add README with badges and usage instructions
- [x] Add LICENSE (MIT)
- [x] Add `.editorconfig` and `.gitignore`
- [x] Add `nph` support for LSP formatting

---

## 🧠 Architecture

- [x] Detect CPU architecture (`arm64`, `x86_64`)
- [x] Create internal module for platform detection
- [x] Document Darwin version requirements (macOS 12.0+)
- [x] Implement version checks and validation
- [ ] Support cross-compilation config for future tooling

---

## 🖥️ CPU Module (`system/cpu.nim`)

- [ ] Get number of physical/logical cores
- [ ] Retrieve per-core and total usage
- [ ] Measure load average
- [ ] Detect current and max frequency
- [ ] Async update interface
- [ ] Unit tests with mocked values

---

## 💾 Memory Module (`system/memory.nim`)

- [ ] Read total, used, and available RAM
- [ ] Track swap usage
- [ ] Retrieve memory pressure (if available)
- [ ] Export summary struct for reporting

---

## 📊 Disk Module (`system/disk.nim`)

- [ ] Enumerate mounted volumes
- [ ] Read total and used disk space
- [ ] Track disk I/O stats (read/write per second)
- [ ] Retrieve block size, inode info

---

## 📡 Network Module (`system/network.nim`)

- [ ] List all interfaces (Ethernet, Wi-Fi, etc.)
- [ ] Get MAC address, MTU, interface state
- [ ] Retrieve sent/received bytes & packets
- [ ] Calculate bandwidth usage
- [ ] Support async polling for updates

---

## 🧵 Process Module (`system/process.nim`)

- [ ] Enumerate all running processes
- [ ] Track CPU and memory usage per process
- [ ] Resolve PPID/child relationships
- [ ] Get process name, status, uptime
- [ ] Detect zombies or defunct states

---

## 🔋 Power Module (`system/power.nim`)

- [ ] Detect battery status and level
- [ ] Get charging state and health
- [ ] Estimate time remaining or time to full
- [ ] Track AC vs battery power source
- [ ] Expose thermal pressure (if supported)

---

## 🌡️ Temperature Module (`system/temperature.nim`)

- [ ] Read CPU temperature via SMC
- [ ] Read GPU temperature if available
- [ ] Read fan speeds
- [ ] Support sensor enumeration and naming
- [ ] Categorise thermal zones

---

## 🧬 Internal Layer (`internal/`)

- [ ] `platform_darwin.nim`: syscall/FFI helpers
- [ ] `utils.nim`: conversions, time formatters
- [ ] `smc.nim`: SMC API interface for temp/fans
- [ ] `iokit.nim`: wrappers for IOKit interfaces
- [ ] `cf.nim`: CoreFoundation helper bridges
- [ ] Use `importc`, `dynlib`, and `objc` as needed

---

## 🌐 Async + Sampling

- [ ] Define async polling interface for selected metrics
- [ ] Support configurable sampling rate
- [ ] Expose async helpers using `asyncdispatch` or `chronos`
- [ ] Support cancellation and timeouts

---

## 🔌 Exporters (Future)

- [ ] Prometheus exporter (text format)
- [ ] InfluxDB line protocol support
- [ ] JSON output for CLI/daemon use
- [ ] CSV support for debugging/logging

---

## 🧪 Testing

- [ ] Implement `unittest`-based test suite
- [ ] Add test helpers and mocks
- [ ] Add CI validation on macOS only
- [ ] Add integration tests for async flows
- [x] Track coverage in Codecov

---

## 🧹 Dev & Tooling

- [x] Setup formatter (`nimpretty` + `nph`)
- [x] Setup static analysis (`nim check`)
- [x] Ensure ThreadSanitizer compatibility
- [x] Add Makefile or task runner (optional)
- [ ] Enable version pinning via `nimble.lock`

---

## ✍️ Documentation

- [ ] Generate Nim docs via `nim doc`
- [ ] Write per-module documentation
- [ ] Add examples in `examples/` (e.g., simple usage CLI)
- [ ] Link back to Rust and Go versions for context

---

## 📄 Finalisation

- [ ] Publish GitHub release
- [x] Publish README with accurate usage and badge state
- [x] Add CHANGELOG.md with Keep a Changelog format
- [x] Announce roadmap completion
