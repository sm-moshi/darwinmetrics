## Error types for Darwin-specific operations
##
## This module defines custom error types for Darwin platform operations.

type
  DarwinError* = object of CatchableError
    ## Base error type for Darwin-specific operations

  DarwinVersionError* = object of DarwinError
    ## Error raised when Darwin version requirements are not met
