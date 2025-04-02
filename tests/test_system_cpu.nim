## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils, times, deques]
import pkg/chronos
import pkg/chronos/timer
import ../src/system/cpu
import ../src/internal/darwin_errors
import ../src/internal/cpu_types

const FloatEpsilon = 1e-6

proc almostEqual(a, b: float): bool =
  ## Float comparison with epsilon
  abs(a - b) < FloatEpsilon

when defined(darwin):
  when defined(threads):
    var weaveInitialized = false

    proc ensureWeaveInit() =
      if not weaveInitialized:
        init(Weave)
        weaveInitialized = true

    proc cleanupWeave() =
      if weaveInitialized:
        exit(Weave)
        weaveInitialized = false

  suite "CPU Information Tests":
    test "getCpuMetrics returns valid information":
      proc testAsync() {.async: (raises: [Exception]).} =
        let metrics = await getCpuMetrics()
        check:
          metrics.architecture in ["arm64", "x86_64"]
          metrics.model.len > 0
          # GitHub runners may have different model naming conventions
          # metrics.model.startsWith("Mac")
          metrics.brand.len > 0
          ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
          # Check frequency information
          metrics.frequency.nominal > 0.0 # Base frequency should be available
          metrics.frequency.current.isNone # Current frequency not available in user mode
          # Max and min frequencies are optional
          (if metrics.frequency.max.isSome: metrics.frequency.max.get() >=
              metrics.frequency.nominal
          else: true)
          (if metrics.frequency.min.isSome: metrics.frequency.min.get() <=
              metrics.frequency.nominal
          else: true)
          # Check CPU usage values are valid
          metrics.usage.user >= 0.0 and metrics.usage.user <= 100.0
          metrics.usage.system >= 0.0 and metrics.usage.system <= 100.0
          metrics.usage.idle >= 0.0 and metrics.usage.idle <= 100.0
          metrics.usage.nice >= 0.0 and metrics.usage.nice <= 100.0
          metrics.usage.total >= 0.0 and metrics.usage.total <= 100.0
          # Total should be complement of idle
          almostEqual(metrics.usage.total, 100.0 - metrics.usage.idle)
          # Sum of user, system, idle, and nice should be approximately 100%
          almostEqual(metrics.usage.user + metrics.usage.system + metrics.usage.idle +
              metrics.usage.nice, 100.0)
      waitFor testAsync()

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      check:
        str.contains("Architecture: arm64")
        str.contains("Model: MacBookPro18,3")
        str.contains("Brand: Apple M1 Pro")
        str.contains("Physical Cores: 8")
        str.contains("Logical Cores: 8")

    test "CpuMetrics string representation is formatted correctly":
      proc testAsync() {.async: (raises: [Exception]).} =
        let metrics = await getCpuMetrics()
        let str = $metrics
        check:
          str.contains("Physical Cores:")
          str.contains("Logical Cores:")
          str.contains("Architecture:")
          str.contains("Model:")
          str.contains("Brand:")
          str.contains("Frequency:")
          str.contains("Nominal:")
          str.contains("Current: Not available")
          str.contains("CPU Usage:")
          str.contains("User:")
          str.contains("System:")
          str.contains("Nice:")
          str.contains("Idle:")
          str.contains("Total:")
      waitFor testAsync()

    test "newCpuMetrics handles missing frequency gracefully":
      var freq = CpuFrequency()
      freq.nominal = 3500.0 # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)

      var metrics = newCpuMetrics(
        physicalCores = 8,
        logicalCores = 8,
        architecture = "arm64",
        model = "MacBookPro18,2",
        brand = "Apple M2 Pro",
        frequency = freq
      )
      metrics.usage = CpuUsage(
        user: 0.0,
        system: 0.0,
        idle: 100.0,
        nice: 0.0,
        total: 0.0
      )
      let str = $metrics
      check:
        str.contains("Frequency:")
        str.contains("MHz") # Just check for MHz unit
        str.contains("Current: Not available")

    test "getCpuMetrics validates core counts":
      let metrics = waitFor getCpuMetrics()
      check:
        metrics.physicalCores > 0
        metrics.logicalCores >= metrics.physicalCores
        metrics.logicalCores mod metrics.physicalCores == 0
          # Logical cores should be a multiple of physical cores

    test "getCpuMetrics architecture matches system":
      let metrics = waitFor getCpuMetrics()
      when defined(amd64):
        check metrics.architecture == "x86_64"
      when defined(arm64):
        check metrics.architecture == "arm64"

    test "getCpuMetrics brand string is consistent":
      let metrics = waitFor getCpuMetrics()
      when defined(arm64):
        check "Apple" in metrics.brand
      when defined(amd64):
        check "Intel" in metrics.brand

    test "newCpuMetrics handles invalid core counts":
      expect (ref DarwinError):
        discard newCpuMetrics(
          physicalCores = -1,
          logicalCores = 8,
          architecture = "arm64",
          model = "Test",
          brand = "Test",
          frequency = CpuFrequency()
        )

    test "newCpuMetrics handles invalid architecture":
      expect (ref DarwinError):
        discard newCpuMetrics(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "invalid",
          model = "Test",
          brand = "Test",
          frequency = CpuFrequency()
        )

    test "newCpuMetrics handles empty model/brand":
      expect (ref DarwinError):
        discard newCpuMetrics(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "arm64",
          model = "",
          brand = "",
          frequency = CpuFrequency()
        )

    test "CPU usage values are consistent":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let usage1 = getCpuUsage()
        check:
          usage1.user >= 0.0 and usage1.user <= 100.0
          usage1.system >= 0.0 and usage1.system <= 100.0
          usage1.idle >= 0.0 and usage1.idle <= 100.0
          usage1.nice >= 0.0 and usage1.nice <= 100.0
          usage1.total >= 0.0 and usage1.total <= 100.0
          almostEqual(usage1.total, 100.0 - usage1.idle)
          almostEqual(usage1.user + usage1.system + usage1.idle + usage1.nice, 100.0)

        # Sleep briefly to allow for CPU activity
        await chronos.sleepAsync(100)

        let usage2 = getCpuUsage()
        check:
          usage2.user >= 0.0 and usage2.user <= 100.0
          usage2.system >= 0.0 and usage2.system <= 100.0
          usage2.idle >= 0.0 and usage2.idle <= 100.0
          usage2.nice >= 0.0 and usage2.nice <= 100.0
          usage2.total >= 0.0 and usage2.total <= 100.0
          almostEqual(usage2.total, 100.0 - usage2.idle)
          almostEqual(usage2.user + usage2.system + usage2.idle + usage2.nice, 100.0)
      waitFor testAsync()

    test "CPU usage string representation is formatted correctly":
      let usage = getCpuUsage()
      let str = $usage
      check:
        str.contains("CPU Usage:")
        str.contains("User:")
        str.contains("System:")
        str.contains("Nice:")
        str.contains("Idle:")
        str.contains("Total:")
        str.contains("%") # Should show percentages

    test "CpuFrequency string representation is formatted correctly":
      var freq = CpuFrequency()
      freq.nominal = 3500.0 # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = some(3500.0)
      freq.min = some(600.0)
      let str = $freq
      check:
        str.contains("MHz") # Just check for MHz unit
        str.contains("Current: Not available")
        str.contains("Max:")
        str.contains("Min:")

    test "CpuFrequency handles missing values":
      var freq = CpuFrequency()
      freq.nominal = 3500.0 # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)
      let str = $freq
      check:
        str.contains("MHz") # Just check for MHz unit
        str.contains("Current: Not available")
        not str.contains("Max:")
        not str.contains("Min:")

  suite "Load Average Tests":
    when defined(threads):
      setup:
        ensureWeaveInit()

      teardown:
        cleanupWeave()

    test "getLoadAverageAsync returns valid load averages":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        let load = metrics.loadAverage
        check:
          load.oneMinute >= 0.0 # Load can be higher than 1.0 on busy systems
          load.fiveMinute >= 0.0
          load.fifteenMinute >= 0.0
          load.timestamp <= getTime() # Timestamp should be now or in the past
          # Load averages should follow a pattern (not strictly required but common)
          load.oneMinute >= load.fiveMinute or load.oneMinute <=
              load.fiveMinute * 2.0
          load.fiveMinute >= load.fifteenMinute or load.fiveMinute <=
              load.fifteenMinute * 2.0
      waitFor testAsync()

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.23,
        fiveMinute: 0.45,
        fifteenMinute: 0.67,
        timestamp: getTime()
      )
      let str = $load
      check:
        str.contains("1 minute:  1.23")
        str.contains("5 minute:  0.45")
        str.contains("15 minute: 0.67")
        str.contains("Timestamp: ")

    test "LoadAverage validation catches invalid values":
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: -1.0,
          fiveMinute: 0.5,
          fifteenMinute: 0.5,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: -1.0,
          fifteenMinute: 0.5,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: 0.5,
          fifteenMinute: -1.0,
          timestamp: getTime()
        )
      expect DarwinError:
        discard $LoadAverage(
          oneMinute: 0.5,
          fiveMinute: 0.5,
          fifteenMinute: 0.5,
          timestamp: getTime() + 5.minutes # Future timestamp
        )

    test "LoadHistory maintains size and order":
      var history = newLoadHistory(maxSamples = 2)
      let now = getTime()

      # First sample
      let sample1 = LoadAverage(
        oneMinute: 0.1,
        fiveMinute: 0.2,
        fifteenMinute: 0.3,
        timestamp: now - 2.minutes
      )
      history.add(sample1)
      check history.len == 1

      # Second sample
      let sample2 = LoadAverage(
        oneMinute: 0.4,
        fiveMinute: 0.5,
        fifteenMinute: 0.6,
        timestamp: now - 1.minutes
      )
      history.add(sample2)
      check history.len == 2

      # Third sample (should remove first)
      let sample3 = LoadAverage(
        oneMinute: 0.7,
        fiveMinute: 0.8,
        fifteenMinute: 0.9,
        timestamp: now
      )
      history.add(sample3)
      check history.len == 2

    test "LoadHistory handles empty state":
      let history = newLoadHistory()
      check:
        history.len == 0
        history.maxSamples == 60 # Default max samples

    when defined(threads):
      test "LoadHistory is thread-safe":
        const NumThreads = 4
        const SamplesPerThread = 100
        let history = newLoadHistory(maxSamples = NumThreads * SamplesPerThread)

        proc addSamples(hist: LoadHistory) {.gcsafe.} =
          let now = getTime()
          for i in 0..<SamplesPerThread:
            let load = LoadAverage(
              oneMinute: float(i),
              fiveMinute: float(i),
              fifteenMinute: float(i),
              timestamp: now + initDuration(seconds = i)
            )
            hist.add(load)

        var tasks: array[NumThreads, FlowVar[void]]
        for i in 0..<NumThreads:
          tasks[i] = spawn addSamples(history)
        sync()

        check:
          history.len <= history.maxSamples
          history.len >= min(NumThreads * SamplesPerThread,
              history.maxSamples)

      test "LoadHistory handles concurrent read/write":
        let history = newLoadHistory(maxSamples = 100)
        let now = getTime()

        # Add some initial data
        for i in 0..<50:
          history.add(LoadAverage(
            oneMinute: float(i),
            fiveMinute: float(i),
            fifteenMinute: float(i),
            timestamp: now + initDuration(seconds = i)
          ))

        # Spawn threads to read and write concurrently
        proc reader(hist: LoadHistory) {.gcsafe.} =
          for i in 0..<100:
            let len = hist.len
            check len <= hist.maxSamples

        proc writer(hist: LoadHistory) {.gcsafe.} =
          for i in 50..<100:
            hist.add(LoadAverage(
              oneMinute: float(i),
              fiveMinute: float(i),
              fifteenMinute: float(i),
              timestamp: now + initDuration(seconds = i)
            ))

        var tasks: array[2, FlowVar[void]]
        tasks[0] = spawn reader(history)
        tasks[1] = spawn writer(history)
        sync()

        check:
          history.len <= history.maxSamples
          history.len > 0

  suite "Per-Core CPU Load Tests":
    test "getPerCoreCpuLoadInfo returns data for each core":
      let coreInfo = getPerCoreCpuLoadInfo()
      let metrics = waitFor getCpuMetrics()

      check:
        coreInfo.len == metrics.logicalCores
        coreInfo.len > 0

    test "Per-core load information contains valid tick values":
      let coreInfo = getPerCoreCpuLoadInfo()

      for i, core in coreInfo:
        check:
          core.userTicks[0] >= 0'u32
          core.systemTicks[0] >= 0'u32
          core.idleTicks[0] >= 0'u32
          core.niceTicks[0] >= 0'u32
          # At least one state should have non-zero ticks
          core.userTicks[0] + core.systemTicks[0] + core.idleTicks[0] +
              core.niceTicks[0] > 0'u32

    test "Multiple calls to getPerCoreCpuLoadInfo show increasing tick counts":
      let firstSample = getPerCoreCpuLoadInfo()

      # Do some work to ensure CPU activity
      var x = 0
      for i in 0..<1_000_000:
        x += i mod 100

      # Get second sample after some CPU activity
      let secondSample = getPerCoreCpuLoadInfo()

      check:
        firstSample.len == secondSample.len

      var ticksIncreased = false
      for i in 0..<firstSample.len:
        let totalTicksFirst = firstSample[i].userTicks[0] +
                              firstSample[i].systemTicks[0] +
                              firstSample[i].idleTicks[0] +
                              firstSample[i].niceTicks[0]

        let totalTicksSecond = secondSample[i].userTicks[0] +
                               secondSample[i].systemTicks[0] +
                               secondSample[i].idleTicks[0] +
                               secondSample[i].niceTicks[0]

        if totalTicksSecond > totalTicksFirst:
          ticksIncreased = true
          break

      check ticksIncreased

    test "Per-core load information structure matches HostCpuLoadInfo format":
      let coreInfo = getPerCoreCpuLoadInfo()

      for core in coreInfo:
        check:
          core.userTicks.len == 4
          core.systemTicks.len == 4
          core.idleTicks.len == 4
          core.niceTicks.len == 4
          # Only first element contains data, others are zero
          core.userTicks[1] == 0'u32
          core.userTicks[2] == 0'u32
          core.userTicks[3] == 0'u32
          core.systemTicks[1] == 0'u32
          core.systemTicks[2] == 0'u32
          core.systemTicks[3] == 0'u32

    test "Load average tracking works":
      let history = newLoadHistory(maxSamples = 5)
      let metrics = waitFor getCpuMetrics()
      check:
        metrics.loadAverage.oneMinute >= 0.0
        metrics.loadAverage.fiveMinute >= 0.0
        metrics.loadAverage.fifteenMinute >= 0.0
        metrics.loadAverage.timestamp <= getTime()

      history.add(metrics.loadAverage)
      check history.len == 1

else:
  echo "Skipping CPU tests on non-Darwin platform"

when defined(macosx):
  suite "CPU Information":
    test "getCpuMetrics returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        check:
          metrics.architecture in ["arm64", "x86_64"]
          metrics.model.len > 0
          metrics.brand.len > 0
          ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
      waitFor testAsync()

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      check:
        str.contains("Architecture: arm64")
        str.contains("Model: MacBookPro18,3")
        str.contains("Brand: Apple M1 Pro")
        str.contains("Physical Cores: 8")
        str.contains("Logical Cores: 8")

    test "CpuMetrics string representation is formatted correctly":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        let str = $metrics
        check:
          str.contains("Architecture: " & metrics.architecture)
          str.contains("Model: " & metrics.model)
          str.contains("Brand: " & metrics.brand)
          str.contains("Physical Cores: " & $metrics.physicalCores)
          str.contains("Logical Cores: " & $metrics.logicalCores)
      waitFor testAsync()

  suite "Load Average":
    test "getLoadAverage returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        let load = metrics.loadAverage
        check:
          load.oneMinute >= 0.0
          load.fiveMinute >= 0.0
          load.fifteenMinute >= 0.0
          load.timestamp <= getTime()
      waitFor testAsync()

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.5,
        fiveMinute: 2.0,
        fifteenMinute: 1.8,
        timestamp: getTime()
      )
      let str = $load
      check:
        str.contains("1 minute:  1.50")
        str.contains("5 minute:  2.00")
        str.contains("15 minute: 1.80")
        str.contains("Timestamp:")

  suite "CPU Usage":
    test "CPU usage values are valid":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        let metrics = await getCpuMetrics()
        check:
          metrics.usage.user >= 0.0 and metrics.usage.user <= 100.0
          metrics.usage.system >= 0.0 and metrics.usage.system <= 100.0
          metrics.usage.idle >= 0.0 and metrics.usage.idle <= 100.0
          metrics.usage.nice >= 0.0 and metrics.usage.nice <= 100.0
          abs(metrics.usage.user + metrics.usage.system + metrics.usage.idle + metrics.usage.nice - 100.0) <= 0.1
      waitFor testAsync()

    test "CPU usage tracking":
      proc testAsync() {.async: (raises: [DarwinError, CancelledError, Exception]).} =
        var metrics = await getCpuMetrics()
        await chronos.sleepAsync(100)
        metrics = await getCpuMetrics()
        check:
          metrics.usage.user >= 0.0
          metrics.usage.system >= 0.0
          metrics.usage.idle >= 0.0
          metrics.usage.nice >= 0.0
      waitFor testAsync()
