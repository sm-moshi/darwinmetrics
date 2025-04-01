## CPU types module for Darwin
##
## This module defines the core types used for CPU metrics in Darwin-based systems.
## These types provide a clean abstraction over the low-level Mach kernel structures.

import std/[options, times, deques, locks]

type CpuUsage* = object        ## CPU usage information
  user*: float                ## Percentage of time spent in user mode (0-100)
  system*: float              ## Percentage of time spent in system mode (0-100)
  idle*: float                ## Percentage of time spent idle (0-100)
  nice*: float                ## Percentage of time spent in nice priority (0-100)
  total*: float               ## Total CPU usage percentage (0-100)

type CpuFrequency* = object    ## CPU frequency information
  nominal*: float             ## Nominal (base) frequency in MHz
  current*: Option[float]     ## Current frequency in MHz (if available)
  max*: Option[float]         ## Maximum frequency in MHz (if available)
  min*: Option[float]         ## Minimum frequency in MHz (if available)

type CpuInfo* = object         ## CPU information structure
  physicalCores*: int          ## Number of physical CPU cores
  logicalCores*: int           ## Number of logical CPU cores (including hyperthreading)
  architecture*: string        ## CPU architecture (e.g., "arm64" or "x86_64")
  model*: string              ## Machine model identifier
  brand*: string              ## CPU brand string
  frequency*: CpuFrequency    ## CPU frequency information
  usage*: CpuUsage            ## Current CPU usage information

type LoadAverage* = object ## System load average information
  oneMinute*: float        ## 1-minute load average
  fiveMinute*: float       ## 5-minute load average
  fifteenMinute*: float    ## 15-minute load average
  timestamp*: Time         ## When this measurement was taken

type LoadHistory* = ref object     ## Historical load average tracking
  samples*: Deque[LoadAverage]    ## Load average samples
  maxSamples*: int               ## Maximum number of samples to keep
  lock*: Lock                    ## Lock for thread-safe access
