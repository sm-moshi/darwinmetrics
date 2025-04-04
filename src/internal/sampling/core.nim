## Core types and interfaces for metric sampling.
##
## This module provides the fundamental types and interfaces used by the
## async/await backend implementations without importing any backend-specific code.
## It serves as the foundation for the sampling system's type hierarchy and
## defines the core contracts that metric collectors must fulfill.
##
## Key Components:
## * Base types for metric values and results
## * Sampling configuration interfaces
## * Error types and handling
## * Duration and timing primitives
##
## This module is intentionally minimal and backend-agnostic to allow for:
## * Easy testing without backend dependencies
## * Potential future support for alternative async backends
## * Clear separation of concerns in the sampling system
##
## Note: This module should not import any backend-specific modules
## (like chronos). Those dependencies belong in the backend implementations.

