{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TupleSections #-}
module Lecture05 where

import Data.Char (toUpper)

--
-- ==========================================
--  Lecture 5: The List Monad & State Monad
-- ==========================================
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. The List Monad
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Recall:
--   instance Monad [] where
--     return x = [x]
--     xs >>= f = concatMap f xs
--
-- Think of a list as a non-deterministic computation:
-- each element is one possible outcome.
-- >>= applies a function to every possibility and
-- collects all the results.

triple :: a -> [a]
triple x = [x, x, x]

-- ghci> ["Bunny"] >>= triple
-- ["Bunny","Bunny","Bunny"]
--
-- ghci> ["Bunny"] >>= triple >>= triple
-- ["Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny"]


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1a. Exercise: write the Monad instance for []
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A type isomorphic to [a].
data MyList a = Nil | NonEmptyList a (MyList a)
    deriving (Show, Functor)

concat' :: MyList a -> MyList a -> MyList a
concat' Nil list = list
concat' (NonEmptyList x rest) list = NonEmptyList x (concat' rest list)

instance Applicative MyList where
  pure x = NonEmptyList x Nil
  -- <*> :: MyList (a -> b) -> MyList a -> MyList b
  Nil <*> _ = Nil
  (NonEmptyList f fs) <*> list =  concat' (fmap f list) (fs <*> list)

instance Monad MyList where
  return = pure
    -- MyList a >>= (a -> MyList b) -> MyList b
  Nil >>= _ = Nil
  (NonEmptyList x xs) >>= f = concat' (f x) (xs >>= f)



-- Recall:
--   instance Monad [] where
--     return x = ???
--     xs >>= f = ???


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1b. Pythagorean triples — non-deterministic search
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pythTriples :: [(Int, Int, Int)]
pythTriples = do
  a <- [1..20]
  b <- [a..20]
  c <- [b..20]
  if a*a + b*b == c*c then return (a,b,c) else []

-- ghci> pythTriples
-- [(3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15)]
--
-- Each <- picks one element from a list.
-- The if/then/else acts as a filter:
--   return (a,b,c) = [(a,b,c)]  -- keep this triple
--   []                           -- discard it


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1c. Do notation and list comprehensions
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- List comprehensions are just do notation for [] with
-- more compact syntax:
--
--   [x | x <- [1..20], even x]
--   ==
--   do { x <- [1..20]; if even x then [x] else [] }
--
-- Example: Fibonacci via list monad / list comprehension:

fibDo :: [Integer]
fibDo = 0 : 1 : do
  (x, y) <- zip fibDo (tail fibDo)
  return (x + y)

fibComp :: [Integer]
fibComp = 0 : 1 : [ x + y | (x, y) <- zip fibComp (tail fibComp) ]


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. State Monad — motivation
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Imagine you are writing a compiler and need to generate
-- unique variable names: _t0, _t1, _t2, ...
-- You need a counter that increases every time you use it.
-- In Python or C++ you would just use a mutable variable.
-- In Haskell, every function is pure — so you have to pass
-- the counter around by hand:

freshNameManual :: Int -> (String, Int)
freshNameManual n = ("_t" ++ show n, n + 1)

twoNamesManual :: Int -> ((String, String), Int)
twoNamesManual n0 = let (name1, n1) = freshNameManual n0
                        (name2, n2) = freshNameManual n1
                    in  ((name1, name2), n2)

-- ghci> twoNamesManual 0
-- (("_t0","_t1"), 2)
--
-- This works, but it is tedious and error-prone — it is easy
-- to accidentally write freshNameManual n0 twice instead of
-- freshNameManual n1. The more steps you have, the worse it gets.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2a. Defining the State type
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

newtype State' s a = State' { runState' :: s -> (a, s) }

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2b. Exercise: Functor and Monad instances
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Exercise: fill in the Functor instance.
--
instance Functor (State' s) where
  -- f : a -> b, State' g : State' s a
  fmap f (State' g) = State' (\s -> let (x,s') = g s in (f x, s'))  -- g :  s -> (a,s), the value is of type State' s b
--   -- Hint: run g on the state, apply f to the result, pass state along

-- (Applicative is needed for Monad; we provide it here.)
--
instance Applicative (State' s) where
  pure x = State' (x,)
  -- liftA2 :: (a -> b -> c) -> State' s a -> State' s b -> State' s c
  liftA2 f (State' g) (State' h) = State'
    (\state1 ->
      let (x, state2) = g state1
          (y, state3) = h state2
          z  = f x y
      in  (z, state3))
-- Exercise: fill in the Monad instance.
--
instance Monad (State' s) where
  return = pure
--   -- Hint: run g, feed the result to f, thread the state through
  (State' g) >>= f = State'
    (\state1 ->
      let
        (x, state2) = g state1
        (State' h)  = f x
      in h state2 )


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2c. Basic state operations
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Think of the state as a mutable variable you can
-- read, write, or update:

get1 :: State' s s                    -- read the current value    (like x in C++)
get1 = State' (\s -> (s, s))
--
put1 :: s -> State' s ()              -- overwrite with a new value (like x = 5)
put1 s = State' (const ((), s))
--
modify1 :: (s -> s) -> State' s ()    -- apply a function           (like x += 1)
modify1 f = State' (\s -> ((), f s))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2d. The fresh-name generator, revisited
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Compare with the manual version above — no more
-- threading the counter by hand!

freshName :: State' Int String
freshName = do
  n <- get1              -- read the counter
  put1 (n + 1)           -- increment it
  return ("_t" ++ show n)

twoNames :: State' Int (String, String)
twoNames = do
  x <- freshName         -- no manual threading!
  y <- freshName         -- the monad passes the counter for us
  return (x, y)

-- ghci> runState' twoNames 0


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2d'. Using the Functor instance on freshName
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- We don't need the Monad instance yet — we can build a
-- concrete freshName directly with the constructor:
--
-- freshName :: State' Int String
-- freshName = State' (\n -> ("_t" ++ show n, n + 1))
--
-- fmap transforms the *result* of a stateful computation
-- while the state still threads through automatically.
-- The counter is bumped exactly once in each of these:

-- Produce the fresh name already upper-cased:
freshNameUpper :: State' Int String
freshNameUpper = fmap (map toUpper) freshName
-- ghci> runState' freshNameUpper 0
-- ("_T0", 1)

-- Decorate a fresh name with a prefix, e.g. for a label:
freshLabel :: State' Int String
freshLabel = fmap ("label_" ++) freshName
-- ghci> runState' freshLabel 7
-- ("label__t7", 8)

-- Ask only for the *length* of the next fresh name,
-- without caring about the string itself:
freshNameLen :: State' Int Int
freshNameLen = fmap length freshName
-- ghci> runState' freshNameLen 0
-- (3, 1)          -- "_t0" has length 3, counter went 0 → 1
-- ghci> runState' freshNameLen 100
-- (5, 101)        -- "_t100" has length 5
--
-- Note: fmap can change the answer but cannot decide, based
-- on that answer, whether/how to update the state — that
-- extra power is exactly what (>>=) gives you over fmap.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2e. Tracing the execution — tick example
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- tick is like freshName but returns the counter itself:

tick :: State' Int Int
tick = do
  n <- get1
  put1 (n + 1)
  return n

-- Step-by-step trace of: runState' (do { tick; tick; tick }) 0
--
--                state    result
--   start:         0
--   1st tick:      0 → 1     0    -- get1 returns 0, put1 sets 1, return 0
--   2nd tick:      1 → 2     1    -- get1 returns 1, put1 sets 2, return 1
--   3rd tick:      2 → 3     2    -- get1 returns 2, put1 sets 3, return 2
--   final:    result = 2, state = 3
--
-- Each tick reads the current counter, bumps it, and returns
-- the old value — exactly like counter++ in C++.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2f. State Monad — stack example
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

type Stack a = State' [a]

push :: a -> Stack a ()
push x = modify1 (x:)

-- Exercise: implement pop using get1 and put1.
--
pop :: Stack a a
pop = do
  xs <- get1
  case xs of
    (y:rest) -> do
      put1 rest
      return y
    []       -> error "pop: empty stack"

-- Example usage:
--
stackOps :: Stack Int Int
stackOps = do
  push 1
  push 2
  push 3
  _ <- pop       -- removes 3
  a <- pop       -- removes 2
  return a
--
-- ghci> runState' stackOps []
-- (2, [1])
