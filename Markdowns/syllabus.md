# Functional Programming in Haskell — Course Syllabus

## Overview

A hands-on introduction to functional programming through Haskell.
The course builds from first principles (pure functions, recursion, types)
up through advanced abstractions (monads, monad transformers, concurrency),
then continues into advanced type-system features and design patterns.

---

## Schedule

### Section 1 — Basics of Functional Programming

Core ideas of functional programming in Haskell.

- Pure functions and referential transparency
- Pattern matching and recursion (base case / recursive case)
- Lazy evaluation and infinite data structures
- Currying and partial application
- Higher-order functions (`map`, `filter`)
- First examples: `quicksort`, Fibonacci, list summation

---

### Section 2 — Algebraic Data Types

Modelling data with Haskell's type system.

- Enumeration types (`data Color = Red | Blue | Green`)
- Product types and sum types
- Pattern matching on constructors
- Record syntax and field accessors
- Recursive types: custom lists and binary trees
- Type aliases (`type`, `newtype`)
- Deriving and writing typeclass instances: `Show`, `Eq`, `Functor`, `Semigroup`, `Monoid`

---

### Section 3 — Folds and the Foldable Typeclass

Structural recursion as a uniform pattern.

- `foldl` and `foldr`: mechanics and intuition
- Building common functions from folds: `sum`, `reverse`, `count`
- The `Foldable` typeclass and `foldMap`
- Implementing `Foldable` for a binary tree (inorder traversal)
- Custom `Monoid` wrappers (`Any`, `All`, `Sum`)
- `foldMap` applications: `treeContains`, `treeToList`

---

### Section 4 — Applicative Functors and Monads

Lifting computations into contexts.

- Functor laws: identity and composition
- `Applicative`: `pure` and `<*>`, applicative laws
- The `Maybe` applicative: safe chaining of optional values
- List as an applicative: parallel application vs. Cartesian product
- Introduction to monads: `return` and `>>=`
- Kleisli composition `>=>` and the do-notation
- Monad laws; `Maybe` monad: safe `head` and `tail`

---

### Section 5 — The List Monad and the State Monad

Monadic structure for non-determinism and stateful computation.

- The list monad: modelling non-determinism
- `do`-notation over lists; Fibonacci via list comprehension in a monad
- The `State` monad: `newtype State s a = State (s -> (s, a))`
- `Functor`, `Applicative`, and `Monad` instances for `State`
- Running stateful computations: `runState`, `evalState`, `execState`

---

### Section 6 — The Writer Monad

Accumulating output alongside a computation.

- The `Writer` monad: `newtype Writer w a = Writer (w, a)`
- `Functor`, `Applicative`, and `Monad` instances
- `tell` and `listen` primitives
- Structured logging: `LogType`, `LogEntry`, custom `Monoid` for logs
- Case study: a bank register with `deposit`, `withdraw`, `getBalance`, `auditWithdraw`, `transfer`

---

### Section 7 — The State Monad in Depth

Advanced stateful programming patterns.

- `get`, `put`, `modify` primitives
- Counting operations: instrumented `quicksort` with a comparison counter
- `filterM` and monadic filtering
- Case study: an RPG game state (`gainExperience`, `takeDamage`, `collectGold`)
- Case study: maze navigation with backtracking using `State`

---

### Section 8 — The IO Monad and Monad Transformers

Interfacing with the world and combining monadic effects.

- The IO monad: `getLine`, `putStrLn`, `readFile`, `writeFile`
- Error handling in IO: `try` and `IOError`
- Why we need monad transformers
- Common transformers: `StateT`, `ReaderT`, `WriterT`, `ExceptT`, `MaybeT`
- `lift` and the transformer hierarchy
- Case study: `StateT AppState IO` — an interactive stateful application
- Combining three layers: `ExceptT AppError (StateT GameState IO)`

---

### Section 9 — Parser Combinators

Building a small language from scratch with monadic parsers.

- What is a parser? Consuming input, producing results
- `Parser a = StateT String [] a` — non-determinism meets state
- Primitive parsers: `satisfy`, `char`, `string`
- Combinators: `many`, `many1`, `token`, `symbol`, `parens`
- The `Alternative` typeclass and `<|>`
- Parsing integers, identifiers, and expressions
- Building a complete grammar: assignment, arithmetic, print, program
- Error reporting: `parse :: String -> Either String Program`

---

### Section 10 — Concurrency

Writing correct concurrent programs in Haskell.

- Lightweight threads: `forkIO` and `threadDelay`
- `MVar`: a mutable, blocking variable
- Race conditions and deadlocks; the Dining Philosophers problem
- Software Transactional Memory (STM): `TVar`, `atomically`, `retry`
- Why STM prevents deadlocks by construction
- Case study: a concurrent counter
- Case study: atomic bank transfer with `STM`

---

### Section 11 — Testing with HSpec and QuickCheck

Writing a trustworthy test suite for Haskell code.

- Unit testing with HSpec: `describe`, `it`, `shouldBe`, `shouldThrow`, `before`/`after`
- Organising a test suite across multiple modules
- Property-based testing with QuickCheck: the idea of universally quantified properties
- `Arbitrary` instances: deriving and writing custom generators with `Gen`
- `forAll`, `classify`, `cover`, `shrinking`
- Testing typeclass laws: functor, monoid, and monad laws as QuickCheck properties
- Integrating both into the Stack build: `stack test`
- When to use each: example-based vs. property-based thinking

---

### Section 12 — GADTs

Types that know more about themselves.

- Limitation of vanilla ADTs: all constructors share the same return type
- `GADTs` extension: constructors can fix type parameters
- Motivating example: a typed expression tree (`Expr Int`, `Expr Bool`)
- Pattern matching on GADTs: the compiler learns type information per branch
- Phantom types as a lighter-weight alternative
- `DataKinds` and kind-level values: promoting types to kinds
- Practical uses: type-safe heterogeneous lists, well-typed DSLs, tagless interpreters

---

### Section 13 — Type Families

Type-level functions and associated types.

- Why we need computation at the type level
- Type synonyms vs. type families: `type family F a`
- Closed vs. open type families
- Associated type families inside typeclasses
- `FunctionalDependencies` as an alternative
- Examples: `Container` typeclass with associated `Element` type; type-level arithmetic
- `TypeFamilies` + `GADTs` together: indexed types and type-safe state machines
- Brief look at `DataKinds` + `TypeFamilies` for length-indexed vectors
