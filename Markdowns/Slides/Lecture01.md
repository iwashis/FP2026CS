---
theme: ./defaulttheme.json
author: Tomasz Brengos 
date: MMMM dd, YYYY
---


# Functional Programming

## Lecture 1

## Code for this lecture
Lecture01.hs

---

# A Working Haskell Example

```haskell
quicksort :: Ord a => [a] -> [a]
quicksort []     = []
quicksort (x:xs) = quicksort le ++ [x] ++ quicksort gr
  where
    le = filter (< x) xs
    gr = filter (>=x) xs
```

Also works without the type signature:

```haskell
quicksort []     = []
quicksort (x:xs) = quicksort le ++ [x] ++ quicksort gr
  where
    le = filter (< x) xs
    gr = filter (>=x) xs
```

---

# Haskell — A Few Associations

* Category theory
* Declarative
* No side effects
* λ-calculus
* Lazy evaluation

---

# Haskell — A Few Associations

## Category theory

We compose arrows:
```haskell
(.) :: (b -> c) -> (a -> b) -> (a -> c)
(g . f) x = g (f x)
```

Monads are everywhere:
```haskell
class Monad m where
  (>>=)  :: m a -> (a -> m b) -> m b
  return :: a -> m a
```

*Note:*
```haskell
a -> b -> c  =  a -> (b -> c)  ~isomorphic~  (a,b) -> c
```

---

# Haskell — A Few Associations

## Declarative

*How vs. What*

---

## Programming Paradigms: Imperative vs. Declarative

Imperative (Python):
```python
sum = 0
for x in list:
    sum += x
print(sum)
```

Declarative / functional (Haskell):
```haskell
sum = foldr (+) 0 list
```

Another declarative example (SQL):
```sql
SELECT * FROM employees WHERE age >= 20;
```

---

# Haskell — A Few Associations

## No Side Effects

*Definition*
A function (expression) has *side effects* if it modifies the state of
variables outside its own environment.

*Question*
Let `f` and `g` be Python functions. Is the following always true?
```python
f(5) + g(5) == g(5) + f(5)
```

*Examples of side effects*
* Global variables
* I/O
* ...

---

# Haskell — A Few Associations

## λ-calculus

*Definition (Haskell notation)*
```
e ::= x ∈ Variables  |  \x -> e  |  e e'
```

*Definition (simply typed λ-calculus)*

Grammar of types:
```
t ::= t -> t'  |  t' ∈ BaseTypes
```

Grammar of λ-expressions:
```
e ::= x  |  \x:t -> e  |  e e'  |  c ∈ ConstantsOfBaseTypes
```

---

# Haskell — A Few Associations

## Lazy Evaluation

Infinite list of ones:
```haskell
ones = 1 : ones
```

Infinite list of natural numbers:
```haskell
nats = [1..]
```

*Puzzle*
```haskell
f = 0 : 1 : [x+y | (x,y) <- zip f (tail f)]
```

---

# Lazy Evaluation — The Key Idea

Haskell uses **call-by-need**:
- Expressions are evaluated **only when their value is required**
- Results are **shared**: each expression is evaluated at most once

Also called *lazy evaluation* or *non-strict evaluation*.

---

# Lazy Evaluation — Avoiding Unnecessary Work

Consider the same function in C and Haskell:

```c
int f(int x, int y) {
  return (x > 0) ? x - 1 : x + 1;
}
```

```haskell
f :: Int -> Int -> Int
f x y = if x > 0 then x-1 else x+1
```

In C, `f(1, expr)` always evaluates `expr`. In Haskell:

```haskell
val = f 1 (product [1..])   -- product [1..] is never evaluated!
```

`val = 0`, computed immediately. The second argument is never needed, never computed.

---

# Lazy Evaluation — Evaluation Order

*Innermost-first (call-by-value / eager):*
Evaluate arguments before applying the function.
```
((2+3)+(1+4))+(5+6) -> (5+(1+4))+(5+6) ->
        (5+5)+(5+6) -> 10+(5+6)         ->
        10+11       -> 21
```

*Outermost-first (call-by-name / lazy):*
Reduce the outermost application first; force arguments only when needed.
```
((2+3)+(1+4))+(5+6) -> ((2+3)+(1+4))+11 ->
      ((2+3)+5)+11  -> (5+5)+11          ->
      10+11         -> 21
```

Both give the same answer here. Lazy evaluation wins when an argument would diverge.

---

# Thunks

Haskell represents unevaluated expressions as **thunks** — suspended computations stored on the heap.

A thunk is *forced* (reduced to WHNF) when its value is required by:
- pattern matching
- a strict primitive (`+`, `>`, ...)
- `seq`

Once forced, the result is **shared**: the thunk is overwritten with the value and never re-evaluated.

---

# Normal Form (NF)

*Definition*
An expression is in **Normal Form (NF)** if it cannot be reduced further.

*Examples*
```haskell
42
True
[1, 2, 3]        -- i.e.  1 : 2 : 3 : []
(2, 'a')
\x -> x + 2
```

*Non-examples*
```haskell
1 + 1            -- reduces to 2
map id [1, 2]    -- reduces to [1, 2]
```

---

# Weak Head Normal Form (WHNF)

*Definition*
An expression is in **WHNF** if its outermost form is:
- a **lambda abstraction** `\x -> ...`
- a **data constructor** applied to (possibly unevaluated) arguments
- a **literal** (`42`, `True`, `'a'`, ...)
- a **partial application** (fewer arguments than the function expects)

*Examples — in WHNF but not necessarily NF*
```haskell
\x -> x + 2           -- lambda
Just (sum [1..10])    -- Just constructor; argument unevaluated
5 : map f xs          -- (:) constructor; tail unevaluated
(1+1, 2)              -- (,) constructor; first component unevaluated
```

*Not in WHNF*
```haskell
map (\x -> x*x) [1,2]   -- reducible function application
(+) 1 2                  -- reduces to 3
```

---

# WHNF vs NF

Every NF is a WHNF, but not vice versa.

| Expression | WHNF | NF |
|---|:---:|:---:|
| `42` | ✓ | ✓ |
| `\x -> x+2` | ✓ | ✓ |
| `(1+1, 2)` | ✓ | ✗ |
| `5 : map f xs` | ✓ | ✗ |
| `map f [1,2]` | ✗ | ✗ |

*Question*
Given `f x = x * x`, is `f` in WHNF? In NF?

---

# Pattern Matching Forces WHNF

```haskell
length1 :: [a] -> Int
length1 []     = 0
length1 (x:xs) = 1 + (length1 xs)
```

```haskell
let t = product [1..] in length1 [1, t]
```

Reduction — `t` is never forced:
```
length1 [1,t]  ->  1 + length1 [t]  ->  1 + (1 + length1 [])  ->  1+(1+0)  ->  2
```

Pattern matching on `:` forces only the *spine* (list structure), not the elements.

---

# Pattern Matching Forces WHNF

A small change forces `t`:

```haskell
length2 :: [Int] -> Int
length2 []     = 0
length2 (x:xs) = if x > 0 then 1 + (length2 xs) else 1 + (length2 xs)
```

```haskell
let t = product [1..] in length2 [1, t]
```

When processing the second element, `if x > 0` forces `t = product [1..]` → **diverges**.

*Key insight:* both branches are identical, yet the guard forces `t` regardless.

---

# Observing Evaluation: `seq` and `:sprint`

```haskell
seq :: a -> b -> b    -- forces first arg to WHNF, then returns second
```

Try it in GHCi:
```haskell
ghci> let x = 2+3 :: Int
ghci> :sprint x
x = _              -- unevaluated thunk
ghci> seq x ()
()
ghci> :sprint x
x = 5              -- forced to WHNF (= NF for Int)
ghci> let y = map id [x]
ghci> :sprint y
y = _              -- y is a thunk
ghci> seq y ()
()
ghci> :sprint y
y = [_]            -- spine forced to WHNF; element still a thunk
ghci> y
[5]
ghci> :sprint y
y = [5]            -- fully evaluated
```

---

# Reduction Exercises

*Exercise 1*
Trace the reduction of `map negate [1,2,3]`:
```haskell
map :: (a -> b) -> [a] -> [b]
map f []     = []
map f (x:xs) = (f x) : map f xs

negate :: Num a => a -> a
negate x = -x
```

*Exercise 2*
Trace `(take 2 . map (+1)) [1..10]`.
Stop as soon as you have the answer — observe that the rest of `[1..10]` is never evaluated.

---

# Lazy Evaluation — Termination

*Theorem (normalisation)*
If an expression has a normal form, lazy (outermost-first) evaluation will find it.
Eager evaluation may fail to terminate even when a normal form exists.

```haskell
fst (42, product [1..])   -- lazy: 42 immediately;  eager: loops forever
```

*Problem: Space Leaks*
Laziness can build up huge chains of unevaluated thunks:

```haskell
sum' []     = 0
sum' (x:xs) = x + sum' xs

sum' [1..1000000]   -- builds a thunk of depth 1,000,000 → stack overflow!
```

Fix: use a strict `seq` and a strict accumulator, 
or simply `foldl'` (we will talk about this function in the future lectures).

---

# Literature

* [School of Haskell](https://www.schoolofhaskell.com)
* [Learn You a Haskell for Great Good!](http://learnyouahaskell.com)
