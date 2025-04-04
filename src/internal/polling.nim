## Async polling helpers for metric collection.
##
## This module provides reusable async polling primitives with proper
## cancellation, timeout handling, and backoff support.

import std/times
import chronos
import chronos/timer
import ./sampling/core

export chronos.seconds, chronos.milliseconds, chronos.nanoseconds
export chronos.AsyncTimeoutError, chronos.CancelledError

type
  PollError* = object of CatchableError
    ## Error that occurred during polling
    retryCount*: int        ## Number of retries attempted
    lastAttempt*: Time      ## When the last attempt was made

  PollConfig* = object
    ## Configuration for polling behaviour
    baseInterval*: chronos.Duration     ## Base interval between polls
    maxInterval*: chronos.Duration      ## Maximum interval (with backoff)
    timeout*: chronos.Duration         ## Maximum time to wait for each poll
    maxRetries*: int          ## Maximum number of retries (0 = infinite)
    backoffFactor*: float     ## Multiply interval by this on failure

proc newPollConfig*(baseInterval = chronos.milliseconds(100),
                   maxInterval = chronos.seconds(5),
                   timeout = chronos.seconds(1),
                   maxRetries = 3,
                   backoffFactor = 2.0): PollConfig =
  ## Creates a new polling configuration with sensible defaults
  PollConfig(
    baseInterval: baseInterval,
    maxInterval: maxInterval,
    timeout: timeout,
    maxRetries: maxRetries,
    backoffFactor: backoffFactor
  )

proc pollAsync*[T](action: proc(): Future[T] {.closure, gcsafe.},
                   config = newPollConfig()): Future[T] {.async: (raises: [PollError, CancelledError]).} =
  ## Executes an async action with retry and backoff logic
  var
    retryCount = 0
    currentInterval = config.baseInterval
    lastError: ref PollError = nil

  while true:
    try:
      let future = action()
      let timeoutFut = withTimeout(future, config.timeout)
      discard await timeoutFut
      if not future.failed:
        return await future
    except CancelledError as e:
      raise e  # Always propagate cancellation
    except AsyncTimeoutError:
      lastError = newException(PollError, "Operation timed out")
      lastError.retryCount = retryCount
      lastError.lastAttempt = getTime()
    except Exception as e:
      lastError = newException(PollError, e.msg)
      lastError.retryCount = retryCount
      lastError.lastAttempt = getTime()

    # Handle retry logic
    inc retryCount
    if config.maxRetries > 0 and retryCount >= config.maxRetries:
      raise lastError

    # Apply exponential backoff
    let nextInterval = chronos.nanoseconds(
      (currentInterval.nanoseconds.float * config.backoffFactor).int
    )
    currentInterval = if nextInterval > config.maxInterval:
      config.maxInterval
    else:
      nextInterval

    await chronos.sleepAsync(currentInterval)

proc pollUntilAsync*[T](action: proc(): Future[T] {.closure, gcsafe.},
                        predicate: proc(val: T): bool {.gcsafe.},
                        config = newPollConfig()): Future[T] {.async: (raises: [PollError, CancelledError]).} =
  ## Polls until predicate returns true or we exceed retries
  while true:
    let val = await pollAsync(action, config)
    if predicate(val):
      return val

proc pollEvery*(interval: chronos.Duration, callback: proc(): Future[void] {.closure, gcsafe.}): Future[void] {.async: (raises: [CancelledError, Exception]).} =
  ## Polls a callback at regular intervals.
  ## The callback must be async and gcsafe.
  ##
  ## Note: This procedure may raise CancelledError if cancelled,
  ## or Exception from the callback or sleep operations.
  while true:
    try:
      try:
        await callback()
      except CancelledError as e:
        raise e
      except CatchableError:
        # Ignore errors in callback
        discard

      await chronos.sleepAsync(interval)
    except CancelledError as e:
      raise e
    except CatchableError:
      # Ignore any other errors and continue polling
      discard
