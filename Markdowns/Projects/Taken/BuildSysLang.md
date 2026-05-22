# BuildSysLang: A Dependency-Aware Build System

## Motivation

Build systems like `make`, `ninja`, and `bazel` are doing one of the most studied ideas in computer science — *incremental computation* — under the hood: figuring out which targets depend on which inputs, recomputing only what has actually changed, and doing as much in parallel as the dependency graph allows. The same idea recurs almost anywhere a system has to react to changing inputs: spreadsheet recomputation, modern UI frameworks, query engines that cache results. This project is a tiny build system: a language for declaring targets and dependencies plus an engine that resolves the graph and runs the right things in the right order. The interesting ideas — topological sort, cycle detection, and "do as little work as possible" — are the same ones that scale up to industrial systems.

## Project Overview
BuildSysLang is a small domain-specific language for describing build targets and the dependencies between them, in the style of `make`. The runtime computes a build order, decides which targets are out of date, and runs the necessary commands.

## Key Goals
1. **Parser Implementation**: Convert build files into a structured AST.
2. **Dependency Graph & Executor**: Build the dependency graph, detect cycles, and run targets in a correct topological order.
3. **Test Suite**: Cover the parser, the ordering logic, and a handful of small build files (including ill-formed ones).
4. **Parallel Execution (stretch)**: Run independent targets concurrently while preserving dependency order.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data BuildFile = BuildFile [Rule]

data Rule = Rule
  { target :: String
  , deps   :: [String]
  , recipe :: [Command]
  }

data Command
  = Shell  String         -- a literal shell command (or a simulated one, in tests)
  | Echo   String
  | Touch  String         -- mark the target as built
  | ...
```

You may also want a notion of "is this target up to date?" — for instance by comparing source mtimes to target mtime, or by hashing the inputs. The exact mechanism is your design choice.

## Example Build File
```
target app : main.o utils.o {
  shell "ld main.o utils.o -o app"
}

target main.o : main.c {
  shell "cc -c main.c"
}

target utils.o : utils.c {
  shell "cc -c utils.c"
}
```

## Implementation Components

### 1. Parser
- Parse rule declarations: target name, dependency list, recipe.
- Report syntax errors with useful location information.
- Support comments.

### 2. Dependency Graph & Executor
- Build a graph from targets to their dependencies.
- Detect cycles and report them clearly instead of looping.
- Compute a topological order and execute the recipe of each out-of-date target in that order.
- Skip targets that are already up to date according to your chosen freshness rule.

### 3. Test Suite
- **Unit tests**: parser correctness; cycle detection; topological-sort output for small graphs.
- **End-to-end tests**: a small build file that runs from a clean state; a re-run that does no work; an edited source that triggers exactly the affected targets.
- **Property-based tests**: for randomly generated DAGs, the executor's order respects every dependency edge; cyclic graphs are always rejected.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
