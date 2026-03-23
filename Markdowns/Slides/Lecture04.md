---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 4


## Lecture code
Lecture04.hs

---

# Not every parameterised type is a Functor

A `Functor` lets you transform the value *inside* a context. But this only works when the type parameter appears in **output** (covariant) position.

**Counter-example:** a predicate *consumes* an `a`, so it cannot be a `Functor`.
```haskell
newtype Predicate a = Predicate (a -> Bool)

-- Attempt:
fmap :: (a -> b) -> Predicate a -> Predicate b
fmap f (Predicate p) = Predicate (\b -> ???)
--   f :: a -> b
--   p :: a -> Bool
--   b :: b          -- we need (b -> Bool), but can only go a → b, not b → a!
```

**Rule of thumb:** if the type parameter appears to the *left* of an arrow (input position), you cannot write a lawful `fmap`. Such types are called *contravariant*.

---

# Applicative Functors

Before we get to monads, it is worth understanding applicative functors, which are an important intermediate link in the type hierarchy.

```haskell
class Functor f => Applicative f where
  pure  :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
```

An applicative functor is a functor extended with two operations:
- `pure` - places a value into a context (similar to the later `return`)
- `(<*>)` - applies a function in a context to a value in a context

## Applicative laws:
```haskell
pure id <*> v = v                            -- identity
pure (.) <*> u <*> v <*> w = u <*> (v <*> w) -- composition
pure f <*> pure x = pure (f x)               -- homomorphism
u <*> pure y = pure ($ y) <*> u              -- interchange
```

---

# Applicative examples

## Maybe as Applicative:
```haskell
instance Applicative Maybe where
  pure = Just

  Nothing <*> _ = Nothing
  (Just f) <*> something = fmap f something
```

## Usage:
```haskell
-- Combining two Maybe values
liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
liftA2 f x y = f <$> x <*> y

-- Example:
createUser :: Maybe String -> Maybe Int -> Maybe User
createUser name age = liftA2 User name age
```

---

## Step-by-step: adding two Maybe numbers
```haskell
-- (+) <$> Just 3 <*> Just 5
-- Step 1: fmap (+) (Just 3)  =>  Just (+3)
-- Step 2: Just (+3) <*> Just 5  =>  Just 8

ghci> (+) <$> Just 3  <*> Just 5   -- Just 8
ghci> (+) <$> Nothing <*> Just 5   -- Nothing
ghci> (+) <$> Just 3  <*> Nothing  -- Nothing
```
Missing data anywhere → the whole result is `Nothing`. No `case` needed.

---

## List as Applicative
### Lecture exercise

Write the `Applicative` instance for lists.

## List Applicative — all combinations
```haskell
sizes  = ["S", "M", "L"]
colors = ["red", "blue"]

-- Every size paired with every color:
ghci> (,) <$> sizes <*> colors
[("S","red"),("S","blue"),("M","red"),("M","blue"),("L","red"),("L","blue")]
```
Useful for generating test cases, board game moves, brute-force search, …

---

# A Functor that is NOT Applicative

Not every `Functor` can be made `Applicative`. It is a perfectly good `Functor`:
```haskell
instance Functor (Map k) where          -- (simplified)
    fmap f m = Map.map f m              -- apply f to every value
```

Can we write `pure`?
```haskell
pure :: a -> Map k a
pure x = ???   -- a Map that maps *every possible key* to x?
```
A `Map` is finite, but the key space may be infinite (e.g. `Map Int a`). 
There is no way to build a map that contains *all* keys. So `pure` cannot be implemented.

What about `(<*>)`?
```haskell
(<*>) :: Map k (a -> b) -> Map k a -> Map k b
```
We could intersect keys and apply — but without a lawful `pure`, the applicative laws break down.


---

# Monads — the problem first

Suppose we want to chain several operations that can each fail.
Without any abstraction we get deeply nested `case` expressions:
```haskell
lookupEmail :: Int -> Maybe String
lookupEmail uid =
  case Map.lookup uid users of
    Nothing   -> Nothing
    Just name -> case Map.lookup name emails of
                   Nothing    -> Nothing
                   Just email -> Just email
```
Every step must manually check for failure. This does not scale.

---

# The Maybe Monad

The Maybe monad instance lets us chain fallible steps without manual checking:
```haskell
instance Monad Maybe where
  Nothing >>= _ = Nothing
  Just x  >>= f = f x

  return = Just
```
- `>>=` (bind): if the left side is `Nothing`, stop and return `Nothing`; otherwise, feed the value inside `Just` to the next step.
- `return`: wrap a plain value into `Just`.

---

## Safe division — chaining without crashing
```haskell
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)

ghci> safeDiv 100 10 >>= safeDiv 5   -- Just 2
ghci> safeDiv 100 0  >>= safeDiv 5   -- Nothing
```

## Dictionary lookup chain — revisited
```haskell
import qualified Data.Map as Map

users  = Map.fromList [(1, "alice"), (2, "bob")]
emails = Map.fromList [("alice", "alice@example.com")]

lookupEmail :: Int -> Maybe String
lookupEmail uid = Map.lookup uid users >>= \name -> Map.lookup name emails

ghci> lookupEmail 1   -- Just "alice@example.com"
ghci> lookupEmail 2   -- Nothing  (bob has no email)
ghci> lookupEmail 99  -- Nothing  (unknown user)
```

---

## Safe head and tail
The functions `head` and `tail` in Haskell are partial.
We can make them safe:
```haskell
head' :: [a] -> Maybe a
head' []     = Nothing
head' (x:_)  = Just x

tail' :: [a] -> Maybe [a]
tail' []     = Nothing
tail' (_:xs) = Just xs
```

## Exercise:
Using `head'` and `tail'`, write a function that returns the 3rd element
of the input list:
```haskell
third :: [a] -> Maybe a
```

---

# Monads — the general pattern

Looking at the examples, we see the same pattern every time:

> A **monad** is a functor `m` with two operations:
```haskell
(>>=)  :: m a -> (a -> m b) -> m b   -- chain a computation into the next step
return ::   a -> m a                  -- wrap a plain value, no effects
```
Think of `m a` as *a computation that produces an `a`* (possibly with failure, non-determinism, I/O, …).

---

## Monad Laws

Three laws ensure that `>>=` and `return` behave sensibly:
```haskell
return x >>= f        = f x              -- left identity:  return does nothing extra
m >>= return          = m                -- right identity: return does nothing extra
(m >>= f) >>= g       = m >>= (\x -> f x >>= g)  -- associativity: grouping doesn't matter
```

---

## An Applicative that is NOT a Monad

`ZipList` applies functions to elements *positionally* (by zipping), rather than generating all combinations:
```haskell
newtype ZipList a = ZipList [a]

instance Applicative ZipList where
    pure x                          = ZipList (repeat x)
    (ZipList fs) <*> (ZipList xs)   = ZipList (zipWith ($) fs xs)

ghci> ZipList [(+1), (*10)] <*> ZipList [3, 4]
ZipList [4, 40]
```

Why can't we write a lawful `Monad` instance?
```haskell
(>>=) :: ZipList a -> (a -> ZipList b) -> ZipList b
```
Bind would apply the function to each element, getting a *separate list* from each — but these inner lists may have *different lengths*. There is no principled way to zip them back together while satisfying the monad laws (associativity breaks).

**Lesson:** `Applicative` combines *independent* effects; `Monad` lets later effects *depend* on earlier results. `ZipList`'s positional structure handles independence but breaks when results determine the shape of what comes next.

---

## Composing monadic functions

A *monadic function* has type `a -> m b`: takes a plain value, returns a computation.
Two such functions can be composed with the **fish** operator:
```haskell
(>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c
f >=> g = \x -> f x >>= g
```

## Relationship between >=> and >>=
```haskell
f >=> g      = \x -> ( f x >>= g )

x >>= g      = (const x >=> g) ()
```
`>>=` and `>=>` are two sides of the same coin — use whichever reads more clearly.

---

# Do Notation

Chaining many `>>=` calls with lambdas gets noisy. Haskell provides **do notation** as syntactic sugar:
```haskell
-- With >>=:
lookupEmail uid =
  Map.lookup uid users >>= \name ->
  Map.lookup name emails

-- With do notation:
lookupEmail uid = do
  name  <- Map.lookup uid users
  email <- Map.lookup name emails
  return email
```
Each `x <- action` is just `action >>= \x -> …` in disguise. The compiler desugars do notation into `>>=` chains automatically.

## Do notation desugaring rules
```haskell
do { x <- m ; rest }  =  m >>= \x -> do { rest }
do { m ; rest }        =  m >>  do { rest }
do { return x }        =  return x
```
`>>` is just `>>=` that discards the result:
```haskell
(>>) :: Monad m => m a -> m b -> m b
m >> k = m >>= \_ -> k
```

## Exercise: rewrite with do notation
Rewrite the `third` function using do notation:
```haskell
third :: [a] -> Maybe a
third xs = do
  ...
```
