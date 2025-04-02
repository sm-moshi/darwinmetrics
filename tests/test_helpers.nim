## Test helpers and utilities for darwinmetrics tests.
##
## This module provides common test utilities, mock objects,
## and helper functions used across the test suite.

import std/[unittest, times, options]
import pkg/chronos
import pkg/chronos/timer
import ../src/internal/sampling/core
import ../src/system/[
  cpu,
  disk,
  memory,
  network,
  process,
  power
]
import ../src/internal/darwin_errors
import ../src/internal/[cpu_types, disk_types, memory_types, network_types, process_types, power_types]


type
  MockMetricProvider* = ref object
    ## Mock provider for testing metric collection
    cpuMetrics*: CPUMetrics
    memoryMetrics*: memory_types.MemoryMetrics
    diskMetrics*: DiskMetrics
    networkMetrics*: NetworkMetrics
    processMetrics*: ProcessMetrics
    powerMetrics*: PowerMetrics
    shouldFailCPU*: bool
    shouldFailMemory*: bool
    shouldDelayMemory*: bool
    memoryDelay*: int
    failureMsg*: string

proc newMockMetricProvider*(): MockMetricProvider =
  ## Creates a mock provider with default values
  result = MockMetricProvider(
    cpuMetrics: CPUMetrics(
      physicalCores: 8,
      logicalCores: 16,
      architecture: "arm64",
      model: "MacBookPro18,2",
      brand: "Apple M1 Pro",
      frequency: CPUFrequency(
        nominal: 2400.0,
        current: none(float),
        max: some(3200.0),
        min: some(600.0)
    ),
    usage: CPUUsage(
      user: 10.0,
      system: 5.0,
      idle: 85.0,
      nice: 0.0,
      total: 15.0
    )
  ),
    memoryMetrics: memory_types.MemoryMetrics(
      memoryStats: memory_types.MemoryStats(
        totalPhysical: 16_000_000_000'u64,
        availablePhysical: 8_000_000_000'u64,
        usedPhysical: 8_000_000_000'u64,
        pageSize: 4096'u32,
        pagesFree: 2_000_000'u64,
        pagesActive: 1_000_000'u64,
        pagesInactive: 500_000'u64,
        pagesWired: 250_000'u64,
        pagesCompressed: 100_000'u64,
        pressureLevel: memory_types.MemoryPressureLevel.mplNormal,
        timestamp: getTime().toUnix
      ),
      timestamp: getTime().toUnix
    ),
    diskMetrics: DiskMetrics(
      volumes: @[DiskInfo(
        name: "test",
        mountPoint: "/",
        fileSystem: "apfs",
        total: 1_000_000_000_000'i64,
        used: 500_000_000_000'i64,
        free: 500_000_000_000'i64,
        isRemovable: false,
        isLocal: true,
        timestamp: getTime().toUnix,
        totalSpace: 1_000_000_000_000'i64,
        freeSpace: 500_000_000_000'i64,
        readBytes: 1_000_000'i64,
        writeBytes: 500_000'i64,
        readOps: 1000'i64,
        writeOps: 500'i64
      )],
      ioStats: DiskIOStats(
        readOperations: 1000'i64,
        writeOperations: 500'i64,
        readBytes: 1_000_000'i64,
        writeBytes: 500_000'i64,
        readTime: 100'i64,
        writeTime: 50'i64
      ),
      timestamp: getTime().toUnix
    ),
    networkMetrics: NetworkMetrics(
      interfaces: @[NetworkInfo(
        networkInterface: NetworkInterfaceInfo(
          name: "en0",
          displayName: "Ethernet",
          macAddress: "00:00:00:00:00:00",
          ipv4Address: "192.168.1.1",
          ipv6Address: "fe80::1",
          interfaceType: NetworkInterfaceType.nitEthernet,
          isUp: true
        ),
        stats: NetworkStats(
          bytesReceived: 1_000_000'i64,
          bytesSent: 500_000'i64,
          packetsReceived: 10_000'i64,
          packetsSent: 5_000'i64
        )
      )],
      timestamp: getTime().toUnix
    ),
    processMetrics: ProcessMetrics(
      info: ProcessInfo(
        pid: 1,
        ppid: 0,
        name: "test",
        executable: "/usr/bin/test",
        status: ProcessStatus.psRunning,
        startTime: getTime().toUnix
      ),
      resources: ProcessResourceUsage(
        cpuUser: 20.5,
        cpuSystem: 10.5,
        cpuTotal: 31.0,
        cpuPercent: 5.0,
        memoryRSS: 2_000_000_000'i64,
        memoryVirtual: 4_000_000_000'i64,
        memoryShared: 1_000_000_000'i64,
        ioRead: 1_000_000'i64,
        ioWrite: 500_000'i64
      ),
      threads: 4,
      openFiles: 100,
      timestamp: getTime().toUnix
    ),
    powerMetrics: PowerMetrics(
      isPresent: true,
      status: PowerStatus.Charging,
      source: PowerSource.AC,
      percentRemaining: 80.0,
      timeRemaining: some(120),
      timeToFull: some(30),
      health: some(BatteryHealth(
        cycleCount: 100,
        condition: "Normal",
        temperature: 35.0,
        designCapacity: 5000,
        currentCapacity: 4500,
        maxCapacity: 4800
      )),
      isLowPower: false,
      thermalPressure: ThermalPressure.Normal,
      timestamp: getTime().toUnix
    ),
    shouldFailCPU: false,
    shouldFailMemory: false,
    shouldDelayMemory: false,
    memoryDelay: 0,
    failureMsg: ""
  )

template checkMetricSnapshot*(snapshot: MetricSnapshot,
    provider: MockMetricProvider) =
  ## Checks that a snapshot matches the mock provider's values
  check snapshot != nil
  check snapshot.cpuMetrics == provider.cpuMetrics
  check snapshot.memoryMetrics == provider.memoryMetrics
  check snapshot.diskMetrics == provider.diskMetrics
  check snapshot.networkMetrics == provider.networkMetrics
  check snapshot.processMetrics == provider.processMetrics
  check snapshot.powerMetrics == provider.powerMetrics

template runAsyncTest*(body: untyped) =
  ## Runs an async test with proper cleanup
  try:
    waitFor(body)
  except CatchableError as e:
    require(false, "Async test failed: " & e.msg)
