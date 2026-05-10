# GameAiLang: Behavior Trees for Game AI

## Motivation

Behavior trees are the dominant way of structuring NPC AI in modern games — Unreal Engine, Unity, the ones behind a long list of AAA titles — and they have spread into robotics as well. The reason for their popularity is that they are easy to author (artists can build them in editors), modular (sub-trees compose without surprises), and predictable (no neural-network surprises, which matters in games where the AI must be tunable by designers). The semantics behind them is surprisingly clean: every node returns one of three statuses, and a couple of composite-node rules suffice to express most NPC logic you can think of. This project is a small DSL for describing such trees plus an engine that ticks them against a (simulated) game state — a hands-on look at a very practical pattern.

## Project Overview
GameAiLang is a small domain-specific language for describing *behavior trees*, a common way of structuring non-player-character (NPC) decision logic in games. A behavior tree is a tree of composite nodes (sequences, selectors) and leaf nodes (actions, conditions) that the engine "ticks" each frame to decide what the NPC should do.

## Key Goals
1. **Parser Implementation**: Convert behavior-tree definitions into a structured AST.
2. **AI Engine**: Tick a tree against a (simulated) game state, dispatching actions and condition checks to a small library of named primitives.
3. **Test Suite**: Cover the parser, individual node kinds, and a handful of end-to-end behaviors against scripted world states.
4. **Tracing / Debugger (stretch)**: For each tick, produce a trace showing which branch was taken and what the leaf nodes returned — enough information to reconstruct why the NPC did what it did.

## Suggested Core Data Types

A starting point — adapt to your design. Each tick of a node returns one of three statuses: success, failure, or running.

```haskell
data Tree
  = Sequence  [Tree]      -- run children in order until one fails
  | Selector  [Tree]      -- run children in order until one succeeds
  | Action    String      -- named primitive to invoke
  | Condition String      -- named predicate to query
  | ...                   -- decorators (Inverter, Repeater, ...) are common additions

data Status = Success | Failure | Running | ...
```

The set of named actions and conditions lives in a separate library that the engine consults — the AST should not enumerate them.

## Example Behavior Tree
```
behavior Guard {
  selector {
    sequence {
      condition SeeEnemy;
      action    Attack;
    }
    sequence {
      condition HearNoise;
      action    Investigate;
    }
    action Patrol;
  }
}
```

## Implementation Components

### 1. Parser
- Parse `sequence` / `selector` blocks, `action` and `condition` leaves.
- Report syntax errors with useful location information.
- Support comments.

### 2. Engine
- Walk the tree and tick each node with the current world state.
- Honour the standard semantics: a sequence fails on the first failing child and succeeds when all succeed; a selector succeeds on the first succeeding child and fails when all fail.
- Dispatch `Action` and `Condition` leaves to a registry of host functions; report a useful error if a name is unknown.
- Support a `Running` result so that long-lived actions can persist across ticks.

### 3. Test Suite
- **Unit tests**: parser correctness; sequence/selector semantics on hand-built trees with mocked leaves; that an unknown action name produces a clear error.
- **End-to-end tests**: a `Guard` tree (or similar) ticked against a small scripted sequence of world states, checking the resulting action stream.
- **Property-based tests**: for random trees built from `Sequence`/`Selector`/leaf, the result of a tick depends only on the leaf statuses (not on irrelevant subtree structure).

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `Homework/` folder.
