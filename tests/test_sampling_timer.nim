## Tests for the ChronosTimer implementation.
##
## These tests verify that the timer respects intervals,
## handles cancellation correctly, and cleans up resources.

{.define: useChronos.}

import std/unittest
import chronos
import chronos/timer
import ../src/internal/sampling/[types, chronos_timer]

suite "Sampling Timer":
  test "timer respects interval":
    proc testTimer() {.async.} =
      let timer = newChronosTimer()
      var tickCount = 0

      timer.setOnTick(proc(): Future[void] {.async.} =
        inc tickCount
      )

      await timer.start(milliseconds(100))
      await sleepAsync(milliseconds(350))
      await timer.stop()

      # Should have ticked ~3 times (350ms / 100ms)
      check tickCount >= 3
      check tickCount <= 4

    waitFor testTimer()

  test "timer can be stopped":
    proc testStop() {.async.} =
      let timer = newChronosTimer()
      var tickCount = 0

      timer.setOnTick(proc(): Future[void] {.async.} =
        inc tickCount
      )

      await timer.start(milliseconds(100))
      await sleepAsync(milliseconds(150))
      await timer.stop()
      await sleepAsync(milliseconds(150))

      # Should have ticked ~1-2 times before stopping
      check tickCount >= 1
      check tickCount <= 2

    waitFor testStop()

  test "timer handles errors in callback":
    proc testErrors() {.async.} =
      let timer = newChronosTimer()
      var tickCount = 0

      timer.setOnTick(proc(): Future[void] {.async.} =
        inc tickCount
        if tickCount == 2:
          raise newException(ValueError, "Test error")
      )

      await timer.start(milliseconds(100))
      await sleepAsync(milliseconds(250))
      await timer.stop()

      # Should have ticked twice before error
      check tickCount == 2

    waitFor testErrors()

  test "timer can be closed":
    proc testClose() {.async.} =
      let timer = newChronosTimer()
      var tickCount = 0

      timer.setOnTick(proc(): Future[void] {.async.} =
        inc tickCount
      )

      await timer.start(milliseconds(100))
      await sleepAsync(milliseconds(150))
      await timer.close()
      await sleepAsync(milliseconds(150))

      # Should have ticked ~1-2 times before closing
      check tickCount >= 1
      check tickCount <= 2

    waitFor testClose()

  test "timer requires onTick callback":
    proc testNoCallback() {.async.} =
      let timer = newChronosTimer()
      expect ValueError:
        await timer.start(milliseconds(100))

    waitFor testNoCallback()

  test "timer handles rapid start/stop":
    proc testRapidStartStop() {.async.} =
      let timer = newChronosTimer()
      var tickCount = 0

      timer.setOnTick(proc(): Future[void] {.async.} =
        inc tickCount
      )

      for i in 0..2:
        await timer.start(milliseconds(100))
        await sleepAsync(milliseconds(50))
        await timer.stop()

      # Should have minimal ticks due to rapid stopping
      check tickCount <= 1

    waitFor testRapidStartStop()
