{.define: useChronos.}

import std/unittest
import chronos
import chronos/timer
import ../src/internal/sampling/[types, chronos_backend]

suite "Chronos Sampler":
  test "sampler respects interval":
    proc testSampler() {.async.} =
      var tickCount = 0
      let interval = milliseconds(100)

      let config = newSamplerConfig(
        interval,
        proc(timestamp: UniversalTime): Future[void] {.async.} =
        inc tickCount
      )

      let sampler = newChronosSampler(config)
      await sampler.start()
      await sleepAsync(milliseconds(350))
      await sampler.stop()

      # Should have ticked ~3 times (350ms / 100ms)
      check tickCount >= 3
      check tickCount <= 4

    waitFor testSampler()

  test "sampler can be stopped":
    proc testStop() {.async.} =
      var tickCount = 0
      let interval = milliseconds(100)

      let config = newSamplerConfig(
        interval,
        proc(timestamp: UniversalTime): Future[void] {.async.} =
        inc tickCount
      )

      let sampler = newChronosSampler(config)
      await sampler.start()
      await sleepAsync(milliseconds(150))
      await sampler.stop()
      await sleepAsync(milliseconds(150))

      # Should have ticked ~1-2 times before stopping
      check tickCount >= 1
      check tickCount <= 2

    waitFor testStop()

  test "sampler handles errors in callback":
    proc testErrors() {.async.} =
      var tickCount = 0
      let interval = milliseconds(100)

      let config = newSamplerConfig(
        interval,
        proc(timestamp: UniversalTime): Future[void] {.async.} =
        inc tickCount
        if tickCount == 2:
          raise newException(ValueError, "Test error")
      )

      let sampler = newChronosSampler(config)
      await sampler.start()
      await sleepAsync(milliseconds(250))
      await sampler.stop()

      # Should have ticked twice before error
      check tickCount == 2

    waitFor testErrors()

  test "sampler can be closed":
    proc testClose() {.async.} =
      var tickCount = 0
      let interval = milliseconds(100)

      let config = newSamplerConfig(
        interval,
        proc(timestamp: UniversalTime): Future[void] {.async.} =
        inc tickCount
      )

      let sampler = newChronosSampler(config)
      await sampler.start()
      await sleepAsync(milliseconds(150))
      await sampler.close()
      await sleepAsync(milliseconds(150))

      # Should have ticked ~1-2 times before closing
      check tickCount >= 1
      check tickCount <= 2

    waitFor testClose()

  test "sampler works without callback":
    proc testNoCallback() {.async.} =
      let interval = milliseconds(100)
      let config = newSamplerConfig(interval)
      let sampler = newChronosSampler(config)

      await sampler.start()
      await sleepAsync(milliseconds(150))
      await sampler.stop()

      # Should not raise any errors
      check true

    waitFor testNoCallback()

  test "sampler handles rapid start/stop":
    proc testRapidStartStop() {.async.} =
      var tickCount = 0
      let interval = milliseconds(100)

      let config = newSamplerConfig(
        interval,
        proc(timestamp: UniversalTime): Future[void] {.async.} =
        inc tickCount
      )

      let sampler = newChronosSampler(config)

      for i in 0..2:
        await sampler.start()
        await sleepAsync(milliseconds(50))
        await sampler.stop()

      # Should have minimal ticks due to rapid stopping
      check tickCount <= 1

    waitFor testRapidStartStop()
