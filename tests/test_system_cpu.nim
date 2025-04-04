## Tests for CPU metrics module
##
## These tests verify the CPU information retrieval functionality
## on Darwin-based systems.

import std/[unittest, options, strutils, times]
import chronos
import chronos/timer
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
      proc testAsync() {.async: (raises: [DarwinError, DarwinVersionError,
          CatchableError]).} =
        let metrics = await getCpuMetrics()
        assert metrics.architecture in ["arm64", "x86_64"]
        assert metrics.model.len > 0
        assert metrics.brand.len > 0
        assert ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
        assert metrics.frequency.nominal > 0.0
        assert metrics.frequency.current.isNone
        assert (if metrics.frequency.max.isSome: metrics.frequency.max.get() >=
            metrics.frequency.nominal else: true)
        assert (if metrics.frequency.min.isSome: metrics.frequency.min.get() <=
            metrics.frequency.nominal else: true)
        assert metrics.usage.user >= 0.0 and metrics.usage.user <= 100.0
        assert metrics.usage.system >= 0.0 and metrics.usage.system <= 100.0
        assert metrics.usage.idle >= 0.0 and metrics.usage.idle <= 100.0
        assert metrics.usage.nice >= 0.0 and metrics.usage.nice <= 100.0
        assert metrics.usage.total >= 0.0 and metrics.usage.total <= 100.0
        assert almostEqual(metrics.usage.total, 100.0 - metrics.usage.idle)
        assert almostEqual(metrics.usage.user + metrics.usage.system +
            metrics.usage.idle + metrics.usage.nice, 100.0)

      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to collect CPU metrics (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      assert str.contains("Architecture: arm64")
      assert str.contains("Model: MacBookPro18,3")
      assert str.contains("Brand: Apple M1 Pro")
      assert str.contains("Physical Cores: 8")
      assert str.contains("Logical Cores: 8")

    test "CpuMetrics string representation is formatted correctly":
      proc testAsync() {.async: (raises: [DarwinError, DarwinVersionError,
          CatchableError]).} =
        let metrics = await getCpuMetrics()
        let str = $metrics
        assert str.contains("Physical Cores:")
        assert str.contains("Logical Cores:")
        assert str.contains("Architecture:")
        assert str.contains("Model:")
        assert str.contains("Brand:")
        assert str.contains("Frequency:")
        assert str.contains("Nominal:")
        assert str.contains("Current: Not available")
        assert str.contains("CPU Usage:")
        assert str.contains("User:")
        assert str.contains("System:")
        assert str.contains("Nice:")
        assert str.contains("Idle:")
        assert str.contains("Total:")

      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to format CPU metrics (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "newCpuMetrics handles missing frequency gracefully":
      var freq = CpuFrequency()
      freq.nominal = 3500.0
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
      assert str.contains("Frequency:")
      assert str.contains("MHz")
      assert str.contains("Current: Not available")

    test "getCpuMetrics validates core counts":
      try:
        let metrics = waitFor getCpuMetrics()
        assert metrics.physicalCores > 0
        assert metrics.logicalCores >= metrics.physicalCores
        assert metrics.logicalCores mod metrics.physicalCores == 0
      except DarwinError as e:
        assert false, "Failed to validate core counts (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "getCpuMetrics architecture matches system":
      try:
        let metrics = waitFor getCpuMetrics()
        when defined(amd64):
          assert metrics.architecture == "x86_64"
        when defined(arm64):
          assert metrics.architecture == "arm64"
      except DarwinError as e:
        assert false, "Failed to validate architecture (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "getCpuMetrics brand string is consistent":
      try:
        let metrics = waitFor getCpuMetrics()
        when defined(arm64):
          assert "Apple" in metrics.brand
        when defined(amd64):
          assert "Intel" in metrics.brand
      except DarwinError as e:
        assert false, "Failed to validate brand string (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

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
      proc testAsync() {.async: (raises: [DarwinError, DarwinVersionError,
          CatchableError]).} =
        let usage1 = getCpuUsage()
        assert usage1.user >= 0.0 and usage1.user <= 100.0
        assert usage1.system >= 0.0 and usage1.system <= 100.0
        assert usage1.idle >= 0.0 and usage1.idle <= 100.0
        assert usage1.nice >= 0.0 and usage1.nice <= 100.0
        assert usage1.total >= 0.0 and usage1.total <= 100.0
        assert almostEqual(usage1.total, 100.0 - usage1.idle)
        assert almostEqual(usage1.user + usage1.system + usage1.idle +
            usage1.nice, 100.0)

        await chronos.sleepAsync(chronos.milliseconds(100))

        let usage2 = getCpuUsage()
        assert usage2.user >= 0.0 and usage2.user <= 100.0
        assert usage2.system >= 0.0 and usage2.system <= 100.0
        assert usage2.idle >= 0.0 and usage2.idle <= 100.0
        assert usage2.nice >= 0.0 and usage2.nice <= 100.0
        assert usage2.total >= 0.0 and usage2.total <= 100.0
        assert almostEqual(usage2.total, 100.0 - usage2.idle)
        assert almostEqual(usage2.user + usage2.system + usage2.idle +
            usage2.nice, 100.0)

      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to validate CPU usage (DarwinError): " & e.msg
      except DarwinVersionError as e:
        assert false, "Unsupported Darwin version: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "CPU usage string representation is formatted correctly":
      let usage = getCpuUsage()
      let str = $usage
      assert str.contains("CPU Usage:")
      assert str.contains("User:")
      assert str.contains("System:")
      assert str.contains("Nice:")
      assert str.contains("Idle:")
      assert str.contains("Total:")
      assert str.contains("%")

    test "CpuFrequency string representation is formatted correctly":
      var freq = CpuFrequency()
      freq.nominal = 3500.0
      freq.current = none(float)
      freq.max = some(3500.0)
      freq.min = some(600.0)
      let str = $freq
      assert str.contains("MHz")
      assert str.contains("Current: Not available")
      assert str.contains("Max:")
      assert str.contains("Min:")

    test "CpuFrequency handles missing values":
      var freq = CpuFrequency()
      freq.nominal = 3500.0
      freq.current = none(float)
      freq.max = none(float)
      freq.min = none(float)
      let str = $freq
      assert str.contains("MHz")

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.23,
        fiveMinute: 0.45,
        fifteenMinute: 0.67,
        timestamp: getTime()
      )
      let str = $load
      require str.contains("1 minute:  1.23")
      require str.contains("5 minute:  0.45")
      require str.contains("15 minute: 0.67")
      require str.contains("Timestamp: ")

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
          timestamp: getTime() + 5.minutes
        )

    test "LoadHistory maintains size and order":
      var history = newLoadHistory(maxSamples = 2)
      let now = getTime()

      let sample1 = LoadAverage(
        oneMinute: 0.1,
        fiveMinute: 0.2,
        fifteenMinute: 0.3,
        timestamp: now - 2.minutes
      )
      history.add(sample1)
      assert history.len == 1

      let sample2 = LoadAverage(
        oneMinute: 0.4,
        fiveMinute: 0.5,
        fifteenMinute: 0.6,
        timestamp: now - 1.minutes
      )
      history.add(sample2)
      assert history.len == 2

      let sample3 = LoadAverage(
        oneMinute: 0.7,
        fiveMinute: 0.8,
        fifteenMinute: 0.9,
        timestamp: now
      )
      history.add(sample3)
      assert history.len == 2

    test "LoadHistory handles empty state":
      let history = newLoadHistory()
      assert history.len == 0
      assert history.maxSamples == 60

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

        assert history.len <= history.maxSamples
        assert history.len >= min(NumThreads * SamplesPerThread,
            history.maxSamples)

      test "LoadHistory handles concurrent read/write":
        let history = newLoadHistory(maxSamples = 100)
        let now = getTime()

        for i in 0..<50:
          history.add(LoadAverage(
            oneMinute: float(i),
            fiveMinute: float(i),
            fifteenMinute: float(i),
            timestamp: now + initDuration(seconds = i)
          ))

        proc reader(hist: LoadHistory) {.gcsafe.} =
          for i in 0..<100:
            let len = hist.len
            assert len <= hist.maxSamples

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

        assert history.len <= history.maxSamples
        assert history.len > 0

  suite "Per-Core CPU Load Tests":
    test "getPerCoreCpuLoadInfo returns data for each core":
      try:
        let coreInfo = getPerCoreCpuLoadInfo()
        let metrics = waitFor getCpuMetrics()

        assert coreInfo.len == metrics.logicalCores
        assert coreInfo.len > 0
      except CatchableError as e:
        assert false, "Failed to get per-core CPU info: " & e.msg

    test "Per-core load information contains valid tick values":
      try:
        let coreInfo = getPerCoreCpuLoadInfo()

        for i, core in coreInfo:
          assert core.userTicks[0] >= 0'u32
          assert core.systemTicks[0] >= 0'u32
          assert core.idleTicks[0] >= 0'u32
          assert core.niceTicks[0] >= 0'u32
          assert core.userTicks[0] + core.systemTicks[0] + core.idleTicks[0] +
              core.niceTicks[0] > 0'u32
      except CatchableError as e:
        assert false, "Failed to validate tick values: " & e.msg

    test "Multiple calls to getPerCoreCpuLoadInfo show increasing tick counts":
      try:
        let firstSample = getPerCoreCpuLoadInfo()

        var x = 0
        for i in 0..<1_000_000:
          x += i mod 100

        let secondSample = getPerCoreCpuLoadInfo()

        assert firstSample.len == secondSample.len

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

        assert ticksIncreased
      except CatchableError as e:
        assert false, "Failed to validate tick count changes: " & e.msg

    test "Per-core load information structure matches HostCpuLoadInfo format":
      try:
        let coreInfo = getPerCoreCpuLoadInfo()

        for core in coreInfo:
          assert core.userTicks.len == 4
          assert core.systemTicks.len == 4
          assert core.idleTicks.len == 4
          assert core.niceTicks.len == 4
          assert core.userTicks[1] == 0'u32
          assert core.userTicks[2] == 0'u32
          assert core.userTicks[3] == 0'u32
          assert core.systemTicks[1] == 0'u32
          assert core.systemTicks[2] == 0'u32
          assert core.systemTicks[3] == 0'u32
      except CatchableError as e:
        assert false, "Failed to validate CPU load info format: " & e.msg

    test "Load average tracking works":
      try:
        let history = newLoadHistory(maxSamples = 5)
        let metrics = waitFor getCpuMetrics()
        assert metrics.loadAverage.oneMinute >= 0.0
        assert metrics.loadAverage.fiveMinute >= 0.0
        assert metrics.loadAverage.fifteenMinute >= 0.0
        assert metrics.loadAverage.timestamp <= getTime()

        history.add(metrics.loadAverage)
        assert history.len == 1
      except CatchableError as e:
        assert false, "Failed to track load average: " & e.msg

else:
  echo "Skipping CPU tests on non-Darwin platform"

when defined(macosx):
  suite "CPU Information":
    test "getCpuMetrics returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CatchableError]).} =
        let metrics = await getCpuMetrics()
        assert metrics.architecture in ["arm64", "x86_64"]
        assert metrics.model.len > 0
        assert metrics.brand.len > 0
        assert ("Intel" in metrics.brand) or ("Apple" in metrics.brand)
      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to get CPU metrics: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "CpuInfo string representation is formatted correctly":
      let info = CpuInfo(
        physicalCores: 8,
        logicalCores: 8,
        architecture: "arm64",
        model: "MacBookPro18,3",
        brand: "Apple M1 Pro"
      )
      let str = $info
      assert str.contains("Architecture: arm64")
      assert str.contains("Model: MacBookPro18,3")
      assert str.contains("Brand: Apple M1 Pro")
      assert str.contains("Physical Cores: 8")
      assert str.contains("Logical Cores: 8")

    test "CpuMetrics string representation is formatted correctly":
      proc testAsync() {.async: (raises: [DarwinError, CatchableError]).} =
        let metrics = await getCpuMetrics()
        let str = $metrics
        assert str.contains("Architecture: " & metrics.architecture)
        assert str.contains("Model: " & metrics.model)
        assert str.contains("Brand: " & metrics.brand)
        assert str.contains("Physical Cores: " & $metrics.physicalCores)
        assert str.contains("Logical Cores: " & $metrics.logicalCores)
      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to format CPU metrics: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

  suite "Load Average":
    test "getLoadAverage returns valid information":
      proc testAsync() {.async: (raises: [DarwinError, CatchableError]).} =
        let metrics = await getCpuMetrics()
        let load = metrics.loadAverage
        assert load.oneMinute >= 0.0
        assert load.fiveMinute >= 0.0
        assert load.fifteenMinute >= 0.0
        assert load.timestamp <= getTime()
      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to get load average: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "LoadAverage string representation is formatted correctly":
      let load = LoadAverage(
        oneMinute: 1.5,
        fiveMinute: 2.0,
        fifteenMinute: 1.8,
        timestamp: getTime()
      )
      let str = $load
      assert str.contains("1 minute:  1.50")
      assert str.contains("5 minute:  2.00")
      assert str.contains("15 minute: 1.80")
      assert str.contains("Timestamp:")

  suite "CPU Usage":
    test "CPU usage values are valid":
      proc testAsync() {.async: (raises: [DarwinError, CatchableError]).} =
        let metrics = await getCpuMetrics()
        assert metrics.usage.user >= 0.0 and metrics.usage.user <= 100.0
        assert metrics.usage.system >= 0.0 and metrics.usage.system <= 100.0
        assert metrics.usage.idle >= 0.0 and metrics.usage.idle <= 100.0
        assert metrics.usage.nice >= 0.0 and metrics.usage.nice <= 100.0
        assert abs(metrics.usage.user + metrics.usage.system +
            metrics.usage.idle + metrics.usage.nice - 100.0) <= 0.1
      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to validate CPU usage: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

    test "CPU usage tracking":
      proc testAsync() {.async: (raises: [DarwinError, CatchableError]).} =
        var metrics = await getCpuMetrics()
        await chronos.sleepAsync(chronos.milliseconds(100))
        metrics = await getCpuMetrics()
        assert metrics.usage.user >= 0.0
        assert metrics.usage.system >= 0.0
        assert metrics.usage.idle >= 0.0
        assert metrics.usage.nice >= 0.0
      try:
        waitFor testAsync()
      except DarwinError as e:
        assert false, "Failed to track CPU usage: " & e.msg
      except CancelledError as e:
        assert false, "Operation cancelled: " & e.msg
      except CatchableError as e:
        assert false, "Unexpected error: " & e.msg

suite "CPU Metrics Collection":
  test "Basic CPU metrics collection":
    try:
      let metrics = waitFor getCpuMetrics()
      assert metrics.timestamp > 0
      assert metrics.usage.user >= 0.0
      assert metrics.usage.system >= 0.0
      assert metrics.usage.idle >= 0.0
      assert metrics.usage.nice >= 0.0
    except CatchableError as e:
      assert false, "Failed to collect CPU metrics: " & e.msg

  test "Async CPU metrics collection":
    proc testAsync() {.async: (raises: [DarwinError, DarwinVersionError,
        CatchableError]).} =
      let metrics = await getCpuMetrics()
      await chronos.sleepAsync(chronos.seconds(1))
      let metrics2 = await getCpuMetrics()
      assert metrics2.timestamp > metrics.timestamp

    try:
      waitFor testAsync()
    except DarwinError as e:
      assert false, "Failed to collect CPU metrics (DarwinError): " & e.msg
    except DarwinVersionError as e:
      assert false, "Unsupported Darwin version: " & e.msg
    except CancelledError as e:
      assert false, "Operation cancelled: " & e.msg
    except CatchableError as e:
      assert false, "Unexpected error: " & e.msg
