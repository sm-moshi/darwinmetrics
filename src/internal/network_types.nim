## Types for network metrics collection on Darwin systems.
##
## This module provides type definitions for network interfaces,
## traffic statistics, and overall network metrics.
##
## Types
## -----
## * NetworkInterfaceType - Enumeration of network interface types
## * NetworkInterfaceInfo - Information about a network interface
## * NetworkStats - Network traffic statistics
## * NetworkInfo - Combined interface info and stats
## * NetworkMetrics - Complete network metrics container

type
  NetworkInterfaceType* = enum
    ## Network interface types
    nitUnknown,    ## Unknown interface type
    nitEthernet,   ## Wired Ethernet
    nitWifi,       ## Wi-Fi
    nitVirtual,    ## Virtual interface
    nitLoopback    ## Loopback interface

  NetworkInterfaceInfo* = object
    ## Information about a network interface
    name*: string                 ## Interface name
    displayName*: string          ## Human-readable name
    macAddress*: string           ## MAC address
    ipv4Address*: string          ## IPv4 address
    ipv6Address*: string          ## IPv6 address
    interfaceType*: NetworkInterfaceType  ## Interface type
    isUp*: bool                   ## Whether the interface is up

  NetworkStats* = object
    ## Network traffic statistics
    bytesReceived*: int64         ## Total bytes received
    bytesSent*: int64             ## Total bytes sent
    packetsReceived*: int64       ## Total packets received
    packetsSent*: int64           ## Total packets sent

  NetworkInfo* = object
    ## Information about a network interface with statistics
    networkInterface*: NetworkInterfaceInfo  ## Interface information
    stats*: NetworkStats                     ## Traffic statistics

  NetworkMetrics* = object
    ## Complete network metrics
    interfaces*: seq[NetworkInfo]     ## Information about all network interfaces
    timestamp*: int64                 ## Timestamp when metrics were collected (nanoseconds)
