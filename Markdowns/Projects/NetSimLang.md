# NetSimLang: Network Topology Simulator

## Motivation

Network simulators — ns-3, GNS3, OMNeT++ — are how routing protocols, congestion-control algorithms, and topology designs are tested before anyone touches real hardware; they are also how networking is taught. The core abstractions are surprisingly simple: a graph of devices and links, plus a way of moving discrete packets along edges according to some routing rule. This project is a tiny simulator built from those abstractions, focused on the language for describing topologies and the algorithms for routing packets between hosts. It is a clean place to meet shortest-path search, partitioned graphs, and the difference between "the network can deliver this packet" and "the network *should*".

## Project Overview
NetSimLang is a small domain-specific language for describing computer-network topologies (hosts, routers, links) and simulating packet flow over them. Programs declare the devices and the links between them; the runtime simulates packets travelling across the network according to a routing strategy.

## Key Goals
1. **Parser Implementation**: Convert topology definitions into a structured AST.
2. **Simulator**: Model devices, links, and packet routing — each packet has a source, destination, and follows some chosen routing strategy.
3. **Test Suite**: Cover the parser, the routing logic, and a handful of small networks (including pathological ones).
4. **Faults & Visualisation (stretch)**: Add per-link latency and a simple loss model, and/or render the network and packet flow in some readable form.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Network = Network [Device] [Link]

data Device
  = Router String
  | Host   String
  | ...

data Link = Link
  { endA      :: String
  , endB      :: String
  , bandwidth :: Int       -- units per tick
  }

data Packet = Packet
  { src     :: String
  , dst     :: String
  , payload :: String
  }
```

How you model time (discrete ticks vs. an event queue), routing (static table, shortest-path, flooding), and per-link state (queues) is part of the design.

## Example Network
```
network {
  router R1;
  host   H1;
  host   H2;

  link H1 <-> R1 bandwidth 100;
  link H2 <-> R1 bandwidth 100;
}

send H1 -> H2 "hello";
```

## Implementation Components

### 1. Parser
- Parse device declarations, link declarations, and `send` directives.
- Report syntax errors with useful location information.
- Support comments.

### 2. Simulator
- Build the device/link graph from the parsed declarations.
- Choose and document a routing strategy (shortest-path on hop count is a reasonable starting point).
- Step the simulation forward and report, per packet, the path it took (or that it was undeliverable).
- Reject packets to or from unknown devices with a clear error.

### 3. Test Suite
- **Unit tests**: parser correctness; routing tables on hand-built small graphs; behaviour on a network with no path between source and destination.
- **End-to-end tests**: a small star and a small ring topology with known shortest paths; a partitioned network where some sends must fail.
- **Property-based tests**: for connected random graphs, every host can reach every other host; no packet's reported path contains the same link twice.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
