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

We will not start from their conclusion. We will sneak up on it.

---

# A proposition looks like a type

Start with the gentlest version of the idea — not an identity, just a resemblance worth taking seriously.

A **proposition** is a claim: "it is raining", "`A` and `B`", "`A` implies `B`". To *assert* a proposition, it is not enough to write it down — you must hand over a **proof**.

A **type** is a collection of values. To *use* a type, it is not enough to name it — you must hand over a **value** of it.

Line those up:

> To have the proposition `A`, exhibit a **proof** of `A`. To have the type `A`, exhibit a **value** of `A`.

So let us *guess* that **a proposition is a type, and a proof of it is a value of that type** — and then test the guess on every logical connective in turn. If the guess is right, each way of *building* a proposition should match a way of *building* a type you already know.

---

# "or" is a sum — `Either`

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

`either` is *proof by cases*: to conclude `C` from `A ∨ B`, you must show `C` follows from `A` **and** that it follows from `B`. Pattern matching forces you to cover both. The guess holds: disjunction `∨` **is** the sum type.

---

# "and" is a product — the pair

To prove "`A` **and** `B`", you must supply a proof of `A` **and** a proof of `B`. To build a value of type `(A, B)`, you must supply a value of `A` **and** a value of `B`. Same demand.

The logical *rules* for `∧` are exactly the API of a pair — the **cartesian product** of `A` and `B`:

```haskell
-- introduction: from a proof of A and a proof of B, build A ∧ B
intro :: a -> b -> (a, b)
intro x y = (x, y)

-- elimination: from A ∧ B, extract either side
fst :: (a, b) -> a        -- A ∧ B  ⟹  A
snd :: (a, b) -> b        -- A ∧ B  ⟹  B
```

`fst` and `snd` are the two elimination rules of conjunction. The *only* way to make the proof is to have both parts — the type checker enforces precisely what the logician demands. Again the guess holds: conjunction `∧` **is** the product type.

---

# "implies" is a function

To prove "`A ⇒ B`" is to give a **method** that turns any proof of `A` into a proof of `B`. That *is* a function `A -> B` — the **functional type** is implication.

The two rules of implication are the two operations on functions:

```haskell
-- introduction (λ): assume A, derive B, discharge the assumption
\x -> body      -- if  x :: A  lets us build  body :: B,  then  :: A -> B

-- elimination (application, modus ponens): from A ⇒ B and A, get B
($) :: (a -> b) -> a -> b
f $ x = f x
```

Function application **is** *modus ponens*: given `f :: A -> B` and a proof `x :: A`, then `f x :: B`. The humble λ is the rule of **assumption discharge** that logicians draw with a bracketed hypothesis. Three connectives, three type formers — the resemblance is no accident.

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

# Now the dictionary writes itself

Every guess held. Collecting them, the resemblance hardens into a precise **translation** — read it across, line by line:

| Logic | Programming |
|---|---|
| proposition `A` | type `A` |
| proof of `A` | program `e :: A` |
| `A` is provable | `A` is *inhabited* (has a value) |
| disjunction `A ∨ B` | sum `Either A B` |
| conjunction `A ∧ B` | product `(A, B)` |
| implication `A ⇒ B` | function `A -> B` |
| truth `⊤` | unit `()` |
| falsity `⊥` | empty type `Void` |
| simplifying a proof | evaluating a program |

This is the **Curry–Howard correspondence**, or as Wadler calls it, *Propositions as Types*. It is not an analogy to be admired from afar — it is an **identity** we can compute with. What we guessed connective by connective, Gentzen, Church, Howard proved holds wholesale.

> A **proposition** is a **type**, and a **proof** of it is a **program** of that type.

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

# From propositions to predicates

Everything so far lived in **propositional** logic: `∧`, `∨`, `⇒` combine whole propositions, but none of them can talk about a *particular thing*. Real mathematics says more:

- "for **every** natural `n`, `n + 0 = n`"
- "**there exists** a vector of some length built from this list"

These are **predicate** logic — propositions *indexed by values*. To carry Curry–Howard into them, the type side must gain the same power: **types that mention values**. That is exactly a **dependent type**, and the two quantifiers become two new type formers.

| Logic | Types |
|---|---|
| `∀ x. P x` | dependent function (Π-type) |
| `∃ x. P x` | dependent pair (Σ-type) |

---

# Types that depend on values

A dependent type is a **type-valued function**. The length-indexed vector from Lecture 10 is the canonical example (here in Agda, where `Set` is the type of types):

```agda
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : {n : ℕ} → A → Vec A n → Vec A (suc n)
```

`Vec A` is *not* a type — it is a function `ℕ → Set`. Feed it a type `ℕ` and a **value** `3`, and only then do you get a type, `Vec ℕ 3`, whose values are exactly the triples. The length now lives **inside the type**.

Because types are computed from values, the type checker must *evaluate* while checking: `Vec A (1 + 2)` and `Vec A 3` are the **same type**. Type checking and computation are no longer separate phases.

---

# `∀` is a dependent function — the Π-type

An ordinary function `A → B` has a *fixed* result type. A **dependent function** lets the result type *depend on the argument value*:

```agda
replicate : {A : Set} (n : ℕ) → A → Vec A n
replicate zero    _ = []
replicate (suc k) x = x ∷ replicate k x
```

The argument `n` appears in the **return type** `Vec A n`. Read logically:

> `∀ (n : ℕ). A ⇒ Vec A n`

This is the **Π-type**, written `(n : ℕ) → Vec A n`. A proof of a *universally quantified* statement **is** a function that, given any `n`, produces a proof for that `n` — one program, every instance. Ordinary polymorphism is the special case `∀ (A : Set). …` (the implicit `{A : Set} →`): the argument is a type rather than a value.

---

# `∃` is a dependent pair — the Σ-type

Sometimes the result length cannot be predicted — `filter` keeps an unknown number of elements. We must **return the length alongside the vector**, and the type of the second component depends on the first:

```agda
filter : {A : Set} {n : ℕ} → (A → Bool) → Vec A n → Σ[ m ∈ ℕ ] Vec A m
```

`Σ[ m ∈ ℕ ] Vec A m` is a **dependent pair**: a value `m` *together with* a `Vec A m`. Read logically:

> `∃ (m : ℕ). Vec A m`

This is the **Σ-type**. A proof of an *existential* is a **witness paired with evidence** — a pair whose second component's type is determined by the first. The ordinary product `A × B` is the degenerate Σ-type where the second type does not depend on the first component, just as `A → B` is the degenerate Π-type.

---

# Equality is a type, too

The deepest step: even an **equation `a ≡ b`** becomes a type — inhabited exactly when the two sides compute to the same value.

```agda
data _≡_ {A : Set} (x : A) : A → Set where
  refl : x ≡ x
```

The single constructor `refl : x ≡ x` says "everything equals itself". **A proof of an equation is a value of an equality type** — and `refl` proves any equation whose two sides *compute* to the same value. To use it, we first need numbers that compute. Let us build them.

---

# Natural numbers, and addition that computes

Agda's `ℕ` is just Peano's two axioms as a datatype, and `+` is structural recursion on the **first** argument:

```agda
data ℕ : Set where
  zero : ℕ
  suc  : ℕ → ℕ

_+_ : ℕ → ℕ → ℕ
zero  + n = n                -- (1)
suc m + n = suc (m + n)      -- (2)
```

A numeral like `3` is just sugar for `suc (suc (suc zero))`. Each clause of `_+_` is a **computation rule** the type checker runs while checking a type. So `+` is not a black box the runtime calls — it *unfolds during type checking*.

---

# Numbers compute: `2 + 1 ≡ 3`

Concrete equations need no induction — they are proved by pure computation, so the proof is literally `refl`:

```agda
_ : 2 + 1 ≡ 3
_ = refl

_ : 2 + 2 ≡ 4
_ = refl
```

Unfolding the first one with the two rules for `_+_`:

```text
2 + 1  =  suc (suc zero) + suc zero
       =  suc (suc zero  + suc zero)     -- rule (2)
       =  suc (suc (zero + suc zero))    -- rule (2)
       =  suc (suc (suc zero))           -- rule (1)
       =  3
```

Both sides reduce to the *same* value `suc (suc (suc zero))`, so `refl : 3 ≡ 3` type-checks. The equation holds **by definition of `+`** — the machine simply ran it.

---

# When computation gets stuck: `n + 0 ≡ n`

A theorem such as *"for every `n`, `n + 0 ≡ n`"* is a genuine dependent function type:

```agda
plusZero : (n : ℕ) → n + 0 ≡ n
```

But now `refl` *fails*. In `2 + 1` the first argument was a concrete `suc (...)`, so rule (2) fired and the sum collapsed to a numeral. Here the first argument is a **variable** `n`: neither rule matches `n + 0`, so it is **stuck** — it is not definitionally `n`. We must reason about *all* `n` at once, by induction.

---

# Proving a theorem by induction

The fix is to **split on `n`**, exactly as induction does. Dependent pattern matching makes each case's type compute, and the recursive call is the induction hypothesis:

```agda
plusZero : (n : ℕ) → n + 0 ≡ n
plusZero zero    = refl                 -- base: 0 + 0  reduces to  0
plusZero (suc k) = cong suc (plusZero k) -- step: from k+0≡k  get  (suc k)+0 ≡ suc k
```

- The **base case** holds by computation: `0 + 0` reduces to `0`, so `refl` checks.
- The **step** invokes the induction hypothesis `plusZero k : k + 0 ≡ k` and `cong : (f : A → B) → x ≡ y → f x ≡ f y` to push it under `suc`.

The recursion is the induction; the totality checker confirms every case is covered and the proof terminates. This is a genuine mathematical proof — **machine-checked**.

---

# A toolkit, and one more lemma

Equality proofs compose like ordinary equational reasoning. Two combinators do all the work:

```agda
sym   : {x y : ℕ} → x ≡ y → y ≡ x          -- flip an equation
trans : {x y z : ℕ} → x ≡ y → y ≡ z → x ≡ z -- chain two equations
```

To prove commutativity we also need the *mirror* of `plusZero` — pushing a `suc` out of the **second** argument. Same induction on the first argument:

```agda
plusSuc : (m n : ℕ) → m + suc n ≡ suc (m + n)
plusSuc zero    n = refl                  -- suc n ≡ suc n
plusSuc (suc m) n = cong suc (plusSuc m n) -- IH under one more suc
```

---

# Addition is commutative

Now the headline theorem, `m + n ≡ n + m`, by induction on `m`:

```agda
+-comm : (m n : ℕ) → m + n ≡ n + m
+-comm zero    n = sym (plusZero n)
+-comm (suc m) n = trans (cong suc (+-comm m n)) (sym (plusSuc n m))
```

- **Base** (`m = zero`): the goal is `n ≡ n + 0` (since `zero + n` reduces to `n`). That is `plusZero n` flipped — `sym (plusZero n)`.
- **Step** (`m = suc m`): the goal is `suc (m + n) ≡ n + suc m`. Chain two facts with `trans`:
  - `cong suc (+-comm m n) : suc (m + n) ≡ suc (n + m)` — the induction hypothesis under `suc`;
  - `sym (plusSuc n m)     : suc (n + m) ≡ n + suc m` — the lemma, flipped.

The type checker verifies the chain lines up. We have proved, for **all** naturals, that order does not matter — a theorem of arithmetic, written as a program.

---

# Dependent types in practice

With lengths in the type, the compiler **rejects meaningless operations before they run**:

```agda
head : {A : Set} {n : ℕ} → Vec A (suc n) → A   -- typed ONLY for non-empty vectors
head (x ∷ _) = x                                -- no [] case — it is impossible
```

`head []` is not a runtime crash — it is a **type error**: `[] : Vec A zero` cannot match `Vec A (suc n)`. The classic "head of empty list" bug becomes *unrepresentable*. Similarly, vector append can *prove its own arithmetic*:

```agda
_++_ : {A : Set} {m n : ℕ} → Vec A m → Vec A n → Vec A (m + n)
```

This is why **Agda, Idris, Coq/Rocq and Lean** are simultaneously programming languages **and** proof assistants: their type checker *is* a proof checker. Writing a total program of a dependent type discharges a theorem — Curry–Howard carried from propositional connectives all the way up to quantified mathematics.
