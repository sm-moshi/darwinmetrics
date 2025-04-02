## Type converters for sampling module
##
## This module provides converters between the core SamplingDuration type
## and the Duration types from both std/times and chronos/timer.
## It ensures we can seamlessly convert between different time representations.

import ./core
import std/times

when defined(useChronos):
  import pkg/chronos/timer as chronosTimer
  import pkg/chronos/futures as chronosFuture

# Convert from core types to backend types

proc toDuration*(duration: SamplingDuration): times.Duration {.inline.} =
  ## Convert from SamplingDuration to std/times Duration
  initDuration(nanoseconds = inNanoseconds(duration))

proc toUnixNano*(time: Time): int64 {.inline.} =
  ## Convert Time to Unix timestamp in nanoseconds
  let secs = time.toUnix()
  let nanos = time.nanosecond
  (secs.int64 * 1_000_000_000) + nanos.int64

when defined(useChronos):
  proc toChronosDuration*(duration: SamplingDuration): chronosTimer.Duration {.inline.} =
    ## Convert from SamplingDuration to chronos/timer Duration
    chronosTimer.nanoseconds(inNanoseconds(duration))

  proc toMoment*(duration: SamplingDuration): chronosTimer.Moment {.inline.} =
    ## Convert from SamplingDuration to chronos Moment
    chronosTimer.Moment.fromNow(toChronosDuration(duration))

# Convert from backend types to core types

proc fromDuration*(duration: times.Duration): SamplingDuration {.inline.} =
  ## Convert from std/times Duration to SamplingDuration
  nanoseconds(duration.inNanoseconds)

proc fromUnixNano*(timestamp: int64): Time {.inline.} =
  ## Convert Unix timestamp in nanoseconds to Time
  let seconds = timestamp div 1_000_000_000
  let nanosecs = timestamp mod 1_000_000_000
  initTime(seconds, nanosecs.int)

when defined(useChronos):
  proc fromDuration*(duration: chronosTimer.Duration): SamplingDuration {.inline.} =
    ## Convert from chronos/timer Duration to SamplingDuration
    nanoseconds(duration.nanoseconds)

# Converters for seamless integration

converter toDurationConverter*(d: SamplingDuration): times.Duration =
  toDuration(d)

converter fromDurationConverter*(d: times.Duration): SamplingDuration =
  fromDuration(d)

when defined(useChronos):
  converter toChronosDurationConverter*(d: SamplingDuration): chronosTimer.Duration =
    toChronosDuration(d)

  converter fromDurationConverter*(d: chronosTimer.Duration): SamplingDuration =
    fromDuration(d)

# Time converters
converter fromUnixNanoConverter*(timestamp: int64): Time =
  fromUnixNano(timestamp)

converter toUnixNanoConverter*(time: Time): UniversalTime =
  toUnixNano(time)
