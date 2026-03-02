---
theme: ./defaulttheme.json
author: Tomasz Brengos 
date: MMMM dd, YYYY
---


# Functional Programming

## Lecture 2

## Code for this lecture
Lecture02.hs

---

# Algebraic Data Types

Non-Haskell grammar summary of ADTs:
```
τ = τ in BasicTypes | τ × τ | τ + τ | τ -> τ | τ := τ
```

---

# Enumeration Types

```haskell
data Bool         = True  | False

data BasicColors  = Red   | Green | Blue
```

In general:

```haskell
data EnumType = EnumType_1 | EnumType_2 | ... | EnumType_n
```

---

# More Advanced ADTs

```haskell
data Type = Cons1 Type_11 ... Type_1n1
          | Cons2 Type_21 ... Type_2n2
          | ...
          | Consm Type_m1 ... Type_mnm
```

*Example*
```haskell
data Shape = Rectangle (Double, Double) (Double, Double)
           | Circle    (Double, Double) Double
           | Point     (Double, Double)

exampleRect :: Shape
exampleRect = Rectangle (0,1) (2,4)

exampleCirc :: Shape
exampleCirc = Circle (0,0) 5

changeRadiusIfCircle :: Shape -> Shape
changeRadiusIfCircle (Circle point r) = Circle point (r+5)
changeRadiusIfCircle x = x
```

---

# Working with ADTs — Pattern Matching

```haskell
volume :: Shape -> Double
volume (Point _)              = 0
volume (Circle _ r)           = pi * r^2
volume (Rectangle (x,y) (z,t)) = abs (z-x) * abs (t-y)
```

```
> volume (Point (1,1))
0.0
> volume (Rectangle (0,0) (3,4))
12.0
> volume (Circle (0,0) 2)
12.566370614359172
```

---

# Records

Two ways to define the same type:

```haskell
data Person1 = Person1 String String String Integer
  deriving Show
```

```haskell
data Person2 = Person2 { name    :: String
                       , surname :: String
                       , address :: String
                       , age     :: Integer
                       }
  deriving (Eq, Show)
```

Three ways to construct a value:
```haskell
examplePerson1 = Person1 "Tom" "Smith" "London" 20
examplePerson2 = Person2 "Tom" "Smith" "London" 20
examplePerson3 = Person2 { surname = "Smith"
                         , name    = "Tom"
                         , age     = 20
                         , address = "London"
                         }
```

---

# Working with Records

```haskell
data Person2 = Person2 { name    :: String
                       , surname :: String
                       , address :: String
                       , age     :: Integer
                       }
  deriving (Eq, Show)
```

```haskell
addMr :: Person2 -> Person2
addMr p@Person2 { name = name, surname = surname, .. } =
    if surname /= "" then Person2 { name = "Mr." ++ name, .. }
                     else p
```

*Note:* requires at the top of the file:
```haskell
{-# LANGUAGE RecordWildCards #-}
```

---

# Recursive ADTs

```haskell
data IntList = EmptyList | Head Int IntList

data IntTree = EmptyTree | Node Int IntTree IntTree
```

How do we work with recursive data types?

```haskell
length' :: IntList -> Int
length' EmptyList      = 0
length' (Head _ list)  = 1 + length' list
```

*Exercise*
Define `sumList :: IntList -> Int` and `depth :: IntTree -> Int`.

---

# Parameterised Types

```haskell
data List a    = EmptyList | Head a (List a)
```

Compare with the built-in:
```haskell
data [a]       = []        | a : [a]
```

Binary tree with internal values of type `a`:
```haskell
data BinTree a = EmptyTree | Node a (BinTree a) (BinTree a)
```

More examples:
```haskell
data Tuple a        = Tuple a a
data Triple a b c   = Triple a b c
data PairOrMap a b  = Pair a b | Map (a -> b)
```

---

# Important Examples

```haskell
data ()         = ()
data Bool       = True    | False
data Maybe a    = Just a  | Nothing
data Either a b = Left a  | Right b
data [a]        = []      | a : [a]
data State s a  = State { runState :: s -> (a, s) }
```

---

# Type Class Instances — Show

```haskell
instance (Show a) => Show (List a) where
    show EmptyList     = ""
    show (Head a list) = show a ++ "," ++ show list
```

```
> Head 1 (Head 50 EmptyList)
1,50,
```

---

# Type Class Instances — Eq

```haskell
instance (Eq a) => Eq (List a) where
    EmptyList   == EmptyList   = True
    (Head a _)  == EmptyList   = False
    EmptyList   == (Head a _)  = False
    (Head a xs) == (Head b ys) = a == b && xs == ys
```

```
> Head 1 (Head 2 EmptyList) == Head 1 (Head 2 EmptyList)
True
> Head 1 (Head 2 EmptyList) == Head 1 (Head 3 EmptyList)
False
```

---

# Type Aliases

Type aliases create new names for existing types — no new types are introduced:

```haskell
type Width  = Int
type Height = Int

area :: Width -> Height -> Int
area w h = w * h
```

```
> area 3 4
12
```

---

# Functor

A functor allows applying a function inside a context:

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

*Instance for our* `List`:
```haskell
instance Functor List where
    fmap _ EmptyList     = EmptyList
    fmap f (Head a list) = Head (f a) (fmap f list)
```

```
> fmap (+1) (Head 1 (Head 2 EmptyList))
2,3,
> fmap show (Head 1 (Head 2 EmptyList))
"1","2",
```

---

# Semigroup and Monoid

A **semigroup** has an associative operation `(<>)`.
A **monoid** also has a neutral element `mempty`.

```haskell
instance Semigroup (List a) where
    EmptyList   <> ys = ys
    (Head x xs) <> ys = Head x (xs <> ys)

instance Monoid (List a) where
    mempty  = EmptyList
    mappend = (<>)
```

```
> Head 1 (Head 2 EmptyList) <> Head 3 (Head 4 EmptyList)
1,2,3,4,
> mempty <> Head 1 (Head 2 EmptyList)
1,2,
```

---

# Literature

* [School of Haskell](https://www.schoolofhaskell.com)
* [Learn You a Haskell for Great Good!](http://learnyouahaskell.com)
