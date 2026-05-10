# GeneticAlgorithms: A Tiny Evolutionary Optimiser

## Motivation

Genetic algorithms — and the broader family of evolutionary methods — are an elegant idea borrowed from biology and turned into an optimisation tool: maintain a *population* of candidate solutions, score each one by a fitness function, and produce the next generation by selecting the best, recombining their pieces, and occasionally mutating. They are used in scheduling, antenna design, neural-architecture search, game balance, and a long list of "I have no nice gradient" problems. The internal structure is also a near-textbook fit for functional programming: a generation is a list, the genetic operators are pure functions on lists, and the whole thing is `iterate (step rng) initialPop`. This project is a small framework that makes that pattern concrete and applies it to two or three example problems.

## Project Overview
This project implements a small framework for evolutionary optimisation. The user defines a representation for individuals plus a fitness function; the framework runs a configurable selection / crossover / mutation loop and reports the best individual found. It should be possible to apply the same engine to two or three different problems with no changes to the engine itself.

## Key Goals
1. **Representation & Genetic Operators**: A type for individuals, a fitness function interface, and the basic operators (selection, crossover, mutation) parameterised over the representation.
2. **Evolution Loop**: Run a population through generations until a stopping criterion (max generations or fitness threshold), reporting per-generation statistics.
3. **Test Suite**: Cover the operators in isolation and the engine on at least two example problems with known-good answers.
4. **Extensions (stretch)**: Add at least one of — elitism, tournament vs. roulette selection, an island model with periodic migration, adaptive mutation rates — and demonstrate its effect on convergence.

## Suggested Core Data Types

A starting point — adapt to your design. The interesting design choice is whether to fix `Individual` or to keep it parametric so the same engine handles bit strings, real vectors, and permutations.

```haskell
-- A generic individual together with its score
data Scored a = Scored
  { individual :: a
  , fitness    :: Double
  }

-- All the knobs of a run, gathered in one place
data Config a = Config
  { popSize       :: Int
  , maxGen        :: Int
  , mutationRate  :: Double
  , crossover     :: a -> a -> Rand a
  , mutate        :: a -> Rand a
  , randomIndiv   :: Rand a
  , fitnessFn     :: a -> Double
  | ...
  }

type Population a = [Scored a]
type Rand a       = ...   -- e.g. State StdGen a, or your monad of choice
```

You will need a source of randomness — `System.Random` plus `MonadRandom`, or hand-rolled `State StdGen`, are both fine.

## Example

Two example problems exercising the same engine:

```
-- Problem 1: maximise sum of bits in a 32-bit string  (a sanity check)
runGA bitStringConfig

-- Problem 2: solve a small Travelling Salesperson instance
--   individual = a permutation of cities; fitness = -tour length
runGA tspConfig

generation   best     avg
   0       12.0    7.4
  10       19.0   14.7
  20       27.0   22.1
  ...
  best individual after 200 generations: [...]
```

## Implementation Components

### 1. Representation & Genetic Operators
- Define an interface (a record of functions, a type class — your call) capturing what the engine needs from the user: how to make a random individual, how to crossover two of them, how to mutate one, how to score one.
- Provide reusable building blocks for at least two representations (bit strings + something else, e.g. permutations or real vectors).
- Provide both fitness-proportional ("roulette") and tournament selection so the user can swap them.

### 2. Evolution Loop
- Initialise a population of `popSize` random individuals.
- For each generation: score every individual, pick parents, produce children via crossover + mutation, form the next generation.
- Stop on either `maxGen` or a user-supplied fitness threshold.
- Report, per generation, at least the best fitness, the average fitness, and the best individual — so the user can see whether a run is converging.

### 3. Test Suite
- **Unit tests**: each genetic operator preserves the structural invariants of its representation (a permutation crossover returns a permutation; bit-string mutation flips at most a bounded number of bits).
- **End-to-end tests**: the bit-counting problem reaches the maximum within a generous generation budget; a small TSP instance reaches a known-good tour length.
- **Property-based tests**: invariants — every individual ever produced satisfies the representation's invariants; the best fitness in the population is monotonically non-decreasing under elitist selection.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
