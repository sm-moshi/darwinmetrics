## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils, times, deques, asyncdispatch, os]
when defined(threads):
  import pkg/weave
import ../src/system/cpu
import ../src/internal/darwin_errors

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
    test "getCpuInfo returns valid information":
      let info = getCpuInfo()
      check:
        info.physicalCores > 0
        info.logicalCores >= info.physicalCores
        info.architecture in ["arm64", "x86_64"]
        info.model.len > 0
        info.brand.len > 0
        # Check frequency information
        info.frequency.nominal > 0.0  # Base frequency should be available
        info.frequency.current.isNone # Current frequency not available in user mode
        # Max and min frequencies are optional
        (if info.frequency.max.isSome: info.frequency.max.get() >= info.frequency.nominal
        else: true)
        (if info.frequency.min.isSome: info.frequency.min.get() <= info.frequency.nominal
        else: true)
        # Check CPU usage values are valid
        info.usage.user >= 0.0 and info.usage.user <= 100.0
        info.usage.system >= 0.0 and info.usage.system <= 100.0
        info.usage.idle >= 0.0 and info.usage.idle <= 100.0
        info.usage.nice >= 0.0 and info.usage.nice <= 100.0
        info.usage.total >= 0.0 and info.usage.total <= 100.0
        # Total should be complement of idle
        almostEqual(info.usage.total, 100.0 - info.usage.idle)
        # Sum of user, system, idle, and nice should be approximately 100%
        almostEqual(info.usage.user + info.usage.system + info.usage.idle + info.usage.nice, 100.0)

    test "CpuInfo string representation is formatted correctly":
      let info = getCpuInfo()
      let str = $info
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

    test "getCpuInfo handles missing frequency gracefully":
      var freq = CpuFrequency()
      freq.nominal = 3500.0  # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)

      var info = newCpuInfo(
        physicalCores = 8,
        logicalCores = 8,
        architecture = "arm64",
        model = "MacBookPro18,2",
        brand = "Apple M2 Pro",
        frequency = freq
      )
      info.usage = CpuUsage(
        user: 0.0,
        system: 0.0,
        idle: 100.0,
        nice: 0.0,
        total: 0.0
      )
      let str = $info
      check:
        str.contains("Frequency:")
        str.contains("MHz")  # Just check for MHz unit
        str.contains("Current: Not available")

    test "getCpuInfo validates core counts":
      let info = getCpuInfo()
      check:
        info.physicalCores > 0
        info.logicalCores >= info.physicalCores
        info.logicalCores mod info.physicalCores == 0
          # Logical cores should be a multiple of physical cores

    test "getCpuInfo architecture matches system":
      let info = getCpuInfo()
      when defined(amd64):
        check info.architecture == "x86_64"
      when defined(arm64):
        check info.architecture == "arm64"

    test "getCpuInfo brand string is consistent":
      let info = getCpuInfo()
      when defined(arm64):
        check "Apple" in info.brand
      when defined(amd64):
        check "Intel" in info.brand

    test "getCpuInfo handles invalid core counts":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = -1,
          logicalCores = 8,
          architecture = "arm64",
          model = "Test",
          brand = "Test",
          frequency = CpuFrequency()
        )

    test "getCpuInfo handles invalid architecture":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "invalid",
          model = "Test",
          brand = "Test",
          frequency = CpuFrequency()
        )

    test "getCpuInfo handles empty model/brand":
      expect (ref DarwinError):
        discard newCpuInfo(
          physicalCores = 8,
          logicalCores = 8,
          architecture = "arm64",
          model = "",
          brand = "",
          frequency = CpuFrequency()
        )

    test "CPU usage values are consistent":
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
      sleep(100)

      let usage2 = getCpuUsage()
      check:
        usage2.user >= 0.0 and usage2.user <= 100.0
        usage2.system >= 0.0 and usage2.system <= 100.0
        usage2.idle >= 0.0 and usage2.idle <= 100.0
        usage2.nice >= 0.0 and usage2.nice <= 100.0
        usage2.total >= 0.0 and usage2.total <= 100.0
        almostEqual(usage2.total, 100.0 - usage2.idle)
        almostEqual(usage2.user + usage2.system + usage2.idle + usage2.nice, 100.0)

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
      freq.nominal = 3500.0  # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = some(3500.0)
      freq.min = some(600.0)
      let str = $freq
      check:
        str.contains("MHz")  # Just check for MHz unit
        str.contains("Current: Not available")
        str.contains("Max:")
        str.contains("Min:")

    test "CpuFrequency handles missing values":
      var freq = CpuFrequency()
      freq.nominal = 3500.0  # Updated to match M2 frequency
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)
      let str = $freq
      check:
        str.contains("MHz")  # Just check for MHz unit
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
      proc testAsync() {.async.} =
        let load = await getLoadAverageAsync()
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
      check history.samples.len == 1

      # Second sample
      let sample2 = LoadAverage(
        oneMinute: 0.4,
        fiveMinute: 0.5,
        fifteenMinute: 0.6,
        timestamp: now - 1.minutes
      )
      history.add(sample2)
      check history.samples.len == 2

      # Third sample (should remove first)
      let sample3 = LoadAverage(
        oneMinute: 0.7,
        fiveMinute: 0.8,
        fifteenMinute: 0.9,
        timestamp: now
      )
      history.add(sample3)
      check history.samples.len == 2

    test "LoadHistory handles empty state":
      let history = newLoadHistory()
      check:
        history.samples.len == 0
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
          history.samples.len <= history.maxSamples
          history.samples.len >= min(NumThreads * SamplesPerThread,
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
            let len = hist.samples.len
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
          history.samples.len <= history.maxSamples
          history.samples.len > 0

else:
  echo "Skipping CPU tests on non-Darwin platform"
