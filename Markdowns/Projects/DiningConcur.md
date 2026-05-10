# Concurrent Programming Language

## Motivation

The dining philosophers is the classic illustration of resource contention — a handful of processes need overlapping shared resources, and the obvious "grab one, then the next" strategy leads straight to deadlock. The same situation shows up in every real concurrent system: operating-system kernels, database engines, distributed locks, even game servers. This project is a tiny concurrent language whose primitives — spawn a process, atomically acquire a *set* of resources, release them — are precisely those needed to write the dining philosophers and other coordination puzzles. The harder, more interesting half is detecting (or preventing) deadlocks when they happen — the same problem that has spawned an entire field of research on deadlock-free locking disciplines.

## Project Overview
This project implements a small domain-specific language for expressing concurrent programs that share resources. The language has primitives for spawning processes, atomically acquiring sets of resources, and releasing them — enough to encode classic synchronisation problems such as the dining philosophers.

## Key Goals
1. **Parser Implementation**: Convert textual programs into an AST.
2. **Interpreter & Resource Manager**: Execute the program with real concurrency, mediating access to shared resources.
3. **Test Suite**: Cover the parser, the resource-manager primitives, and a handful of small concurrent programs.
4. **Deadlock Detection (stretch)**: Detect (or prevent) cyclic resource-acquisition patterns at runtime and report them.

## Suggested Core Data Types

A starting point — adapt to your design. In particular, the operation that "uses" a held resource is intentionally generic: dining philosophers is one example, but the language should accommodate other patterns too.

```haskell
data Program = Program [Statement]

-- Expressions used inside statements
data Expr
  = Var    String
  | IntLit Int
  | StrLit String
  | BinOp  Op Expr Expr
  | Rand   Expr Expr   -- random integer in [lo, hi]
  | ...

data Op = Add | Sub | Mod | Concat | ...   -- extend as needed

-- Statements
data Statement
  = Let     String Expr
  | Print   Expr
  | Sleep   Expr                       -- pause for the given number of time units
  | NewResource String                 -- declare a shared resource
  | Acquire [String]                   -- atomically take a set of resources
  | Release [String]                   -- release the named resources
  | Spawn   Expr [Statement]           -- run the body concurrently under a name
  | Loop    [Statement]
  | ForEach String Expr Expr [Statement]   -- bind a name to each value in a range
  | If      Expr [Statement] [Statement]
  | ...
```

## Example Program
```
// Dining philosophers (n = 3)
let n = 3;

foreach i in 0 .. n - 1 {
  newResource ("fork" ++ i);
}

foreach i in 0 .. n - 1 {
  let left  = "fork" ++ i;
  let right = "fork" ++ ((i + 1) mod n);

  spawn ("philosopher" ++ i) {
    loop {
      print ("thinking " ++ i);
      sleep (rand 10 50);

      acquire [left, right];
      print ("eating " ++ i);
      sleep (rand 10 50);
      release [left, right];
    }
  }
}
```

## Implementation Components

### 1. Parser
- Parse the statements and expressions above.
- Report syntax errors with useful location information.
- Support comments.

### 2. Interpreter & Resource Manager
- Run each spawned process in its own Haskell thread (`forkIO`, `async`, or via STM — your choice).
- Implement `acquire` so that the whole set is taken atomically, never leaving a process holding a strict subset.
- Implement `release` symmetrically.
- Provide a logging facility so that interleavings can be inspected after a run.

### 3. Test Suite
- **Unit tests**: parser correctness; expression evaluation; that `acquire`/`release` over a single resource behaves like a mutex.
- **End-to-end tests**: a few small programs (producer/consumer, dining philosophers) that should make progress; and at least one program intentionally written to deadlock, used to test your detection mechanism.
- **Property-based tests**: invariants about the resource manager — e.g. at no point can two processes simultaneously hold the same resource.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
