# SpreadsheetLang: A Functional Spreadsheet Core

## Motivation

Spreadsheets are the most widely-used programming environment in the world: hundreds of millions of people write small programs (formulas) and share them as `.xlsx` files. The thing that makes a spreadsheet a spreadsheet — automatic recomputation when one cell changes, in the right order, without the user thinking about it — is *reactive programming*, the same idea that powers React, Svelte, and modern UI frameworks. This project is the functional core of a spreadsheet: cells, formulas, dependency graph, evaluation order, error propagation. It is small enough to build in a course and large enough to expose the interesting ideas — including the gotchas (cyclic references, dirty-cell propagation) that real spreadsheets and frontends both have to deal with.

## Project Overview
SpreadsheetLang captures the core logic of a spreadsheet: a grid of cells where each cell either holds a value or a formula referring to other cells. The runtime works out the dependencies between cells, evaluates them in a correct order, and propagates updates when a value changes.

## Key Goals
1. **Parser Implementation**: Convert sheet definitions and cell formulas into a structured AST.
2. **Dependency Graph & Evaluator**: Compute the dependency graph between cells, detect cyclic references, and evaluate cells in a correct topological order.
3. **Test Suite**: Cover the parser, the evaluator, and a handful of small sheets (including ones with cycles).
4. **Reactive Recalculation (stretch)**: Make the sheet *reactive* — when a single cell's value or formula changes, recompute exactly the cells that depend (transitively) on it, not the whole sheet.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Sheet = Sheet [Cell]

data Cell = Cell
  { addr    :: Addr             -- e.g. ("A", 1)
  , content :: Content
  }

type Addr = (String, Int)       -- column letters, row number

data Content
  = Lit  Value
  | Form Expr
  | ...

data Expr
  = Ref     Addr
  | LitE    Value
  | BinOp   Op Expr Expr
  | RangeOp RangeOp Addr Addr   -- e.g. SUM(A1:A5)
  | ...

data Value = NumV Double | BoolV Bool | StrV String | ErrV String | ...

data Op      = Add | Sub | Mul | Div | ...
data RangeOp = SumR | AvgR | ...  -- extend as needed
```

## Example Sheet
```
sheet {
  A1 = 10;
  A2 = 20;
  A3 = A1 + A2;
  A4 = SUM(A1:A3);
}
```

## Implementation Components

### 1. Parser
- Parse cell assignments, value literals, references, arithmetic, and at least one range operation.
- Report syntax errors with useful location information.
- Support comments.

### 2. Dependency Graph & Evaluator
- For each formula cell, compute the set of cells it directly references (resolving ranges).
- Detect cycles and produce an `ErrV "cycle"` for every cell on a cycle, rather than looping.
- Evaluate the cells in a topological order; division by zero, references to missing cells, and type errors should yield an `ErrV` value, not crash the whole sheet.

### 3. Test Suite
- **Unit tests**: parser correctness; evaluation of individual operations; cycle detection on a tiny `A1 = A1` sheet.
- **End-to-end tests**: a small sheet whose values you can compute by hand; a sheet with a cycle that must produce error values without hanging.
- **Property-based tests**: invariants — for an acyclic sheet, every cell's value is a function of its inputs only; recomputation after no change yields the same values.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
