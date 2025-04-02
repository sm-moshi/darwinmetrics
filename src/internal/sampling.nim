## Metric sampling implementation using Chronos async framework.
##
## This module provides a unified interface for metric sampling using the
## Chronos async framework for efficient concurrent metric collection.
##
## Example:
## ```nim
## import sampling
##
## # Create a sampler
## let sampler = newMetricSampler()
##
## # Start collecting metrics (async operation)
## waitFor sampler.start()
## ```

# Import the core module which provides the types and interfaces
import ./sampling/core
export core

# Import the duration converters
import ./sampling/converters

# Import Chronos backend
import pkg/chronos
import ./sampling/chronos_backend

# Export the sampler type
type Sampler* = ChronosSampler

proc newSampler*(
    kinds: set[MetricKind] = {low(MetricKind)..high(MetricKind)},
    interval: SamplingDuration = seconds(5),
    maxSnapshots: int = 60
): Sampler =
  ## Create a new Chronos-based sampler
  result = newChronosSampler(kinds, interval, maxSnapshots)

# Provide a unified API with a more general name
proc newMetricSampler*(
    kinds: set[MetricKind] = {low(MetricKind)..high(MetricKind)},
    interval: SamplingDuration = seconds(5),
    maxSnapshots: int = 60
): Sampler =
  ## Creates a new metric sampler using Chronos async framework.
  ##
  ## Parameters:
  ##   kinds: Set of metrics to collect (default: all)
  ##   interval: How often to collect metrics (default: 5 seconds)
  ##   maxSnapshots: Maximum number of snapshots to retain (default: 60, 0 = unlimited)
  ##
  ## Returns:
  ##   A new metric sampler instance
  newSampler(kinds, interval, maxSnapshots)
