---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 11


## Reference
P. Wadler, *Propositions as Types*, Communications of the ACM, **58**(12), December 2015.

---

# A remarkable coincidence

Lecture 10 climbed a ladder of richer and richer types and ended pointing at **dependent types** — types that mention values, where a type can express an arbitrary fact. Today we ask *why* types can do that at all.

The answer is a discovery made independently, three times, in three different fields:

- **Gentzen (1935)** — *natural deduction*, a calculus of logical **proofs**.
- **Church (1940)** — the *simply-typed λ-calculus*, a calculus of typed **programs**.
- **Curry, then Howard (1934–1969)** — noticed these are the **same thing**.

> A **proposition** is a **type**, and a **proof** of it is a **program** of that type.

This is the **Curry–Howard correspondence**, or as Wadler calls it, *Propositions as Types*. It is not an analogy or a coincidence to be admired — it is an **identity** we can compute with.

---

# The dictionary

The correspondence is a precise translation. Read it across, line by line:

| Logic | Programming |
|---|---|
| proposition `A` | type `A` |
| proof of `A` | program `e :: A` |
| `A` is provable | `A` is *inhabited* (has a value) |
| conjunction `A ∧ B` | product `(A, B)` |
| implication `A ⇒ B` | function `A -> B` |
| disjunction `A ∨ B` | sum `Either A B` |
| truth `⊤` | unit `()` |
| falsity `⊥` | empty type `Void` |
| simplifying a proof | evaluating a program |

The rest of the lecture walks down this table. Each logical connective turns out to be a **type former you already know**.

---

# Conjunction is a pair

To prove "`A` **and** `B`", you must supply a proof of `A` **and** a proof of `B`. To build a value of type `(A, B)`, you must supply a value of `A` **and** a value of `B`. Same demand.

The logical *rules* for `∧` are exactly the API of a pair:

```haskell
-- introduction: from a proof of A and a proof of B, build A ∧ B
intro :: a -> b -> (a, b)
intro x y = (x, y)

-- elimination: from A ∧ B, extract either side
fst :: (a, b) -> a        -- A ∧ B  ⟹  A
snd :: (a, b) -> b        -- A ∧ B  ⟹  B
```

`fst` and `snd` are the two elimination rules of conjunction. The *only* way to make the proof is to have both parts — the type checker enforces precisely what the logician demands.

---

# Implication is a function

To prove "`A ⇒ B`" is to give a **method** that turns any proof of `A` into a proof of `B`. That *is* a function `A -> B`.

The two rules of implication are the two operations on functions:

```haskell
-- introduction (λ): assume A, derive B, discharge the assumption
\x -> body      -- if  x :: A  lets us build  body :: B,  then  :: A -> B

-- elimination (application, modus ponens): from A ⇒ B and A, get B
($) :: (a -> b) -> a -> b
f $ x = f x
```

Function application **is** *modus ponens*: given `f :: A -> B` and a proof `x :: A`, then `f x :: B`. The humble λ is the rule of **assumption discharge** that logicians draw with a bracketed hypothesis.

---

# Disjunction is a sum

To prove "`A` **or** `B`" you must prove **one** of them, *and say which*. That is exactly `Either A B`: a value is `Left` of an `A` **or** `Right` of a `B`.

```haskell
data Either a b = Left a | Right b

-- the two introduction rules of ∨
Left  :: a -> Either a b        -- proved A, hence A ∨ B
Right :: b -> Either a b        -- proved B, hence A ∨ B

-- elimination: to use A ∨ B, handle BOTH possible cases
either :: (a -> c) -> (b -> c) -> Either a b -> c
either f g (Left  x) = f x
either f g (Right y) = g y
```

`either` is *proof by cases*: to conclude `C` from `A ∨ B`, you must show `C` follows from `A` **and** that it follows from `B`. Pattern matching forces you to cover both.

---

# Truth, falsity, and negation

The two trivial propositions are the two trivial types:

```haskell
data Unit = Unit          -- ⊤ : trivially true, one proof, carries no info
data Void                 -- ⊥ : false, NO constructors, no proof exists
```

`Unit` (`()`) is always inhabited — `⊤` is always provable. `Void` is **uninhabited** — there is no value, just as `⊥` has no proof.

From a falsehood, anything follows (*ex falso quodlibet*) — and `Void` gives exactly that function, by matching zero cases:

```haskell
absurd :: Void -> a       -- ⊥ ⇒ A,  for any A
absurd v = case v of {}   -- no cases: there is no v to handle
```

**Negation** is then "`A` implies the absurd":

```haskell
type Not a = a -> Void    -- ¬A  ≔  A ⇒ ⊥
```

---

# Proofs are programs — worked example

A theorem is now a **type signature**, and *writing a total, terminating program of that type is a proof*. Consider commutativity of `∧`:

> `A ∧ B  ⇒  B ∧ A`

Its proof is a one-liner you have written a hundred times:

```haskell
swap :: (a, b) -> (b, a)        -- the PROPOSITION
swap (x, y) = (y, x)            -- the PROOF
```

A slightly meatier one — *currying* is the logical equivalence between `(A ∧ B) ⇒ C` and `A ⇒ (B ⇒ C)`:

```haskell
curry :: ((a, b) -> c) -> (a -> b -> c)
curry f x y = f (x, y)
```

The compiler **checks the proof for you**: if it type-checks (and is total), the theorem holds. A type error *is* a flawed proof.

---

# Computation is proof simplification

The correspondence runs deeper than a static dictionary: it matches **dynamics** too. Logicians *simplify* proofs (Gentzen's **cut elimination**); programmers *evaluate* programs (**β-reduction**). These are the **same step**.

A proof that builds a pair and immediately projects from it has a "detour":

```haskell
fst (intro x y)   -- = fst (x, y)   ⟶   x
```

The redundant *introduce-then-eliminate* is removed — that is β-reduction, and it is precisely a logician deleting a *cut*.

> proof normalisation  =  program evaluation

So a *terminating* program corresponds to a proof that simplifies to a clean *normal form*. Evaluation does not merely resemble logic; it **is** the logical act of simplifying a proof.

---

# Quantifiers: polymorphism and dependency

The connectives above are *propositional* logic. The correspondence keeps going into *predicate* logic, where it meets ideas from Lecture 10:

- **Universal `∀`** — a *parametrically polymorphic* type. `id :: forall a. a -> a` is a proof of "for all propositions `A`, `A ⇒ A`". One program; every instance.
- **Existential `∃`** — an *abstract / packaged* type (a value with a hidden type witness).
- **`∀` over values** — **dependent types** (Lecture 10's `Vec n a`): now a type may state "for *every natural* `n`, …", and a program is a proof *for all* `n`.

This is why languages like **Agda**, **Idris**, **Coq/Rocq** and **Lean** double as **proof assistants**: their type checker is a proof checker, and writing a program *is* discharging a mathematical theorem.

---

# Why this matters

*Propositions as Types* is not a curiosity at the edge of type theory — it is the reason types are powerful at all.

- Every type you write is a **tiny theorem**; every total function, its **proof**. "Make illegal states unrepresentable" is *literally* "make false propositions uninhabited".
- It explains the unreasonable reach of types from Lecture 10: phantoms, GADTs and DataKinds are all moves toward **logic embedded in types**.
- It unifies three fields: a logician, a programmer and a category theorist are studying *one structure* in three vocabularies.

> "Programs are proofs, and proofs are programs." — and neither field has to take the other on faith.

When you next satisfy a type checker, remember: you have not just compiled a program — you have **proved a theorem**.

---

# Exercises

1. The proposition `A ⇒ (B ⇒ A)` is a logical axiom (*weakening*). Write a Haskell program of type `a -> b -> a` that proves it. What standard function is this?

2. Prove `(A ⇒ B) ∧ (B ⇒ C)  ⇒  (A ⇒ C)` by giving a program of type `(a -> b) -> (b -> c) -> (a -> c)`. Which combinator did you just write?

3. Write `uncurry :: (a -> b -> c) -> ((a, b) -> c)`, the converse of the `curry` on slide 7. Together they witness a *logical equivalence* — state it.

4. Prove one direction of De Morgan, `(¬A ∨ ¬B) ⇒ ¬(A ∧ B)`, as a program over `Either (Not a) (Not b) -> Not (a, b)` (recall `Not a = a -> Void`).

5. Try to write a total program of type `Either a (Not a)` — the *law of excluded middle*, `A ∨ ¬A`. You will fail. Explain why constructive logic (and Haskell's types) cannot prove it for an arbitrary `A`.
