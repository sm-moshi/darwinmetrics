## Types for process metrics collection on Darwin systems.
##
## This module provides type definitions for process information,
## resource usage statistics, and overall process metrics.
##
## Types
## -----
## * ProcessStatus - Enumeration of process states
## * ProcessInfo - Basic process information
## * ProcessResourceUsage - Process resource usage statistics
## * ProcessMetrics - Complete process metrics container

type
  ProcessStatus* = enum
    ## Process status
    psRunning,    ## Process is running
    psSleeping,   ## Process is sleeping
    psStopped,    ## Process is stopped
    psZombie      ## Process is zombie (defunct)

  ProcessInfo* = object
    ## Information about a process
    pid*: int                   ## Process ID
    ppid*: int                  ## Parent process ID
    name*: string               ## Process name
    executable*: string         ## Full path to executable
    status*: ProcessStatus      ## Current process status
    startTime*: int64           ## Process start time (Unix timestamp)

  ProcessResourceUsage* = object
    ## Process resource usage statistics
    cpuUser*: float             ## CPU time spent in user mode (seconds)
    cpuSystem*: float           ## CPU time spent in system mode (seconds)
    cpuTotal*: float            ## Total CPU time (seconds)
    cpuPercent*: float          ## CPU usage percentage
    memoryRSS*: int64           ## Resident set size in bytes
    memoryVirtual*: int64       ## Virtual memory size in bytes
    memoryShared*: int64        ## Shared memory size in bytes
    ioRead*: int64              ## Bytes read from disk
    ioWrite*: int64             ## Bytes written to disk

  ProcessMetrics* = object
    ## Complete process metrics
    info*: ProcessInfo               ## Basic process information
    resources*: ProcessResourceUsage ## Resource usage information
    threads*: int                    ## Number of threads
    openFiles*: int                  ## Number of open file descriptors
    timestamp*: int64                ## Timestamp when metrics were collected (nanoseconds)
