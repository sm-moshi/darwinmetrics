## Unified sampling implementation for Darwin metrics.
##
## This module provides the high-level interface for metric sampling,
## delegating the actual collection work to the Chronos backend.
## It follows the async/await paradigm for efficient concurrent collection.
##
## Example:
##
## ```nim
## let config = newSamplerConfig(seconds(5))
## let sampler = newSampler(config)
## await sampler.start()
## ```

