---
theme: ./defaulttheme.json
author: Tomasz Brengos 
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 3


## Lecture code
Basics/Lecture03.hs


---

# Typeclasses

In REPL:
```haskell
ghci> :t (==)

ghci> :t show

ghci> :t (<)

ghci> :t read

ghci> :t fmap
```

---

# Defining custom instances

```haskell

data List a = Empty | Head a (List a)

instance Show a => Show (List a) where
  ...

instance Eq a => Eq (List a) where
  ...

instance Functor List where
  ...

```

---

# Defining custom typeclasses

## Examples of typeclasses predefined in Haskell (abbreviated):

```haskell
class Functor f where
  fmap :: (a -> b) -> f a -> f b

class Show a where
  show :: a -> String

class Semigroup a where
  (<>) :: a -> a -> a

class Semigroup a => Monoid a where
  mempty  :: a
  mappend :: a -> a -> a
  mappend = (<>)
```

---


# Let's extend our instance definitions for List

```haskell
instance Semigroup (List a) where
...

instance Monoid (List a) where
...
```

---


# Functors

Exercises:
```haskell
data Maybe1 a = Just a | Nothing -- Maybe a := a + {*}

instance Functor Maybe1 where
  fmap = ...
```

```haskell
data Either1 a b = Left a | Right b

instance Functor (Either1 a) where
  fmap = ...
```

---

# Folds (classically)

Let:
```haskell
(*)  :: a -> b -> b
(#)  :: b -> a -> b
seed :: b
ai   :: a
```
Consider the following:
```haskell
foldl (#) seed [a1..an] -> ((..(seed#a1)#a2#..)#an
foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)
```
Now let's look at their definitions.

---

# Folds (classically)
## foldl



```haskell
foldl :: (b -> a -> b) -> b -> [a] -> b
foldl f seed []     =  seed
foldl f seed (x:xs) =  foldl f (f seed x) xs
```

---

# Folds (classically)
## foldr

```haskell
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f seed []     = seed
foldr f seed (x:xs) = f x (foldr f seed xs)
```
Both functions are lazy! One of them can be rewritten to a
strict version:
```haskell
foldl' f seed []     = seed
foldl' f seed (x:xs) = let z = f seed x in seq z (foldl' f z xs)
```

---

# Folds (classically)

## Exercises

1) Using `foldr`, define the function
```haskell
inits :: [a] -> [[a]]
```
returning all prefixes of the argument, e.g.
```haskell
inits "tomek" = [[],"t","to","tom","tome","tomek"]
```
2) Using `foldl`, define
```haskell
approxE :: Int -> Double
```
which for argument n returns an approximation of Euler's number
(using the classical formula: sum of reciprocals of factorials of consecutive natural numbers)

## More interesting exercise

3) Express `foldl` using `foldr`.

---

# Exercise 3 (defining foldl via foldr)

## Helpful hint:

```haskell
foldl (#) seed [a1..an] -> ((..(seed#a1)#a2#..)#an
foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)
```

Consider:

```haskell
f1 = \v -> v # a1
f2 = \v -> v # a2
...
fn = \v -> v # an
```

What happens when we compute:
```haskell
(foldr (flip (.)) id [f1..fn]) seed   -- flip :: (a -> b -> c) -> (b -> a -> c)
```

```haskell
(foldr (flip (.)) id [f1..fn]) seed
  ->  (((id . fn) . fn-1) . ... . f2) . f1) seed
  ==  (fn . fn-1 . ... . f1) seed
  ->  (... (seed # a1) # a2 ...) # an
```
Complete the exercise!

---

# Foldables more generally

```haskell
data Tree a = EmptyTree | Leaf a | Node a (Tree a) (Tree a)
```
Example:
```haskell
tree :: Tree String
tree = Node "a" (Node "b" EmptyTree (Leaf "c")) (Node "d" EmptyTree EmptyTree)
```
To better understand `tree`, consider:
```
          a
        /   \
       b     d
        \
         c
```
Let's try to write a version of `foldr` for `Tree a` instead of `[a]`.

---

# Foldables more generally


```haskell
foldr :: (a -> b -> b) -> b -> Tree a -> b
foldr f seed EmptyTree           = seed
foldr f seed (Leaf x)            = f x seed
foldr f seed (Node x left right) = foldr f (f x (foldr f seed right)) left
```

We can also write something new!
```haskell
foldMap :: (Monoid m) => (a -> m) -> Tree a -> m
```
It turns out that using `foldr` we can express `foldMap` and vice versa!
This means it is sufficient to define just one of them.

## Exercise

Define `foldMap` using `foldr` and vice versa (for lists).

---

# Foldable typeclass

```haskell
class Foldable t where
  foldr   :: (a -> b -> b) -> b -> t a -> b
  foldMap :: (Monoid m) => (a -> m) -> t a -> m
-- and others:
  fold    :: (Monoid m) => t m -> m
  foldl   :: (b -> a -> b) -> b -> t a -> b
  ...
```
You don't need to define both `foldr` and `foldMap`. Just one is sufficient, as the
minimal definition of a `Foldable` instance requires either
```haskell
foldr
-- or
foldMap
```
