## CPU types module for Darwin systems.
##
## This module defines the core types used for CPU metrics in Darwin-based systems.
## It provides type definitions that map to Mach kernel structures and constants
## for CPU statistics, load averages, and frequency information.
##
## The types support both Intel and Apple Silicon architectures, ensuring
## consistent CPU metrics across platforms.
##
## Example:
##
## .. code-block:: nim
##   # Create CPU information object
##   var info = CpuInfo()
##
##   # CPU frequencies can be checked
##   if info.frequency.current.isSome:
##     echo "Current CPU frequency: ", info.frequency.current.get(), " MHz"
##
##   # Load averages can be monitored
##   let load = LoadAverage()
##   echo "1-minute load: ", load.oneMinute

import std/[options, times, deques, locks]

type
  CpuUsage* = object
    ## CPU usage percentages across different states.
    ## All values are percentages between 0-100.
    user*: float                ## Time spent executing user code
    system*: float             ## Time spent in kernel/system calls
    idle*: float               ## Time CPU was idle
    nice*: float               ## Time spent running niced processes
    total*: float              ## Total CPU utilisation (user + system + nice)

  CpuFrequency* = object
    ## CPU frequency information in MHz.
    ## Note: Current frequency may not be available in user mode on macOS.
    nominal*: float             ## Base/nominal frequency
    current*: Option[float]     ## Current operating frequency if available
    max*: Option[float]         ## Maximum turbo frequency if available
    min*: Option[float]         ## Minimum frequency if available

  CpuInfo* = object
    ## Comprehensive CPU information structure combining
    ## static information and dynamic metrics.
    physicalCores*: int         ## Number of physical CPU cores
    logicalCores*: int          ## Logical cores (including SMT/hyperthreading)
    architecture*: string       ## CPU architecture ("arm64" or "x86_64")
    model*: string             ## Machine model identifier (e.g., "MacBookPro18,2")
    brand*: string             ## CPU brand string (e.g., "Apple M1 Pro")
    frequency*: CpuFrequency    ## Frequency information
    usage*: CpuUsage           ## Current CPU utilisation

  LoadAverage* = object
    ## System load average information representing
    ## the number of processes in the run queue.
    oneMinute*: float          ## Average over past 1 minute
    fiveMinute*: float         ## Average over past 5 minutes
    fifteenMinute*: float      ## Average over past 15 minutes
    timestamp*: Time           ## When this measurement was taken

  LoadHistory* = ref object
    ## Thread-safe container for tracking historical load averages
    samples*: Deque[LoadAverage]    ## Historical load measurements
    maxSamples*: int               ## Maximum samples to retain
    lock*: Lock                    ## Mutex for thread-safe access
