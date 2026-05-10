# MiniComm: A Minimal Concurrent Language

## Motivation

Languages built around message passing rather than shared memory — Erlang, Elixir, Go, the actor systems on the JVM — descend from theoretical models known as *process calculi*: CSP, CCS, the π-calculus. These calculi are remarkably small: a handful of operators (send, receive, parallel composition, choice) is enough to describe non-trivial concurrent systems and reason about them mathematically. The key payoff is that you can compose concurrent programs the way you compose functions, without the tangle of locks and shared state. This project implements a tiny calculus end-to-end, giving a concrete way to feel why message-passing concurrency is both expressive and easier to reason about than threads-and-locks.

## Project Overview
MiniComm is a small process-calculus-flavoured language for expressing concurrent programs that communicate over channels. The intent is to keep the language deliberately tiny so that the focus stays on synchronisation and message passing rather than on language features.

## Key Goals
1. **Parser Implementation**: Convert MiniComm programs into an AST.
2. **Interpreter & Channel Manager**: Execute concurrent processes with rendezvous-style channel synchronisation.
3. **Test Suite**: Cover the parser, the channel primitives, and a handful of small concurrent programs.
4. **Guarded Choice (stretch)**: Support a non-deterministic select/alt over a list of channel actions, in the style of Dijkstra's guarded commands.

## Suggested Core Data Types

A starting point — adapt to your design. Note that each communication or computation step needs to *continue* into another process, so each such constructor carries a continuation.

```haskell
data Program = Program [ProcessDef] Process

data ProcessDef = ProcessDef String [String] Process

data Expr
  = Var    String
  | IntLit Int
  | BinOp  Op Expr Expr
  | ...

data Op = Add | Sub | Mul | ...

data Process
  = Send    String Expr     Process    -- send on channel, then continue
  | Receive String String   Process    -- receive into variable, then continue
  | New     String          Process    -- create channel, then continue
  | Par     Process Process            -- run two processes in parallel
  | Let     String Expr     Process
  | If      Expr   Process  Process
  | Call    String [Expr]
  | Print   Expr            Process
  | Zero                                -- the inactive process
  | ...
```

## Example Program
```
// Producer/consumer over a channel
def Producer(out, count, value) =
  if count < 10 then
    print(value).
    out!value.
    Producer(out, count + 1, value + 1)
  else
    print("done").
    0

def Consumer(c) =
  c?value.
  print(value).
  Consumer(c)

new ch in
  ( Producer(ch, 0, 1) | Consumer(ch) )
```

The `.` separates a step from its continuation; `|` is parallel composition; `0` is the inactive process. Pick syntax you find readable.

## Implementation Components

### 1. Parser
- Parse process definitions, expressions, channel operations, and parallel composition.
- Report syntax errors with useful location information.
- Support comments.

### 2. Interpreter & Channel Manager
- Execute processes concurrently. Two implementation routes are both acceptable: Haskell threads (`forkIO`/`async`) plus `MVar`/`STM` channels, or an explicit single-threaded scheduler that maintains a queue of runnable processes and steps one at a time. The explicit scheduler is more code but makes the next bullet far easier — pick the route you prefer, but commit to one.
- Implement send/receive as a synchronous rendezvous (or document and test whatever semantics you choose).
- Resolve `Call` against the program's process definitions.
- **Detect deadlock.** "Deadlock" here has a precise meaning: every live process is blocked on a send or receive, no two of them are paired on the same channel, and no process can take a step. When the runtime reaches such a state, it must report it explicitly — never just hang. The explicit-scheduler route makes this a one-line check ("the runnable queue is empty but there are blocked processes"); the threaded route needs more care (e.g. a watchdog or GHC's deadlock detection on `MVar`).
- Provide some way to inspect what happened during a run (a log of communications is enough for testing).

### 3. Test Suite
- **Unit tests**: parser correctness; expression evaluation; that a single send/receive on the same channel actually delivers the value.
- **End-to-end tests**: producer/consumer; a small ring of processes; a program that deadlocks (e.g. two processes each waiting on a channel only the other will write to) — the system must report deadlock, *not* hang.
- **Property-based tests**: invariants of the channel manager — e.g. every value received was previously sent; the multiset of received values is a sub-multiset of the multiset of sent values.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
