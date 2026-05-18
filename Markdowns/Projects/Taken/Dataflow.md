# Dataflow Programming Language

## Motivation

Modern data-processing systems — TensorFlow's computation graphs, Apache Beam, Spark, audio/video pipelines like GStreamer, ETL frameworks like Airflow — describe their work as a directed graph of operations rather than a straight-line program. Once the work is a graph, the system can analyse it: detect cycles, type-check the connections between stages, schedule independent branches in parallel, swap a slow stage for a faster one without rewriting the rest. This project is a small dataflow language: a textual description of nodes and edges plus an engine that validates and executes the resulting graph. The point is to feel, hands-on, why "the program is a graph" is such a productive idea.

## Project Overview
This project implements a small domain-specific language for describing data-processing pipelines as directed graphs of operations. Users declare nodes (sources, transformations, sinks) and the edges between them; the system validates the resulting graph and executes it.

## Key Goals
1. **Parser Implementation**: Convert textual pipeline definitions into a graph-shaped AST.
2. **Graph Validator & Executor**: Check structural properties (connectivity, acyclicity, dangling references), then execute the pipeline by passing data along edges in a topological order. Each node kind is dispatched to a small library of named primitives (sources produce values, transforms consume and produce, sinks consume).
3. **Test Suite**: Cover the parser, the validator, and a handful of small pipelines.
4. **Parallel Execution (stretch)**: Schedule independent nodes to run concurrently (e.g. one Haskell thread per ready node), respecting the dependencies in the graph.

## Suggested Core Data Types

A starting point — feel free to refine. In particular, you do **not** need a separate constructor per node kind; carrying a kind tag plus parameters keeps the AST small.

```haskell
data Program = Program [Node] [Edge]

-- A node has a unique id, a kind ("source", "filter", ...) and parameters
data Node = Node
  { nodeId     :: String
  , nodeKind   :: String
  , nodeParams :: [(String, Value)]
  }

-- An edge connects one node's output to another node's input
data Edge = Edge { from :: String, to :: String }

data Value
  = StrVal  String
  | NumVal  Double
  | BoolVal Bool
  | ListVal [Value]
  | ...
```

If you want stronger validation, add a small `Type` describing the data flowing along each edge and check compatibility between connected nodes — but the exact type system is your design choice.

## Example Pipeline
```
// Simple image-processing pipeline
source camera {
  width:  1280,
  height: 720,
  format: "rgb24"
}

transform resize from camera {
  width:  640,
  height: 480
}

transform grayscale from resize

sink display from grayscale {
  windowName: "Processed Image"
}
```

## Implementation Components

### 1. Parser
- Parse node declarations (with their parameters) and `from`-style edge declarations.
- Report syntax errors with useful location information.
- Support comments.

### 2. Graph Validator & Executor
- Build the dataflow graph from the parsed declarations.
- Detect cycles and reject them (or, if you intentionally support feedback loops, document the convention).
- Detect dangling references — edges that name nodes that don't exist.
- Optionally: check that the data type produced by a node matches what its downstream nodes expect.
- Execute the pipeline: walk the graph in topological order and dispatch each node kind to a small registry of host functions (sources produce a value from their parameters, transforms map their input to an output, sinks consume their input). Report a useful error for unknown node kinds. The set of available primitives is small and lives outside the AST — adding a new kind is registering a function under a name.

### 3. Test Suite
- **Unit tests**: parser correctness; cycle detection; dangling-edge detection.
- **End-to-end tests**: a few small pipelines that should validate *and run* end-to-end, with the output of each sink compared against a hand-computed value; plus malformed pipelines that should be rejected with a useful message.
- **Property-based tests**: generate random graphs and check structural invariants (e.g. acyclic graphs validate; cyclic ones don't); for randomly generated linear pipelines built from a fixed primitive library, the executor's output equals the composition of the primitive functions in declaration order.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
