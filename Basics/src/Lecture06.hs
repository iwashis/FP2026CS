module Lecture06 where

import Data.Functor.Identity (Identity, runIdentity)

--
-- ==========================================
--  Lecture 6: Monad Transformers
-- ==========================================
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. Combining monads — the motivation
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- We have seen monads one at a time: Maybe (failure), [] (non-determinism),
-- State s (mutable state), IO (the real world). Real programs mix them:
--
--   * a parser that may fail (Maybe) AND consumes input (State String);
--   * a game loop with a world state (State World) AND I/O (IO);
--   * a search that is non-deterministic ([]) AND tracks a cost (State Int).
--
-- First guess: just compose them. Given monads m and n, is m . n a monad?
--
--   newtype Compose m n a = Compose (m (n a))
--
-- Answer: NO. The composition of two arbitrary monads is generally not a
-- monad — there is no uniform way to write (>>=) for Compose m n.
--
-- A few special compositions DO work, and Haskell packages them as
-- *monad transformers*:
--
--   m . Maybe                  ~~~  MaybeT m   ("m, with failure")
--   m . Either e               ~~~  ExceptT e m
--   s -> m (a, s)              ~~~  StateT s m
--   Monoid w => m (a, w)       ~~~  WriterT w m
--
-- Key idea:        m  ~>  t m     (transformer t adds one extra effect to m).


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. What a monad transformer is
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A monad transformer is three things:
--
--   1. A parameterised type t :: (* -> *) -> * -> *
--   2. A class MonadTrans with `lift :: Monad m => m a -> t m a`
--      to promote inner-monad actions into t m.
--   3. A Monad instance for `t m` for every monad m.
--
-- We define our own copy with primed names so we don't clash with mtl.

class MonadTrans' t where
  lift' :: Monad m => m a -> t m a


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. MaybeT' — failure on top of another monad
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Recall   State s a  ≅  s -> (a, s)
-- Now do the analogous thing for "Maybe on top of m":

newtype MaybeT' m a = MaybeT' { runMaybeT' :: m (Maybe a) }

-- A `MaybeT' m a` is an m-computation whose result is either a value
-- (Just a) or a failure (Nothing).

instance Functor m => Functor (MaybeT' m) where
  fmap f (MaybeT' mma) = MaybeT' (fmap (fmap f) mma)

instance Monad m => Applicative (MaybeT' m) where
  pure x = MaybeT' (return (Just x))
  mf <*> mx = do { f <- mf; x <- mx; return (f x) }

instance Monad m => Monad (MaybeT' m) where
  return = pure
  -- (>>=) :: MaybeT' m a -> (a -> MaybeT' m b) -> MaybeT' m b
  MaybeT' mx >>= f = MaybeT' $ do
    maybeVal <- mx                  -- run the inner m-action
    case maybeVal of
      Nothing -> return Nothing     -- short-circuit on failure
      Just x  -> runMaybeT' (f x)   -- otherwise continue

instance MonadTrans' MaybeT' where
  -- lift' :: Monad m => m a -> MaybeT' m a
  lift' mAction = MaybeT' (fmap Just mAction)
  -- "this action never fails" — wrap each result in Just.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3a. MaybeT' IO in practice
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- "I/O that can also fail" — the shape of many real programs.

type MaybeIO = MaybeT' IO

prompt :: String -> MaybeIO String
prompt msg = do
  lift' (putStr msg)                       -- IO action, lifted
  line <- lift' getLine                    -- IO action, lifted
  if null line then MaybeT' (return Nothing)
               else return line

greet :: MaybeIO ()
greet = do
  name <- prompt "Name: "                  -- bails out on empty input
  age  <- prompt "Age: "
  lift' (putStrLn ("Hello, " ++ name ++ " (" ++ age ++ ")"))

-- ghci> runMaybeT' greet :: IO (Maybe ())
--
-- Without MaybeT' we would be writing nested `case` on every IO (Maybe a)
-- result — exactly the boilerplate Maybe was supposed to eliminate.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4. StateT' — state on top of another monad
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Same recipe, different effect.  State s a ≅ s -> (a, s).
-- Put m around the result:

newtype StateT' s m a = StateT' { runStateT' :: s -> m (a, s) }

-- Exercise: write the Functor instance.
instance Functor m => Functor (StateT' s m) where
  fmap f (StateT' g) = StateT' (\s -> fmap (\(a, s') -> (f a, s')) (g s))

instance Monad m => Applicative (StateT' s m) where
  pure x = StateT' (\s -> return (x, s))
  mf <*> mx = do { f <- mf; x <- mx; return (f x) }

-- Exercise: write the Monad instance for StateT' s m.
-- Hint: run g on s, pull (a, s') out with the inner monad's >>=,
--       then run f a on s'.
instance Monad m => Monad (StateT' s m) where
  return = pure
  StateT' g >>= f = StateT' $ \s -> do
    (a, s') <- g s
    runStateT' (f a) s'

-- Exercise: write the MonadTrans' instance.
-- Hint: use fmap to pair the result with s.
instance MonadTrans' (StateT' s) where
  lift' ma = StateT' (\s -> fmap (\a -> (a, s)) ma)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4a. State operations for StateT'
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

get' :: Monad m => StateT' s m s
get' = StateT' (\s -> return (s, s))

put' :: Monad m => s -> StateT' s m ()
put' s = StateT' (\_ -> return ((), s))

modify' :: Monad m => (s -> s) -> StateT' s m ()
modify' f = StateT' (\s -> return ((), f s))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 5. Stacking effects — a worked example
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Two counters: Int (innermost) and Double (outer).
-- Innermost monad is Identity, so the bottom layer is "pure state".

type Cost      = StateT' Int Identity      -- cheap counter, innermost
type ExtraCost = StateT' Double Cost       -- expensive counter, outer

-- Pay 1 unit of Int cost and 0.5 unit of Double cost.
step :: ExtraCost ()
step = do
  modify' (+ 0.5)            -- acts on the OUTER state (Double)
  lift' (modify' (+ 1))      -- acts on the INNER state (Int) — note the lift'!

-- Run three steps:
example :: ExtraCost ()
example = step >> step >> step

-- The "order of the stack" is the order you unwrap:
-- runStateT' peels the outer Double, then the inner Int, then runIdentity.
--
-- ghci> runIdentity (runStateT' (runStateT' example 0.0) 0)
-- (((), 1.5), 3)
--          ^^^   ^
--          |     +-- final Int counter
--          +-------- final Double counter

runExample :: (((), Double), Int)
runExample = runIdentity (runStateT' (runStateT' example 0.0) 0)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 6. Where this is heading
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Pick the inner monad to taste:
--
--   StateT String Maybe  a   ~~~  parser that may fail
--   StateT String []     a   ~~~  parser with backtracking (next lecture!)
--   StateT World IO      a   ~~~  game loop with state and I/O
--
-- Same combinators (get', put', modify', lift', return, >>=) — different
-- inner monad gives you a different set of extra capabilities.
