{.define: useChronos.}

## Chronos-based sampling backend.
##
## This module provides a sampling backend implementation using Chronos
## for async I/O and precise timing. It is designed to be used with
## the Chronos event loop.
##
## Example:
##
## .. code-block:: nim
##   let config = newSamplerConfig(milliseconds(500))
##   let sampler = newChronosSampler(config)
##   await sampler.start()

import chronos
import chronos/timer
import ./types
import ./chronos_timer

type
  ChronosSampler* = ref object
    ## Chronos-based sampler implementation.
    config: SamplerConfig
    timer: ChronosTimer
    running: bool

proc newChronosSampler*(config: SamplerConfig): ChronosSampler =
  ## Creates a new ChronosSampler.
  ##
  ## Parameters:
  ## - config: The sampler configuration
  ##
  ## Returns: A new ChronosSampler instance
  ChronosSampler(
    config: config,
    timer: newChronosTimer(),
    running: false
  )

proc isRunning*(sampler: ChronosSampler): bool {.inline.} =
  ## Checks if the sampler is currently running.
  ##
  ## Returns: true if the sampler is running, false otherwise
  sampler.running

proc stop*(sampler: ChronosSampler) {.async.} =
  ## Stops the sampler if it is running.
  if sampler.running:
    sampler.running = false
    await sampler.timer.stop()

proc close*(sampler: ChronosSampler) {.async.} =
  ## Stops the sampler and releases any resources.
  await sampler.stop()
  await sampler.timer.close()

proc start*(sampler: ChronosSampler) {.async.} =
  ## Starts the sampler with the configured interval.
  ##
  ## The sampler will collect metrics at each interval and call
  ## the configured callback if one is set.
  if sampler.running:
    return

  sampler.running = true

  # Set up the timer callback
  sampler.timer.setOnTick(proc(): Future[void] {.async.} =
    if sampler.config.callback.isNil:
      return

    try:
      await sampler.config.callback(now())
    except CatchableError as e:
      # Log error but continue running
      echo "Error in sampler callback: ", e.msg
  )

  # Start the timer
  await sampler.timer.start(sampler.config.interval)

