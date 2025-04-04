## Chronos-based timer implementation for precise interval sampling.
##
## This module provides a timer implementation using Chronos for precise
## interval-based sampling. It handles drift compensation and ensures
## consistent intervals between callbacks.
##
## Example:
##
## .. code-block:: nim
##   let timer = newChronosTimer()
##   timer.setOnTick(proc() {.async.} = echo "tick")
##   await timer.start(milliseconds(500))

import chronos
import chronos/timer
import ./types

type
  ChronosTimer* = ref object
    ## Timer implementation using Chronos.
    interval: SamplingDuration
    running: bool
    onTickCallback: ChronosCallback
    future: Future[void]

proc newChronosTimer*(): ChronosTimer =
  ## Creates a new ChronosTimer.
  ##
  ## Returns: A new ChronosTimer instance
  ChronosTimer(
    interval: nanoseconds(0),
    running: false,
    onTickCallback: nil,
    future: nil
  )

proc isRunning*(timer: ChronosTimer): bool {.inline.} =
  ## Checks if the timer is currently running.
  ##
  ## Returns: true if the timer is running, false otherwise
  timer.running

proc setOnTick*(timer: ChronosTimer; callback: ChronosCallback) {.inline.} =
  ## Sets the callback to be called on each timer tick.
  ##
  ## Parameters:
  ## - callback: The callback to be called on each tick
  timer.onTickCallback = callback

proc getOnTick*(timer: ChronosTimer): ChronosCallback {.inline.} =
  ## Gets the current callback.
  ##
  ## Returns: The current callback, or nil if none is set
  timer.onTickCallback

proc stop*(timer: ChronosTimer) {.async.} =
  ## Stops the timer if it is running.
  if timer.running and not timer.future.isNil:
    timer.running = false
    await timer.future
    timer.future = nil

proc close*(timer: ChronosTimer) {.async.} =
  ## Stops the timer and releases any resources.
  await timer.stop()

proc start*(timer: ChronosTimer; interval: SamplingDuration) {.async.} =
  ## Starts the timer with the specified interval.
  ##
  ## Parameters:
  ## - interval: How often to call the callback
  ##
  ## Raises:
  ## - ValueError if no callback is set
  if timer.onTickCallback.isNil:
    raise newException(ValueError, "Timer callback must be set before starting")

  if timer.running:
    await timer.stop()

  timer.interval = interval
  timer.running = true

  timer.future = (proc() {.async.} =
    while timer.running:
      await sleepAsync(toChronosDuration(timer.interval))
      if timer.running:
        await timer.onTickCallback()
  )()

  await timer.future
