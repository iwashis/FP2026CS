# CellularAutomata: A Simulator for 2D Cellular Automata

## Motivation

Cellular automata — the most famous of which is Conway's Game of Life — are deceptively simple systems: a grid of cells, each with a state, evolving in discrete steps according to a rule that looks only at each cell's immediate neighbours. Out of that simplicity emerge gliders, oscillators, self-replicating patterns, and even Turing-complete computation. They are studied in physics, in biology (tissue growth, predator-prey dynamics), and in computer science (parallel computing, pseudo-random generation), and they remain one of the cleanest illustrations of "complex behaviour from simple rules". This project is a small simulator for 2D cellular automata: the user describes an initial grid and a transition rule, and the engine evolves it step by step.

## Project Overview
This project implements a small framework for simulating 2D cellular automata. The user provides an initial grid and a per-cell rule; the simulator advances the grid one step at a time and a renderer displays each generation. The framework should be general enough that Conway's Life is just one rule among several.

## Key Goals
1. **Grid & Rules**: Represent a finite 2D grid of cells and apply a user-supplied transition rule to compute the next generation.
2. **Simulator & Renderer**: Step the grid forward in time and render each generation in a readable form (ASCII to the terminal is enough; an animated GIF or PNG sequence is a nice extension).
3. **Test Suite**: Cover the rule application, the simulator loop, and a handful of well-known Life patterns whose behaviour is documented.
4. **Multi-Rule Library (stretch)**: Implement a small library of named rules beyond Life — Highlife, Day-and-Night, Brian's Brain, a totalistic rule of your design — and let the user pick one by name.

## Suggested Core Data Types

A starting point — adapt to your design. The grid does not have to be a list-of-lists; an `Array (Int, Int) Cell` or a `Map (Int, Int) Cell` (sparse) might serve you better depending on the patterns you want to run.

```haskell
data Cell = Alive | Dead | ...

data Grid = Grid
  { width  :: Int
  , height :: Int
  , cells  :: ...        -- indexed however you like
  }

-- A rule looks at one cell and its neighbours and returns the new cell.
-- The exact shape of the neighbour list is part of your design.
type Rule = Cell -> [Cell] -> Cell

data NamedRule = NamedRule
  { ruleName :: String
  , ruleStep :: Rule
  }
```

Boundary conditions (toroidal wrap-around vs. dead-edge) are a design choice — pick one and document it.

## Example

A glider on a 10×10 toroidal grid, three generations:

```
generation 0      generation 1      generation 2
. # . . . . . . . .   . . . . . . . . . .   . # . . . . . . . .
. . # . . . . . . .   # . # . . . . . . .   . . # # . . . . . .
# # # . . . . . . .   . # # . . . . . . .   . # # . . . . . . .
. . . . . . . . . .   . # . . . . . . . .   . . . . . . . . . .
```

Driving the simulator from `main`:

```
runRule "Conway" (loadGrid "patterns/glider.txt") 30
```

## Implementation Components

### 1. Grid & Rules
- Provide a way to construct a grid (from a literal, from a text file, randomly).
- Implement neighbour lookup with the boundary policy you chose.
- Apply a `Rule` to every cell to produce the next generation.

### 2. Simulator & Renderer
- Step the grid forward `n` generations, returning the sequence (or feeding it directly to the renderer).
- Render each generation in a readable form — at minimum, ASCII to stdout with a short pause between frames.
- Provide Conway's Life as a built-in rule so the example above runs out of the box.

### 3. Test Suite
- **Unit tests**: rule application on hand-built tiny grids; a "blinker" oscillates with period 2; a "block" is a fixed point under Conway's rule.
- **End-to-end tests**: load a glider, step `n` generations, check the resulting grid matches the documented position.
- **Property-based tests**: invariants — total cell count is bounded by `width * height`; on an empty grid the next generation is also empty (under any rule that maps `Dead` with all-dead neighbours to `Dead`).

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
