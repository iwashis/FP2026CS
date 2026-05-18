# Monad Transformers

## Combining Monads — The Motivation

So far we have seen monads one at a time: `Maybe` for failure, `[]` for non-determinism, `State s` for mutable state, `IO` for the real world. Real programs need several of these effects *at once*:

- a parser that may **fail** (`Maybe`) **and** consumes input (`State String`);
- a game loop that has a **world state** (`State World`) **and** performs **I/O** (`IO`);
- a search that is **non-deterministic** (`[]`) **and** tracks a **cost** (`State Int`).

The natural first guess is: "just compose them". Given monads `m` and `n`, is `m . n` — the type `m (n a)` — also a monad?

```haskell
newtype Compose m n a = Compose (m (n a))
```

**No.** The composition of two arbitrary monads is generally *not* a monad — there is no uniform way to write `(>>=)` for `Compose m n`.

## Which Compositions Do Work?

A few specific compositions do work cleanly. If `m` is any monad, each of the following is again a monad:

1. `m . Maybe`            — "computation in `m` that can also fail"
2. `m . Either e`         — "computation in `m` that can fail with an error"
3. `s -> m (a, s)`        — "computation in `m` that also threads a state `s`"
4. `Monoid w => m (a, w)` — "computation in `m` that also accumulates a log `w`"

Each of these is the "outer monad `m` plus one extra effect". Haskell packages them as **monad transformers**: `MaybeT`, `ExceptT`, `StateT`, `WriterT`, … The key idea is:

```haskell
m   ~>   t m          -- transformer t wraps monad m and adds an effect
```

`t m` is a *new* monad that has everything `m` can do **plus** one extra capability.

## What a Monad Transformer Is, Formally

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

To avoid clashing with the standard library, in our own code we use primed names:

```haskell
class MonadTrans' t where
  lift' :: Monad m => m a -> t m a
```

## `MaybeT` — Failure on Top of Another Monad

Recall the isomorphism we used to define `State`:

```haskell
-- State s a  ≅  s -> (a, s)
```

We now do the analogous thing for "`Maybe` on top of `m`":

```haskell
newtype MaybeT m a = MaybeT { runMaybeT :: m (Maybe a) }
```

A `MaybeT m a` is a computation in `m` whose result is *either* a value (`Just a`) *or* a failure (`Nothing`).

### The Monad Instance

```haskell
instance Functor m => Functor (MaybeT m) where
  fmap f (MaybeT mma) = MaybeT (fmap (fmap f) mma)

instance Monad m => Applicative (MaybeT m) where
  pure x  = MaybeT (return (Just x))
  mf <*> mx = do { f <- mf; x <- mx; return (f x) }

instance Monad m => Monad (MaybeT m) where
  return = pure
  MaybeT mx >>= f = MaybeT $ do
    maybeVal <- mx                 -- run the inner m-action
    case maybeVal of
      Nothing -> return Nothing    -- short-circuit on failure
      Just x  -> runMaybeT (f x)   -- otherwise continue
```

Two effects are threaded together: the inner monad `m` runs as usual, and *on top of it* `Maybe` short-circuits on `Nothing`.

### The `MonadTrans` Instance

```haskell
instance MonadTrans MaybeT where
  lift mAction = MaybeT (fmap Just mAction)
```

`lift` takes an `m a` and says "it never fails" by wrapping the result in `Just`.

## `MaybeT IO` in Practice

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

## `StateT` — State on Top of Another Monad

Same recipe, different effect. Recall `State s a ≅ s -> (a, s)`. Put `m` around the result:

```haskell
newtype StateT s m a = StateT { runStateT :: s -> m (a, s) }
```

A `StateT s m a` is "a stateful computation whose step lives in `m`".

### Exercise: Functor, Monad, and MonadTrans instances

The `Functor` instance threads the state through and applies `f` to the result:

```haskell
instance Functor m => Functor (StateT s m) where
  fmap f (StateT g) = StateT $ \s -> fmap (\(a, s') -> (f a, s')) (g s)
```

`Applicative`:

```haskell
instance Monad m => Applicative (StateT s m) where
  pure x = StateT $ \s -> return (x, s)
  mf <*> mx = do { f <- mf; x <- mx; return (f x) }
```

And the `Monad` instance — run `g` on `s`, pull `(a, s')` out with the inner monad's `>>=`, then run `f a` on `s'`:

```haskell
instance Monad m => Monad (StateT s m) where
  return = pure
  StateT g >>= f = StateT $ \s -> do
    (a, s') <- g s
    runStateT (f a) s'
```

`MonadTrans` — pair the inner result with the unchanged state:

```haskell
instance MonadTrans (StateT s) where
  lift ma = StateT $ \s -> fmap (\a -> (a, s)) ma
```

### State Operations for `StateT`

The familiar `get`, `put`, `modify` carry over, with one extra `Monad m` constraint:

```haskell
get :: Monad m => StateT s m s
get = StateT (\s -> return (s, s))

put :: Monad m => s -> StateT s m ()
put s = StateT (\_ -> return ((), s))

modify :: Monad m => (s -> s) -> StateT s m ()
modify f = StateT (\s -> return ((), f s))
```

## Stacking Effects — A Worked Example

Two counters at once: an `Int` counter via `StateT Int` (innermost) and a `Double` counter on top via `StateT Double`. The bottom of the stack is `Identity`, which is the trivial monad that simply wraps a value — it makes the bottom layer "pure state".

```haskell
type Cost      = StateT Int  Identity      -- cheap counter, innermost
type ExtraCost = StateT Double Cost        -- expensive counter, outer

-- Pay 0.5 units of Double cost and 1 unit of Int cost.
step :: ExtraCost ()
step = do
  modify (+ 0.5)            -- acts on the OUTER state (Double)
  lift (modify (+ 1))       -- acts on the INNER state (Int) — note the lift!

-- Run three steps:
example :: ExtraCost ()
example = step >> step >> step
```

```
> runIdentity (runStateT (runStateT example 0.0) 0)
(((), 1.5), 3)
--      ^^^   ^
--      |     └── final Int counter
--      └──────── final Double counter
```

The "order of the stack" is the order you unwrap: `runStateT` peels off the outer `Double`, then another `runStateT` peels off the inner `Int`, then `runIdentity` peels off the trivial wrapper at the bottom. Each `lift` you write descends one layer of the stack — `modify` acts on the *outermost* state; `lift (modify ...)` acts on the next one down.

This is the core skill for monad-transformer programming: pick the stack of effects your program needs, and use `lift` to talk to the inner layers.
