---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 10


## Lecture code
Basics/src/Advanced/TypeSystems.hs


## Reference
S. Peyton Jones, D. Vytiniotis, S. Weirich and G. Washburn, *Simple Unification-based Type Inference for GADTs*, ICFP 2006.

---

# Where we are: the algebraic data type

Every type we have written so far is an **algebraic data type** — a *sum* of *products*:

```haskell
data Shape = Circle Double | Rect Double Double   -- sum of two products
data Maybe a = Nothing | Just a                   -- parameterised
data Tree a  = Leaf | Node (Tree a) a (Tree a)    -- recursive
```

ADTs are expressive and cheap to reason about. But they have one blind spot:

> **Every constructor of `T a` returns `T a`.**

The result type is fixed in advance. So the compiler can never use the *shape* of a value to rule out a class of mistakes. Today we remove that blind spot — twice.

---

# The blind spot, concretely

A tiny expression language as a plain ADT. It mixes `Int` and `Bool`:

```haskell
data UExpr = UInt Int | UBool Bool
           | UAdd UExpr UExpr | UIf UExpr UExpr UExpr
```

Nothing stops us writing **`1 + True`** — it is a perfectly well-typed `UExpr`:

```haskell
nonsense = UAdd (UInt 1) (UBool True)   -- compiles fine (!)
```

So evaluation must be **partial**: it returns a *sum of possible result types*, and fails at runtime on type errors.

```haskell
data Val = VInt Int | VBool Bool

evalU :: UExpr -> Maybe Val
evalU (UAdd a b) = case (evalU a, evalU b) of
  (Just (VInt x), Just (VInt y)) -> Just (VInt (x + y))
  _                              -> Nothing      -- "1 + True" lands here
-- ...
```

---

# Two questions, two extensions

We will push that check back to **compile time** in three steps:

- **Phantom types** — a type parameter used only in *types* → forbid illegal API *calls*.
- **GADTs** — constructors *refine* the result type → a total, type-safe interpreter.
- *DataKinds*  — promote data to the *type* level → types that *count*.


---

# Extension 1: Phantom types

A **phantom type** is a parameter that appears on the left of `=` but in **none** of the constructors on the right. It stores no data — it only carries a compile-time *tag*. *(No language pragma needed — this is plain Haskell.)*

Model a door as a state machine. The state lives **only in the type**:

```haskell
data Open      -- empty types: we never build a value of them,
data Closed    -- we only mention them in types

newtype Door state = Door String   -- `state` is phantom
```

The smart constructors encode the **legal transitions** — read the types:

```haskell
newDoor   :: String      -> Door Closed   -- a fresh door starts Closed
openDoor  :: Door Closed -> Door Open      -- may only open a Closed door
closeDoor :: Door Open   -> Door Closed    -- may only close an Open door
```

---

# Phantom types: what they buy

Legal sequences type-check; illegal ones do **not compile**:

```haskell
openDoor (newDoor "front")               -- ok:  Closed -> Open
closeDoor (openDoor (newDoor "front"))   -- ok:  Closed -> Open -> Closed

openDoor (openDoor (newDoor "front"))    -- TYPE ERROR
--   Couldn't match type 'Open' with 'Closed'
--     Expected: Door Closed
--       Actual: Door Open
```

The compiler enforces the protocol — no runtime check, no `Maybe`.

## …and what they *cannot* do

Every door is just `Door name` at runtime — **the tag is erased**. We cannot write

```haskell
isOpen :: Door s -> Bool      -- impossible by pattern matching
```

because *no constructor mentions `s`*. Matching a `Door` tells us nothing about its state. To make constructors **carry** that evidence, we need GADTs.

---

# Extension 2: GADTs

A **Generalised Algebraic Data Type** lets each constructor declare its **own result type**. Turn it on first:

```haskell
{-# LANGUAGE GADTs #-}
```

```haskell
-- ordinary ADT: every constructor returns `Expr a` for the SAME a
data Expr a = IntLit Int | BoolLit Bool | ...

-- GADT: each constructor picks the `a` it returns
data Expr a where
  IntLit  :: Int  -> Expr Int
  BoolLit :: Bool -> Expr Bool
  Add     :: Expr Int  -> Expr Int  -> Expr Int
  Mul     :: Expr Int  -> Expr Int  -> Expr Int
  IsEq    :: Expr Int  -> Expr Int  -> Expr Bool
  And     :: Expr Bool -> Expr Bool -> Expr Bool
  If      :: Expr Bool -> Expr a    -> Expr a -> Expr a
```

Now the index `a` in `Expr a` is **honest**: it is the type the expression evaluates to. An `Expr Int` can only be built from integer-producing pieces.

---

# A total, type-safe interpreter

Because the index is honest, `eval` returns **exactly `a`** — no `Maybe`, no `Val` sum, no "type error" branch:

```haskell
eval :: Expr a -> a
eval (IntLit n)  = n
eval (BoolLit b) = b
eval (Add a b)   = eval a + eval b
eval (Mul a b)   = eval a * eval b
eval (IsEq a b)  = eval a == eval b
eval (And a b)   = eval a && eval b
eval (If c t e)  = if eval c then eval t else eval e
```

And the nonsense from earlier is now a **compile error**, not a runtime `Nothing`:

```haskell
Add (IntLit 1) (BoolLit True)
--   Couldn't match type 'Bool' with 'Int'
--     Expected: Expr Int   Actual: Expr Bool
```

---


# ADT vs GADT, side by side

```haskell
-- Plain ADT                          -- GADT
data UExpr                            data Expr a where
  = UInt Int                            IntLit  :: Int  -> Expr Int
  | UBool Bool                          BoolLit :: Bool -> Expr Bool
  | UAdd UExpr UExpr                    Add     :: Expr Int -> Expr Int
  | ...                                          -> Expr Int

evalU :: UExpr -> Maybe Val           eval :: Expr a -> a
-- partial, runtime failure           -- total, no failure possible
```

- ADT: `1 + True` **compiles**, fails at runtime → `Nothing`.
- GADT: `1 + True` is a **type error** → it never runs.

We moved an entire class of bugs from *runtime* to *compile time*, and deleted the `Maybe` while we were at it.

---

# More GADTs (1): a runtime type *witness*

Remember the phantom-type limitation: the tag was **erased**, so we could not inspect it. A GADT fixes exactly that — a value that *carries* its type, recoverable by matching:

```haskell
data Ty a where
  TInt  :: Ty Int
  TBool :: Ty Bool
```

One function, type-directed behaviour — matching the witness **teaches** GHC what `a` is:

```haskell
defaultVal :: Ty a -> a
defaultVal TInt  = 0          -- here a ~ Int
defaultVal TBool = False      -- here a ~ Bool

render :: Ty a -> a -> String
render TInt  n = "int: "  ++ show n
render TBool b = "bool: " ++ show b
```

This is the phantom idea *with the evidence put back in*: `Ty a` is a runtime token from which the type `a` can be read off.

---

# Capstone: DataKinds — types that count

GADTs let constructors refine a *type*. **DataKinds** goes one level up: it **promotes** ordinary data to the *type* level. This slide needs three pragmas:

```haskell
{-# LANGUAGE GADTs #-}          -- the Vec ... where syntax
{-# LANGUAGE DataKinds #-}      -- promote Nat to a kind ('Z, 'S)
{-# LANGUAGE KindSignatures #-} -- the (n :: Nat) annotation
```

Promote the naturals:

```haskell
data Nat = Z | S Nat    -- also defines the KIND `Nat`,
                        -- with type-level values 'Z and 'S
```

A **length-indexed vector** — `Vec n a` is a list of *exactly* `n` elements:

```haskell
data Vec (n :: Nat) a where
  VNil  :: Vec 'Z a                      -- length 0
  VCons :: a -> Vec n a -> Vec ('S n) a  -- one more than the tail
```

The length now lives in the type, where the compiler can check it.

---

# What the length index buys

`vhead` is **total** — its type demands a non-empty vector, so the empty case is *impossible* and GHC never asks for it:

```haskell
vhead :: Vec ('S n) a -> a
vhead (VCons x _) = x          -- no VNil case needed; it cannot occur
```

`vzipWith` can only be called on **two vectors of the same length** `n`:

```haskell
vzipWith :: (a -> b -> c) -> Vec n a -> Vec n b -> Vec n c
vzipWith _ VNil         VNil         = VNil
vzipWith f (VCons x xs) (VCons y ys) = VCons (f x y) (vzipWith f xs ys)
```

Mismatched lengths are a **compile error** — a length-3 and a length-1 vector cannot meet:

```haskell
vzipWith (+) vec1 (VCons 1 VNil)
--   Couldn't match type 'Z' with 'S (S Z)'
```

The two impossible mixed cases (`VNil`/`VCons`) are not even reachable — GHC's coverage checker rules them out from the indices.

---

# How far does this go?

We have walked up a ladder of static guarantees:

- **ADT** — values have a type.
- **Phantom types** — *tag* a type without runtime cost; constrain the API.
- **GADTs** — constructors carry type *evidence*; pattern matches refine types.
- **DataKinds** — *values* (lengths, states, units) live in types.

The end of this road is **dependent types** (Agda, Idris, `Dependent Haskell`), where types may mention arbitrary runtime values.

The cost is real: richer types make **type inference weaker** (you write more signatures), error messages harder, and code more abstract. Reach for these tools where a class of bugs genuinely *hurts* — interpreters, protocols, sized buffers, units — not everywhere.

---

# Exercises


1. Extend `Expr` with variables and a typed environment so that `eval` takes an environment. What is the type of a lookup that must return the *right* type for each variable?

2. Give the `Door` a `lock`/`unlock` pair and a third state `Locked`, so that a `Locked` door must be unlocked before it can be opened. Write the transition types.

3. Define `vappend :: Vec m a -> Vec n a -> Vec ??? a`. What is the length of the result, and what type-level operation do you need to express it?
