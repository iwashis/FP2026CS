# Constraint Satisfaction Programming Language

## Motivation

Constraint solvers sit behind a surprising amount of real software: course timetabling, vehicle routing, factory scheduling, configuring product variants, register allocation in compilers, even Sudoku solvers in your phone. Industrial tools like MiniZinc, Choco, and Google OR-Tools all rest on the same core algorithms — backtracking search and constraint propagation — combined with heuristics for which variable to assign next. This project distils that core into a small DSL and a solver you write yourself: declaratively state variables, domains, and constraints, and let the engine search for a satisfying assignment. The exercise is a clean illustration of how a tiny algorithmic core (search + pruning) can solve a wide family of problems.

## Project Overview
This project implements a small domain-specific language for stating and solving finite-domain constraint satisfaction problems (CSPs). Users declare variables with their domains, state constraints between them, and ask the solver for one or all solutions.

## Key Goals
1. **Parser Implementation**: Convert textual CSP definitions into a structured AST.
2. **Constraint Store & Solver**: Maintain variable domains and search for assignments that satisfy all constraints.
3. **Test Suite**: Cover the parser, individual constraint checks, and a handful of complete problems.
4. **Search Heuristics (stretch)**: Improve the basic backtracking search with a variable-ordering heuristic of your choice (e.g. Minimum Remaining Values) and/or a simple propagation step.

## Suggested Core Data Types

A starting point — feel free to adapt the shapes below to your design.

```haskell
data Program = Program [VarDecl] [Constraint]

-- Variable declarations: name plus its domain
data VarDecl = VarDecl String Domain

data Domain
  = IntRange Int Int        -- inclusive range
  | DiscreteSet [Value]     -- explicit list of allowed values
  | ...

data Value = IntVal Int | StrVal String | BoolVal Bool | ...

-- Constraints reference variables by name
data Constraint
  = Binary BinOp String String           -- e.g. x /= y
  | NAry   NAryOp [String]               -- e.g. allDifferent [x,y,z]
  | ...

data BinOp  = Eq | NEq | Lt | Le | ...
data NAryOp = AllDifferent | ...         -- extend as your project needs
```

You can extend this with arithmetic constraints, an objective function, or richer expressions if your project goes that direction.

## Example CSP Problem
```
// Map colouring (Australia)
var WA, NT, SA, Q, NSW, V, T : { red, green, blue };

constraint WA  /= NT;
constraint WA  /= SA;
constraint NT  /= SA;
constraint NT  /= Q;
constraint SA  /= Q;
constraint SA  /= NSW;
constraint SA  /= V;
constraint Q   /= NSW;
constraint NSW /= V;

solve;
```

## Implementation Components

### 1. Parser
- Parse variable declarations and constraint statements.
- Report syntax errors with useful location information.
- Support comments.

### 2. Constraint Store & Solver
- Maintain the current domain of each variable.
- Implement backtracking search that assigns one variable at a time and undoes assignments on failure.
- Check constraints against partial assignments early enough to prune dead branches.
- Return either a satisfying assignment or a clear "unsatisfiable" report.

### 3. Test Suite
- **Unit tests**: parser correctness; each constraint kind accepts/rejects the right assignments.
- **End-to-end tests**: a handful of classic CSPs (map colouring, N-queens, a small Sudoku) with known solutions.
- **Property-based tests**: generate random small CSPs and check that any solution returned actually satisfies every constraint.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
