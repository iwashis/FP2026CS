---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 8


## Lecture code
Calculator/test/Spec.hs


## Reference
K. Claessen and J. Hughes, *QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs*, ICFP 2000.

---

# Property-based testing in one slide

A unit test fixes one input and asserts one output:
```haskell
reverse [1,2,3] == [3,2,1]    -- passes or fails on this single example
```
A property fixes a **law** the function should obey for *every* input:
```haskell
prop_reverse_involutive :: [Int] -> Bool
prop_reverse_involutive xs = reverse (reverse xs) == xs
```
QuickCheck's job is to **generate random `xs`** and check the law. When it finds a counter-example, it **shrinks** it to the smallest input that still breaks the property.

Everything we will build today lives in `Test.QuickCheck`, but its core fits on a handful of slides — that is the whole point of the paper.

---

# Warm-up: QuickCheck *in use* before we build it

Three deliberately-false properties on `[Int]` — every one of them is *obviously* wrong, which is exactly the point: it lets us focus on **what QuickCheck does at runtime** before we look at how it is implemented.

```haskell
import Test.QuickCheck
import Data.List (sort, nub)

-- FALSE: claims reversing a list is the identity.
prop_reverse_id      :: [Int] -> Property
prop_reverse_id xs   = reverse xs === xs

-- FALSE: claims lists never contain duplicates.
prop_no_duplicates     :: [Int] -> Property
prop_no_duplicates xs  = nub xs === xs
```

## What `quickCheck` does at runtime

1. **Generate** a random `xs :: [Int]` (size-bounded, sampled from `arbitrary`).
2. **Evaluate** the property.
3. If it passes, draw a fresh `xs` and repeat — up to 100 times by default.
4. If it **fails**, *do not stop*: try smaller `xs` from the shrinker, keep the smallest one that still falsifies, and *print that*.

Each property above will end up at a tiny, human-readable counter-example. Crucially, none of these length-≤-1 candidates are counter-examples (`reverse [] = []`, `reverse [x] = [x]`), so we expect a *length-2* answer — and that is exactly what we get.

---

# Reading a QuickCheck run

A typical session — the same three properties:

```
ghci> quickCheck prop_reverse_id
*** Failed! Falsified (after 3 tests and 4 shrinks):
[0,1]
[1,0] /= [0,1]

ghci> quickCheck prop_no_duplicates
*** Failed! Falsified (after 7 tests and 9 shrinks):
[0,0]
[0] /= [0,0]
```
 
---

Three things to notice immediately:
- The counter-example for `prop_reverse_id` is **length 2** — any shorter list is *not* a counter-example, because for those `reverse xs == xs`.
- `prop_no_duplicates` minimises both the *length* and the *element values* — `[0,0]` is the smallest failing list, not `[3,3]` or `[17,42,17]`.
- "*after N tests and M shrinks*" — `N` random tests until one failed, `M` greedy shrink steps to whittle it down.

The rest of the lecture answers a single question: **how does QuickCheck do all of this in ~200 lines of Haskell?**

---

# The `Gen` monad

Two pieces of state are threaded through every generator:

1. a **size** `Int` — an upper bound on the "complexity" of the value (length of a list, depth of a tree, ...),
2. a **random seed** of type `StdGen`.

```haskell
import System.Random (StdGen, split, randomR)

newtype Gen a = Gen { unGen :: Int -> StdGen -> a }

instance Functor Gen where
  fmap f (Gen h) = Gen $ \n g -> f (h n g)

instance Applicative Gen where
  pure x = Gen $ \_ _ -> x
  Gen hf <*> Gen hx = Gen $ \n g ->
    let (g1, g2) = split g
    in  hf n g1 (hx n g2)

instance Monad Gen where
  return = pure
  Gen h >>= k = Gen $ \n g ->
    let (g1, g2) = split g
    in  unGen (k (h n g1)) n g2
```
A generator is *just* a function from `(size, seed)` to a value. `split :: StdGen -> (StdGen,StdGen)` is the critical detail: two sub-generators must get **independent** seeds, otherwise children of a tree would correlate.

---

# Primitive generators

```haskell
choose :: (Int, Int) -> Gen Int
choose (lo, hi) = Gen $ \_ g -> fst (randomR (lo, hi) g)

sized :: (Int -> Gen a) -> Gen a
sized f = Gen $ \n g -> unGen (f n) n g

resize :: Int -> Gen a -> Gen a
resize m (Gen h) = Gen $ \_ g -> h m g

elements :: [a] -> Gen a
elements xs = do
  i <- choose (0, length xs - 1)
  pure (xs !! i)

oneof :: [Gen a] -> Gen a
oneof gs = do
  i <- choose (0, length gs - 1)
  gs !! i

frequency :: [(Int, Gen a)] -> Gen a
frequency wgs = do
  let total = sum (map fst wgs)
  k <- choose (1, total)
  pick k wgs
  where
    pick k ((w, g) : rest)
      | k <= w    = g
      | otherwise = pick (k - w) rest
    pick _ [] = error "frequency: empty list"

vectorOf :: Int -> Gen a -> Gen [a]
vectorOf 0 _ = pure []
vectorOf k g = (:) <$> g <*> vectorOf (k - 1) g
```

`sized` is how we **read** the budget; `resize` is how we **change** it; `frequency` is how we **bias** the choice (heavy leaves, light recursive cases).

---

# The `Arbitrary` class

```haskell
class Arbitrary a where
  arbitrary :: Gen a
  shrink    :: a -> [a]
  shrink _  = []                 -- default: no shrinks
```

Instances for primitives:
```haskell
instance Arbitrary Bool where
  arbitrary    = elements [False, True]
  shrink True  = [False]
  shrink False = []

instance Arbitrary Int where
  arbitrary = sized $ \n -> choose (-n, n)
  shrink 0  = []
  shrink n  = 0 : [ n `div` 2 | n /= 0 ]
                ++ [ n - 1   | n > 0 ]
                ++ [ n + 1   | n < 0 ]
```

Recursive instance for lists — *size-aware*:
```haskell
instance Arbitrary a => Arbitrary [a] where
  arbitrary = sized $ \n -> do
    k <- choose (0, n)
    vectorOf k arbitrary
  shrink []     = []
  shrink (x:xs) = xs                            -- drop the head
                : [ x':xs  | x'  <- shrink x  ] -- shrink the head
               ++ [ x:xs'  | xs' <- shrink xs ] -- shrink the tail
```

The size discipline is the **whole reason** `Gen` carries an `Int`: as we recurse into structure, we *shrink the budget* so generators terminate.

---

# Generators for user types — the recursion discipline

Take the calculator AST from Lecture 7:
```haskell
data Expr = Lit Int | Neg Expr | Add Expr Expr
          | Sub Expr Expr | Mul Expr Expr | Div Expr Expr
```
Naive generator:
```haskell
arbitrary = oneof
  [ Lit <$> arbitrary
  , Neg <$> arbitrary
  , Add <$> arbitrary <*> arbitrary, ... ]
```
loops with probability ≥ ½ — a binary node calls `arbitrary` twice and never shrinks the budget. The textbook fix:

```haskell
instance Arbitrary Expr where
  arbitrary = sized gen
    where
      gen 0 = Lit <$> arbitrary
      gen n = frequency
        [ (1, Lit <$> arbitrary)
        , (1, Neg <$> gen (n - 1))
        , (2, bin Add), (2, bin Sub)
        , (2, bin Mul), (2, bin Div) ]
        where
          half  = n `div` 2
          bin c = c <$> gen half <*> gen half

  shrink (Lit n)   = [ Lit n' | n' <- shrink n ]
  shrink (Neg e)   = e : [ Neg e' | e' <- shrink e ]
  shrink (Add a b) = [a, b]
                  ++ [ Add a' b | a' <- shrink a ]
                  ++ [ Add a b' | b' <- shrink b ]
  -- ... Sub, Mul, Div similar
```

Two invariants worth stressing:
- at `n = 0` only leaves are produced — recursion **must** terminate,
- binary constructors halve the budget — both children stay small.

---

# The `Property` type

A property is a generator of *test outcomes*:
```haskell
data Result = Result
  { ok     :: Maybe Bool   -- Nothing  = test discarded (precondition false)
                           -- Just b   = test passed / failed
  , reason :: String
  , inputs :: [String]     -- printable arguments collected during evaluation
  , labels :: [String]     -- bookkeeping (classify / collect)
  }

newtype Property = Property { unProperty :: Gen Result }
```
The two boolean carriers worth noticing:
- `ok = Nothing`     — *discarded*, not failed. `==>` uses this.
- `ok = Just False`  — the only state QuickCheck actually fails on.
- `ok = Just True`   — the test passed.

A `Property` is therefore richer than a `Bool`: it carries the inputs that produced the outcome, so the user gets a useful failure message.

---

# The `Testable` class — what counts as a property?

```haskell
class Testable prop where
  property :: prop -> Property

instance Testable Bool where
  property b = Property $ pure $ Result
    { ok = Just b, reason = "", inputs = [], labels = [] }

instance Testable Property where
  property p = p

instance (Arbitrary a, Show a, Testable prop)
      => Testable (a -> prop) where
  property f = Property $ do
    a   <- arbitrary
    res <- unProperty (property (f a))
    pure (res { inputs = show a : inputs res })
```

The recursive instance is the **whole story**: a curried function `a -> b -> Bool` is testable because `a -> b -> Bool` reduces to `b -> Bool` after randomly generating `a`, which reduces to `Bool` after randomly generating `b`. Each layer adds one random argument and records its `show` in the failure message.

---

# `==>`, `forAll`, `classify`, `collect`

Conditional properties — a discarded test counts neither as passed nor as failed:
```haskell
infixr 0 ==>
(==>) :: Testable prop => Bool -> prop -> Property
False ==> _ = Property $ pure $ Result
  { ok = Nothing, reason = "precondition false"
  , inputs = [], labels = [] }
True  ==> p = property p
```

Explicit generator (skips the `Arbitrary` default, useful for ranges or smart constructors):
```haskell
forAll :: (Show a, Testable prop) => Gen a -> (a -> prop) -> Property
forAll g k = Property $ do
  a   <- g
  res <- unProperty (property (k a))
  pure (res { inputs = show a : inputs res })
```

Bookkeeping — turns *did it pass?* into *how was the input distributed?*:
```haskell
classify :: Testable prop => Bool -> String -> prop -> Property
classify b lab p = Property $ do
  res <- unProperty (property p)
  pure (res { labels = if b then lab : labels res else labels res })

collect :: (Show a, Testable prop) => a -> prop -> Property
collect x = classify True (show x)
```

`classify` is invaluable for catching the "passes 100 times on the empty list" bug.

---

# Shrinking — what makes counter-examples readable

A counter-example is most useful when it is **minimal**. The shrinker is a greedy local-minimum search:
```haskell
shrinkLoop :: Testable prop
           => (a -> prop) -> (a -> [a]) -> a -> IO a
shrinkLoop run shrinkA = go
  where
    go x = do
      mfail <- firstFailing run (shrinkA x)
      case mfail of
        Nothing -> pure x                 -- local minimum reached
        Just x' -> go x'                  -- keep shrinking

firstFailing :: Testable prop
             => (a -> prop) -> [a] -> IO (Maybe a)
firstFailing _   []     = pure Nothing
firstFailing run (x:xs) = do
  passed <- runOnce (run x)
  if passed then firstFailing run xs else pure (Just x)
```
Read it like this:
- evaluate `shrink x` — a list of "slightly smaller" candidates,
- find the first one that *still* fails,
- iterate until no smaller failing candidate exists.

A bad shrinker is the difference between
```
*** Failed!   [42,-7,3,15,0,-2,9,18]
```
and
```
*** Failed!   [0,1]
```
— and the same insight applies, *unchanged*, to your own recursive types. The warm-up `prop_reverse_id` shrunk all the way down to `[0,1]` because lists' built-in shrinker peels off the head, peels off the tail, and shrinks each element towards `0`. For `Expr` we will have to write that shrinker ourselves; without it, a failing run produces
```
*** Failed!   Add (Mul (Lit 27) (Neg (Lit 3))) (Sub (Lit 9) (Lit (-12)))
```
instead of the legible
```
*** Failed!   Add (Lit 0) (Lit 0)
```

---

# Putting it together: `quickCheck`

```haskell
data Config = Config
  { maxSuccess :: Int    -- target number of passing tests
  , maxDiscard :: Int    -- give up after this many discards
  , maxSize    :: Int    -- cap on the size parameter
  }

defaultConfig :: Config
defaultConfig = Config 100 500 100

quickCheck :: Testable prop => prop -> IO ()
quickCheck = quickCheckWith defaultConfig

quickCheckWith :: Testable prop => Config -> prop -> IO ()
quickCheckWith cfg prop = do
  g0 <- newStdGen
  loop 0 0 g0
  where
    gen = unProperty (property prop)

    loop passed discarded g
      | passed    >= maxSuccess cfg =
          putStrLn $ "+++ OK, passed " ++ show passed ++ " tests."
      | discarded >= maxDiscard cfg =
          putStrLn $ "*** Gave up after " ++ show discarded ++ " discards."
      | otherwise = do
          let (g1, g2) = split g
              n        = passed `mod` maxSize cfg + 1
              res      = unGen gen n g1
          case ok res of
            Nothing    -> loop passed       (discarded + 1) g2
            Just True  -> loop (passed + 1) discarded       g2
            Just False -> putStrLn $
              "*** Failed! " ++ unwords (reverse (inputs res))
              -- shrink-then-print is what the real implementation does here
```

Three details worth noticing:
- `split` separates the per-test seed from the seed used for the *next* test — independence.
- The **size grows** with the test counter (``passed `mod` maxSize``) — small inputs first, larger ones later.
- Shrinking happens between `Just False` and the printout (omitted above for clarity — see the previous slide).

---

# A worked example: the Calculator

Recall the AST and evaluator from Lecture 7's calculator:
```haskell
data Expr = Lit Int | Neg Expr | Add Expr Expr
          | Sub Expr Expr | Mul Expr Expr | Div Expr Expr
eval :: Expr -> Maybe Int
```
Three honest properties:
```haskell
prop_pretty_parse_roundtrip :: Expr -> Property
prop_pretty_parse_roundtrip e =
  parseExpr (pretty e) === Just e

prop_add_commutative :: Expr -> Expr -> Property
prop_add_commutative a b =
  eval (Add a b) === eval (Add b a)

prop_sub_is_add_neg :: Expr -> Expr -> Property
prop_sub_is_add_neg a b =
  eval (Sub a b) === eval (Add a (Neg b))
```
`===` is QuickCheck's *equal-and-show-both-sides-on-failure* operator.

Two properties that look right but **must be guarded carefully**:
```haskell
prop_div_left_inverse :: Expr -> Expr -> Property
prop_div_left_inverse a b =
  eval b /= Just 0 ==> eval (Mul (Div a b) b) === eval a

prop_int_overflow :: Expr -> Expr -> Property
prop_int_overflow a b =
  classify (eval (Mul a b) == Nothing) "overflow" $
    eval (Mul a b) === eval (Mul b a)
```

