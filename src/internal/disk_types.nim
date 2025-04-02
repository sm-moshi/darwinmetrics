## Types for disk metrics collection on Darwin systems.
##
## This module provides type definitions for disk I/O statistics,
## volume information, and overall disk metrics.
##
## Types
## -----
## * DiskIOStats - Statistics for disk read/write operations
## * DiskInfo - Information about a disk volume
## * DiskMetrics - Complete disk metrics container

type
  DiskIOStats* = object
    ## Disk I/O statistics
    readOperations*: int64       ## Number of read operations
    writeOperations*: int64      ## Number of write operations
    readBytes*: int64            ## Bytes read from disk
    writeBytes*: int64           ## Bytes written to disk
    readTime*: int64            ## Time spent reading (milliseconds)
    writeTime*: int64           ## Time spent writing (milliseconds)

  DiskInfo* = object
    ## Information about a disk or volume
    name*: string                ## Device name
    mountPoint*: string          ## Mount point
    fileSystem*: string          ## File system type
    total*: int64                ## Total size in bytes
    used*: int64                ## Used space in bytes
    free*: int64                ## Free space in bytes
    isRemovable*: bool           ## Whether the disk is removable
    isLocal*: bool               ## Whether the disk is local
    timestamp*: int64            ## Timestamp when metrics were collected (nanoseconds)
    totalSpace*: int64           ## Total disk space in bytes
    freeSpace*: int64           ## Free disk space in bytes
    readBytes*: int64           ## Total bytes read since boot
    writeBytes*: int64          ## Total bytes written since boot
    readOps*: int64            ## Number of read operations
    writeOps*: int64           ## Number of write operations

  DiskMetrics* = object
    ## Complete disk metrics
    volumes*: seq[DiskInfo]      ## Information about all disk volumes
    ioStats*: DiskIOStats        ## Disk I/O statistics
    timestamp*: int64            ## Timestamp when metrics were collected (nanoseconds)
