# MiniGC: A Minimal Language for Exploring Garbage Collection

## Motivation

Every high-level language you have used — Haskell, Python, Java, JavaScript, Go — relies on a garbage collector that quietly reclaims memory you no longer reference. The collector is one of the parts of a runtime most programmers know least about, even though it has dramatic effects on performance, latency, and even program correctness (think GC pauses in real-time systems). This project is a tiny language whose only job is to produce *interesting* allocation patterns — references between objects, cycles, short-lived garbage — and a tiny runtime that you control end-to-end, so that you can implement and observe a garbage collector instead of relying on the host's. Once the basic mark-and-sweep is in, the door is open to comparing it with a copying collector, a generational one, or anything else you want to try.

## Project Overview
MiniGC is a minimal programming language designed to demonstrate different garbage collection strategies. The language includes only essential features needed to create interesting memory allocation patterns while providing a framework to implement and compare various garbage collection techniques.

> **Scope note.** This is one of the heavier projects in the folder: three nontrivial subsystems (parser, interpreter with a *manually managed* heap, garbage collector) sit on top of a small language. In particular, you cannot lean on Haskell's GC for the objects under test — you must simulate the heap yourself (an `IntMap Object` plus an explicit "next address" counter is the usual move) and thread that heap through the interpreter (`StateT` is fine, `IORef` is fine). Plan the language surface to be as small as you can get away with.

## Key Goals
1. **Parser Implementation**: Convert MiniGC programs into an AST.
2. **Interpreter & Memory Manager**: Execute programs against a simulated heap and a basic garbage collector.
3. **Test Suite**: Cover the parser, the interpreter, and the collector on a handful of allocation patterns.
4. **Alternative Collector (stretch)**: Implement a second collection strategy of your choice (for instance a copying / stop-and-copy collector that compacts live objects) and compare it with your baseline.

## Suggested Core Data Types

A starting point — adapt to your design. The key requirement is that the language can produce *interesting* allocation patterns: live objects, garbage, and references between objects.

```haskell
data Program = Program [FuncDef] Expr

data FuncDef = FuncDef String [String] Expr

data Expr
  = Var    String
  | IntLit Int
  | BoolLit Bool
  | BinOp  Op Expr Expr
  | If     Expr Expr Expr
  | Let    String Expr Expr
  | Call   String [Expr]
  | New    [(String, Expr)]       -- allocate an object with these fields
  | Get    Expr String            -- read a field
  | Set    Expr String Expr       -- write a field (returns the new value)
  | Seq    Expr Expr
  | Null
  | ...

data Op = Add | Sub | Eq | ...    -- extend as needed
```

Arrays, primitive vs reference fields, or a richer type system are reasonable extensions if your project needs them.

## Example Program: Cycles and Garbage

```
-- Create a circular reference structure that becomes unreachable
def createCycle() = {
  let a = new { data = 42, ref = null };
  let b = new { data = 84, ref = null };

  a.ref := b;
  b.ref := a;

  null
}

-- Helper to create a linked list node
def createNode(value, next) =
  new { value = value, next = next }

-- Main: build a reachable list and some unreachable garbage
def main() = {
  let list = createNode(1, createNode(2, createNode(3, null)));
  createCycle();    -- unreachable cycle, should be collected
  list
}
```

This example demonstrates:
1. A linked list of reachable objects.
2. A circular reference that the collector must reclaim.
3. Allocation patterns mixing live data and garbage.

## Implementation Components

### 1. Parser
- Parse function definitions, allocation, field access/assignment, and the usual control-flow forms.
- Report syntax errors with useful location information.
- Support comments.

### 2. Interpreter & Memory Manager
- Run the program against a simulated heap that you control (do not rely on the host's GC for the objects under test).
- Track which heap addresses are reachable from the current root set (locals, function arguments).
- Implement at least one garbage-collection strategy (your choice — a basic mark-and-sweep is one reasonable option).
- Expose a way to inspect the heap (size, live/free counts, contents) so that tests and demos can observe collection behaviour.

### 3. Test Suite
- **Unit tests**: parser correctness; allocation and field access; that an allocation followed by a collection in which the object is unreachable does in fact reclaim it.
- **End-to-end tests**: small programs exercising linked structures, cycles, and short-lived garbage.
- **Property-based tests**: invariants of the heap — e.g. after a collection, every reachable address is still allocated; total allocated count never exceeds what the program requested.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
