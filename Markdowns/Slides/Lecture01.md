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

# Lazy Evaluation (Fun)

*Expression*
```
((2+3)+(1+4))+(5+6)
```

Innermost (eager) evaluation:
```
((2+3)+(1+4))+(5+6) -> (5+(1+4))+(5+6) ->
        (5+5)+(5+6) -> 10+(5+6)         ->
        10+11       -> 21
```

Lazy evaluation:
```
((2+3)+(1+4))+(5+6) -> ((2+3)+(1+4))+11 ->
      ((2+3)+5)+11  -> (5+5)+11          ->
      10+11         -> 21
```

---

# Lazy Evaluation (Fun)

Consider the same function in C and Haskell:

```c
int f(int x, int y) {
  if (x > 0)
    return x - 1;
  else
    return x + 1;
}
```

```haskell
f :: Int -> Int -> Int
f x y = if x > 0 then x-1 else x+1
```

---

# Lazy Evaluation (Fun)

Same function:

```haskell
f :: Int -> Int -> Int
f x y = if x > 0 then x-1 else x+1
```

Now add:

```haskell
val = f 1 (product [1..])
```

* What is `val`?

---

# Lazy Evaluation (Fun)

```haskell
length1 :: [a] -> Int
length1 []     = 0
length1 (x:xs) = 1 + (length1 xs)
```

Now evaluate:

```haskell
let x = product [1..] in length1 [1,x]
```

* What is the result?

---

# Lazy Evaluation (Fun)

Slightly different `length`:

```haskell
length2 :: [Int] -> Int
length2 []     = 0
length2 (x:xs) = if x > 0 then 1 + (length2 xs) else 1 + (length2 xs)
```

Now evaluate:

```haskell
let x = product [1..] in length2 [1,x]
```

* What is the result this time?

---

# Evaluation

*Example*
```haskell
length1 [1,x]    -> length1 (1:[x]) -> 1+(length1 [x]) ->
1+(length1 (x:[])) -> 1+(1+length1 []) -> 1+(1+0) -> 1+1 -> 2
```

*Definition*
An expression is in **Normal Form (NF)** if it cannot be reduced further.

*Examples*
```haskell
5
2:3:[]
(2,'t')
\x -> x+2
```

---

# Evaluation

*Definition*
An expression is in **Weak Head Normal Form (WHNF)** if it is a λ-abstraction or
an expression whose outermost constructor is evaluated.

*Examples*
```haskell
(1+1, 2)
\x -> x+2
5 : whatever
Just (sum [1..10])
```

*Non-examples*
```haskell
map (\x -> x*x) [1,2]
(+) 1 2
```

*Question*
Is
```haskell
f
```
in WHNF (or NF), given `f x = x*x`?

---

# Evaluation

*Trick*
```haskell
seq x y  -- evaluates x to WHNF, then returns y
```

Try it in GHCi:
```haskell
ghci> let x = 2+3 :: Int
ghci> :sprint x

ghci> seq x ()
()
ghci> :sprint x

ghci> let y = map id [x]
ghci> :sprint y
ghci> seq y ()
()
ghci> :sprint y

ghci> y
ghci> :sprint y
```

---

# Evaluation

*Exercise*
Trace the reduction sequence of:
```haskell
map negate [1,2,3]
```

Reference:
```haskell
map :: (a -> b) -> [a] -> [b]
map f []     = []
map f (x:xs) = (f x) : map f xs

negate :: Num a => a -> a
negate x = -x
```

*Exercise 2*
Trace the reduction sequence of:
```haskell
(take 6 . map (+1)) [1..10]
```

---

# Evaluation

*Theorem*
Lazy evaluation terminates in at most as many steps as eager evaluation.

*Problem*
Memory!

*Exercise*
```haskell
sum' []     = 0
sum' (x:xs) = x + sum' xs

sum' [1..100000000]
```

---

# Literature

* [School of Haskell](https://www.schoolofhaskell.com)
* [Learn You a Haskell for Great Good!](http://learnyouahaskell.com)
