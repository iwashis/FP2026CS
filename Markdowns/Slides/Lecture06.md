---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 6


## Lecture code
Lecture06.hs

---

# Combining monads — the motivation

So far we have seen monads one at a time: `Maybe` for failure, `[]` for non-determinism, `State s` for mutable state, `IO` for the real world. Real programs need several of these *at once*:

- a parser that may **fail** (`Maybe`) **and** consumes input (`State String`),
- a game loop that has a **world state** (`State World`) **and** performs **I/O**,
- a search that is **non-deterministic** (`[]`) **and** tracks a **cost** (`State Int`).

The natural first guess is: "just compose them". Given monads `m` and `n`, is `m . n` (the type `m (n a)`) also a monad?

```haskell
-- Can we always do this?
newtype Compose m n a = Compose (m (n a))
```

**No.** Composition of two arbitrary monads is generally **not** a monad — there is no uniform way to write `>>=` for `Compose m n`.

---

# Which compositions *do* work?

A few patterns do compose cleanly. If `m` is any monad, each of the following is again a monad:

1. `m . Maybe`          — "computation in `m` that can also fail"
2. `m . Either e`       — "computation in `m` that can fail with an error"
3. `s -> m (a, s)`      — "computation in `m` that also threads a state `s`"
4. `Monoid w => m (a, w)` — "computation in `m` that also accumulates a log `w`"

Each of these is the "outer monad `m` plus one extra effect". Haskell packages them as **monad transformers**: `MaybeT`, `ExceptT`, `StateT`, `WriterT`, …

## Key idea
```haskell
m   ~>   t m          -- transformer t wraps monad m and adds an effect
```
`t m` is a *new* monad that has everything `m` can do **plus** one extra capability.

---

# What a monad transformer is, formally

A monad transformer in Haskell is three things:

1. **A parameterised type** that takes a monad and returns a monad:
```haskell
t :: (* -> *) -> * -> *
```

2. **An instance of `MonadTrans`**, which lets you promote an action of the inner monad into the transformed monad:
```haskell
class MonadTrans t where
  lift :: Monad m => m a -> t m a
```

3. **A `Monad` instance for `t m`** for every monad `m`.

Think of `lift` as "I already have a computation in the inner monad `m`; wrap it so it can live inside the richer `t m`."

---

# MaybeT — failure on top of another monad

Recall the isomorphism we used to define `State`:
```haskell
-- State s a  ≅  s -> (a, s)
```
We now do the analogous thing for *"`Maybe` on top of `m`"*:
```haskell
newtype MaybeT m a = MaybeT { runMaybeT :: m (Maybe a) }
```
A `MaybeT m a` is a computation in `m` whose result is *either* a value (`Just a`) *or* a failure (`Nothing`).

## The Monad instance — intuition
```haskell
instance Monad m => Monad (MaybeT m) where
  return x = MaybeT (return (Just x))

  MaybeT mx >>= f = MaybeT $ do
    maybeVal <- mx                 -- run the inner m-action
    case maybeVal of
      Nothing -> return Nothing    -- short-circuit on failure
      Just x  -> runMaybeT (f x)   -- otherwise continue
```
Two effects are threaded together: the inner monad `m` runs as usual, and *on top of it* `Maybe` short-circuits on `Nothing`.

## The MonadTrans instance
```haskell
instance MonadTrans MaybeT where
  lift mAction = MaybeT (fmap Just mAction)
```
`lift` takes an `m a` and says "it never fails" by wrapping the result in `Just`.

---

# MaybeT IO in practice

`MaybeT IO` is **"I/O that can also fail"** — exactly the shape of many real programs.
```haskell
type MaybeIO = MaybeT IO

prompt :: String -> MaybeIO String
prompt msg = do
  lift (putStr msg)                       -- IO action, lifted
  line <- lift getLine                    -- IO action, lifted
  if null line then MaybeT (return Nothing)
               else return line

greet :: MaybeIO ()
greet = do
  name <- prompt "Name: "                 -- bails out on empty input
  age  <- prompt "Age: "
  lift (putStrLn ("Hello, " ++ name ++ " (" ++ age ++ ")"))

-- runMaybeT greet :: IO (Maybe ())
```
Without `MaybeT` we would be writing nested `case` on every `IO (Maybe a)` result — exactly the problem `Maybe` was supposed to solve in the first place, now reappearing because of `IO`.

---

# StateT — state on top of another monad

Same recipe, different effect. Recall `State s a ≅ s -> (a, s)`. Put `m` in the result:
```haskell
newtype StateT s m a = StateT { runStateT :: s -> m (a, s) }
```
A `StateT s m a` is "a stateful computation whose step lives in `m`".

## Exercise
Write the `Monad` instance for `StateT s m`:
```haskell
instance Monad m => Monad (StateT s m) where
  return a = StateT $ \s -> ???

  (StateT g) >>= f = StateT $ \s -> ???
```
Hint: run `g` on `s`, pull out `(a, s')` with `>>=` of the **inner** monad, then run `f a` on `s'`.

## Also exercise
Write the `MonadTrans` instance:
```haskell
instance MonadTrans (StateT s) where
  lift ma = StateT $ \s -> ???     -- use fmap to pair the result with s
```

---

# Stacking effects — a worked example

Two counters at once: an `Int` counter (via `State Int`) and a `Double` counter on top (via `StateT Double`).
```haskell
type Cost      = State Int          -- cheap counter, innermost
type ExtraCost = StateT Double Cost  -- expensive counter, outer

-- Pay 1 unit of Int cost, 0.5 unit of Double cost.
step :: ExtraCost ()
step = do
  modify (+ 0.5)          -- acts on the OUTER state  (Double)
  lift (modify (+ 1))     -- acts on the INNER state  (Int)   — note the lift!

-- Run three steps:
example :: ExtraCost ()
example = step >> step >> step

-- runState (runStateT example 0.0) 0
-- (((), 1.5), 3)
--       ^^^   ^
--       |     └── final Int counter
--       └──────── final Double counter
```
The "order of the stack" is the order you unwrap: `runStateT` peels off the outer `Double`, then `runState` peels off the inner `Int`.
