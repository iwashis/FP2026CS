{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeFamilies #-}

-- | Lecture 10: Beyond algebraic data types — extending Haskell's type system.
--
-- So far every type we have written has been an /algebraic data type/ (ADT):
-- a sum of products, e.g.
--
-- > data Shape = Circle Double | Rect Double Double
--
-- ADTs are wonderfully expressive, but they have a blind spot. The type of a
-- constructor's /result/ is fixed — every constructor of @T a@ returns @T a@,
-- no matter what it contains. That means the type checker cannot use the
-- /shape/ of a value to rule out nonsense. This lecture removes that blind
-- spot with two extensions, plus a capstone:
--
--   * __Phantom types__ — a type parameter that appears only on the left of
--     the @=@. It carries a compile-time /tag/ that the runtime never sees.
--     Great for forbidding illegal API calls; powerless to /inspect/ the tag.
--
--   * __GADTs__ (Generalised Algebraic Data Types) — constructors are allowed
--     to /refine/ the result type. @IntLit :: Int -> Expr Int@ and
--     @BoolLit :: Bool -> Expr Bool@ live in the /same/ type @Expr@, yet a
--     pattern match /learns/ which one it found. This is exactly the power
--     phantom types lacked, and it buys us a total, type-safe interpreter.
--
--   * __DataKinds__ (capstone) — promote ordinary data to the /type/ level so
--     types can count. A length-indexed vector @Vec n a@ makes @head@ total
--     and forces @zipWith@ to receive two vectors of the same length.
--
-- Read the four sections top to bottom: each one is a strictly stronger answer
-- to the same question — /how much nonsense can the compiler reject for us?/
-- The final section, "Solutions to the exercises", works the three exercises
-- from the slides, reusing the definitions built up above.
--
-- __Language pragmas.__ Standard Haskell (the @Haskell2010@ this package
-- compiles with) is enough for ADTs and phantom types — they need /no/
-- extension. The others are off by default and must be switched on with a
-- @{-\# LANGUAGE ... \#-}@ pragma at the top of the file (see the four lines
-- above), or via @default-extensions@ in the @.cabal@ \/ @package.yaml@:
--
--   * @GADTs@         — the @data T a where ...@ syntax (sections 2, 3 and the
--                       exercise solutions).
--   * @DataKinds@     — promote @data Nat = Z | S Nat@ to a /kind/, so @'Z@
--                       and @'S@ can be used in types (section 3).
--   * @KindSignatures@— the @(n :: Nat)@ annotation on a type variable
--                       (section 3).
--   * @TypeFamilies@  — addition on type-level naturals, needed for @vappend@
--                       in the exercise solutions.
module Advanced.TypeSystems (main) where


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 0. Recap: the ADT we already know — and its blind spot
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Here is a tiny expression language as an ordinary ADT. It mixes integers
-- and booleans, so a single value can be nonsensical: @UAdd (UInt 1) (UBool
-- True)@ is a perfectly well-typed 'UExpr', even though "1 + True" is garbage.

data UExpr
  = UInt  Int
  | UBool Bool
  | UAdd  UExpr UExpr
  | UIf   UExpr UExpr UExpr
  deriving (Show)

-- Because the ADT cannot distinguish "expression producing an Int" from
-- "expression producing a Bool", evaluation must be partial: it returns a
-- /sum/ of the possible result types, and fails (Nothing) on type errors that
-- only show up at runtime.

data Val = VInt Int | VBool Bool
  deriving (Show)

evalU :: UExpr -> Maybe Val
evalU (UInt n)  = Just (VInt n)
evalU (UBool b) = Just (VBool b)
evalU (UAdd a b) = case (evalU a, evalU b) of
  (Just (VInt x), Just (VInt y)) -> Just (VInt (x + y))
  _                              -> Nothing          -- "1 + True" lands here
evalU (UIf c t e) = case evalU c of
  Just (VBool True)  -> evalU t
  Just (VBool False) -> evalU e
  _                  -> Nothing                      -- non-boolean condition

-- The lesson: with a plain ADT the /types do not stop us building nonsense/,
-- so we pay for it at runtime with 'Maybe' and a pile of impossible-looking
-- cases. The rest of the lecture pushes that check back to compile time.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. Extension 1: Phantom types
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A /phantom type/ is a type parameter that appears on the left of the @=@ but
-- in /none/ of the constructors on the right. It stores no data; it exists
-- purely so the type checker can track a tag.
--
-- No language pragma is needed here — phantom types are plain Haskell.
--
-- Model a door as a state machine. The state — Open or Closed — lives only in
-- the type. The two state tags are empty types: we never build a value of
-- them, we only mention them in types.

data Open
data Closed

newtype Door state = Door String      -- `state` is phantom: unused on the right

-- The smart constructors and operations encode the legal transitions. Read
-- the types: a fresh door is Closed; you may only open a Closed door, and only
-- close an Open one.

newDoor :: String -> Door Closed
newDoor = Door

openDoor :: Door Closed -> Door Open
openDoor (Door name) = Door name

closeDoor :: Door Open -> Door Closed
closeDoor (Door name) = Door name

doorName :: Door state -> String
doorName (Door name) = name


-- `openDoor (newDoor "front")`            -- ok: Closed -> Open
-- `closeDoor (openDoor (newDoor "front"))`-- ok: Closed -> Open -> Closed
--
-- `openDoor (openDoor (newDoor "front"))` -- TYPE ERROR, and that is the point:
--                                         -- the inner openDoor returns
--                                         -- Door Open, but openDoor wants
--                                         -- Door Closed. Illegal transitions
--                                         -- simply do not compile.
--
-- What phantom types CANNOT do: recover the tag by pattern matching. Every
-- door is just `Door name` at runtime — the state has been erased. We cannot
-- write `isOpen :: Door s -> Bool` by inspecting the value, because no
-- constructor mentions `s`. To make the constructors /carry/ that evidence we
-- need the next extension.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. Extension 2: GADTs
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Needs the @GADTs@ pragma (line 1). A GADT lets each constructor declare its
-- own result type. Compare:
--
--   ordinary ADT syntax      every constructor returns `Expr a` for the same a
--   --------------------     ----------------------------------------------
--   data Expr a = ...
--
--   GADT syntax              each constructor picks the `a` it returns
--   --------------------     ----------------------------------------------
--   data Expr a where
--     IntLit :: Int -> Expr Int
--
-- Now the type index `a` in `Expr a` is honest: it is the type the expression
-- evaluates to. An `Expr Int` can only be built from integer-producing pieces.

data Expr a where
  IntLit  :: Int  -> Expr Int
  BoolLit :: Bool -> Expr Bool
  Add     :: Expr Int  -> Expr Int  -> Expr Int
  Mul     :: Expr Int  -> Expr Int  -> Expr Int
  IsEq    :: Expr Int  -> Expr Int  -> Expr Bool
  And     :: Expr Bool -> Expr Bool -> Expr Bool
  If      :: Expr Bool -> Expr a    -> Expr a -> Expr a

-- The interpreter is now /total/ and /type-directed/: it returns exactly `a`,
-- never a `Maybe` and never a sum-of-values. There is no "type error" case to
-- handle because ill-typed expressions cannot be constructed in the first
-- place.

eval :: Expr a -> a
eval (IntLit n)  = n
eval (BoolLit b) = b
eval (Add a b)   = eval a + eval b
eval (Mul a b)   = eval a * eval b
eval (IsEq a b)  = eval a == eval b
eval (And a b)   = eval a && eval b
eval (If c t e)  = if eval c then eval t else eval e

-- Why does this type-check? When we match `Add a b`, GHC /learns/ from the
-- GADT that `a ~ Int` here, so `eval a + eval b` is adding two Ints and the
-- branch has type Int — which agrees with `Add :: ... -> Expr Int`. Each
-- branch refines the result type to match its constructor. The phantom-type
-- version could never do this: there, matching told us nothing about `a`.
--
-- And the nonsense from section 0 is now a /compile error/, not a runtime
-- Nothing:
--
--   Add (IntLit 1) (BoolLit True)   -- rejected: BoolLit True :: Expr Bool,
--                                   -- but Add wants Expr Int.

-- A small structural pretty-printer, total over the GADT:
pretty :: Expr a -> String
pretty (IntLit n)  = show n
pretty (BoolLit b) = show b
pretty (Add a b)   = "(" ++ pretty a ++ " + "  ++ pretty b ++ ")"
pretty (Mul a b)   = "(" ++ pretty a ++ " * "  ++ pretty b ++ ")"
pretty (IsEq a b)  = "(" ++ pretty a ++ " == " ++ pretty b ++ ")"
pretty (And a b)   = "(" ++ pretty a ++ " && " ++ pretty b ++ ")"
pretty (If c t e)  =
  "(if " ++ pretty c ++ " then " ++ pretty t ++ " else " ++ pretty e ++ ")"

-- Two sample programs. Their Haskell types tell us their result types ahead
-- of evaluation: `program` is an Expr Int, `predicate` is an Expr Bool.
program :: Expr Int
program = If (IsEq (Add (IntLit 1) (IntLit 2)) (IntLit 3))
             (Mul (IntLit 10) (IntLit 5))      -- taken when 1+2 == 3
             (IntLit 0)

predicate :: Expr Bool
predicate = And (IsEq (IntLit 4) (Mul (IntLit 2) (IntLit 2)))
                (BoolLit True)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2a. A caveat: what the GADT index does NOT fix
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- It is tempting to conclude that the honest index makes evaluation total in
-- every sense. It does not. The index rules out /type/ errors ("1 + True"),
-- but it says nothing about /values/. Add a division constructor and the
-- problem is plain: the index `Int` cannot express "non-zero", so division by
-- zero is still a runtime crash.

data E1 a where
  Lit1 :: Int -> E1 Int
  Add1 :: E1 Int -> E1 Int -> E1 Int
  Div1 :: E1 Int -> E1 Int -> E1 Int

eval1 :: E1 a -> a
eval1 (Lit1 n)   = n
eval1 (Add1 a b) = eval1 a + eval1 b
eval1 (Div1 a b) = eval1 a `div` eval1 b      -- crashes when (eval1 b == 0)

-- To recover totality we must reintroduce `Maybe` — note the type index gave
-- us no help with this particular failure. The lesson: GADTs move /type/
-- errors to compile time, but value-level partiality needs other tools.
eval1safe :: E1 a -> Maybe a
eval1safe (Lit1 n)   = Just n
eval1safe (Add1 a b) = (+) <$> eval1safe a <*> eval1safe b
eval1safe (Div1 a b) = do
  x <- eval1safe a
  y <- eval1safe b
  if y == 0 then Nothing else Just (x `div` y)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2b. Two more GADTs (still just the GADTs pragma)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- (i) A runtime type /witness/. This is the phantom idea with the evidence
-- put back in: matching the witness tells us, and the type checker, what `a`
-- is. The thing phantom types could not do, a GADT does directly.

data Ty a where
  TInt  :: Ty Int
  TBool :: Ty Bool

defaultVal :: Ty a -> a
defaultVal TInt  = 0          -- in this branch a ~ Int
defaultVal TBool = False      -- in this branch a ~ Bool

render :: Ty a -> a -> String
render TInt  n = "int: "  ++ show n
render TBool b = "bool: " ++ show b

-- (ii) Type-safe @printf@: the format descriptor's /type/ computes the arity
-- of the function @printf@ returns. @FInt@ adds an @Int@ argument, @FStr@ a
-- @String@ one — so the descriptor below has type @Fmt (String -> Int -> String)@.

data Fmt a where
  FEnd :: Fmt String
  FLit :: String -> Fmt a -> Fmt a
  FInt :: Fmt a -> Fmt (Int -> a)
  FStr :: Fmt a -> Fmt (String -> a)

printf :: Fmt a -> a
printf fmt = go fmt ""
  where
    go :: Fmt a -> String -> a       -- polymorphic recursion: signature required
    go FEnd       acc = acc
    go (FLit s k) acc = go k (acc ++ s)
    go (FInt k)   acc = \n -> go k (acc ++ show n)
    go (FStr k)   acc = \s -> go k (acc ++ s)

greet :: String -> Int -> String
greet = printf (FLit "Hello " (FStr (FLit ", you are " (FInt FEnd))))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. Capstone: DataKinds — types that count
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Needs three pragmas (line 1-3): @GADTs@ for the @Vec@ syntax, @DataKinds@ to
-- promote @Nat@ to a kind, and @KindSignatures@ for the @(n :: Nat)@ below.
--
-- GADTs let constructors refine a /type/. DataKinds goes one level up: it
-- /promotes/ ordinary data to the type level, so we can index a type by a
-- value-like thing. Promote the natural numbers:

data Nat = Z | S Nat        -- with DataKinds this also defines the KIND `Nat`
                            -- with type-level values 'Z and 'S.

-- A length-indexed vector: `Vec n a` is a list of exactly `n` elements. The
-- length is tracked in the type via the promoted naturals.

data Vec (n :: Nat) a where
  VNil  :: Vec 'Z a                       -- empty vector has length zero
  VCons :: a -> Vec n a -> Vec ('S n) a   -- consing adds one to the length

-- `vhead` is TOTAL: its type demands a vector of length `S n` (at least one
-- element), so the empty case is impossible and GHC does not even ask for it.

vhead :: Vec ('S n) a -> a
vhead (VCons x _) = x

-- `vzipWith` can only be called on two vectors of the SAME length `n`. Mixing
-- a length-2 and a length-3 vector is a compile error, not a runtime crash.

vzipWith :: (a -> b -> c) -> Vec n a -> Vec n b -> Vec n c
vzipWith _ VNil         VNil         = VNil
vzipWith f (VCons x xs) (VCons y ys) = VCons (f x y) (vzipWith f xs ys)

-- `vmap` returns `Vec n b` for the SAME `n`: it is "obviously" length-
-- preserving because each VCons in the input becomes exactly one VCons in the
-- output, and VNil maps to VNil. GHC sees it for the same reason — the
-- recursive call returns `Vec n' b` for the tail's length `n'`, and
-- `VCons _ :: ... -> Vec ('S n') b` rebuilds the same `'S n'` the input had.

vmap :: (a -> b) -> Vec n a -> Vec n b
vmap _ VNil         = VNil
vmap f (VCons x xs) = VCons (f x) (vmap f xs)

-- A way back to an ordinary list, so we can print results.
toList :: Vec n a -> [a]
toList VNil         = []
toList (VCons x xs) = x : toList xs

-- Two length-3 vectors. Try giving them different lengths and watch the
-- vzipWith call below stop compiling.
vec1 :: Vec ('S ('S ('S 'Z))) Int
vec1 = VCons 1 (VCons 2 (VCons 3 VNil))

vec2 :: Vec ('S ('S ('S 'Z))) Int
vec2 = VCons 10 (VCons 20 (VCons 30 VNil))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Solutions to the exercises
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The three exercises from the slides, worked out using the machinery above.
-- They are independent of the runnable tour and serve as a reference.


-- Exercise 1: variables and a typed environment
-- ---------------------------------------------
-- A plain `[(String, ???)]` environment cannot work: different variables have
-- different types, so the values can't share one element type. The fix is a
-- /typed de Bruijn index/ — a pointer into the environment that carries, in
-- its own type, the type of the thing it points at.
--
-- The environment is a nested tuple of values; `Idx env a` is a typed pointer
-- into it, and `lookupVar :: Idx env a -> env -> a` lets the index determine
-- the result type `a`. (We call the expression type `TExpr` here so it does
-- not clash with the `Expr` from section 2.)

data Idx env a where
  Zero :: Idx (a, env) a               -- points at the head
  Succ :: Idx env a -> Idx (b, env) a  -- skip the head, look deeper

data TExpr env a where
  Lit  :: Int -> TExpr env Int
  AddE :: TExpr env Int -> TExpr env Int -> TExpr env Int
  Var  :: Idx env a -> TExpr env a

lookupVar :: Idx env a -> env -> a
lookupVar Zero     (x, _)  = x
lookupVar (Succ i) (_, xs) = lookupVar i xs

evalE :: env -> TExpr env a -> a
evalE _   (Lit n)    = n
evalE env (AddE a b) = evalE env a + evalE env b
evalE env (Var i)    = lookupVar i env

-- An environment holding an Int (position 0) and a Bool (position 1).
-- `Var Zero` has type TExpr (Int,(Bool,())) Int; the Bool is reachable as
-- `Var (Succ Zero)` and would have type ... Bool.
exampleEnv :: (Int, (Bool, ()))
exampleEnv = (7, (True, ()))

-- evalE exampleEnv (AddE (Var Zero) (Lit 1))  ==>  8


-- Exercise 2: a third door state, Locked
-- --------------------------------------
-- Reuse the `Door` from section 1; we only need a new tag and the two new
-- transitions. A Locked door must be unlocked (to Closed) before it can be
-- opened — the types make any other order a compile error.

data Locked

lockDoor :: Door Closed -> Door Locked
lockDoor (Door n) = Door n

unlockDoor :: Door Locked -> Door Closed
unlockDoor (Door n) = Door n

-- openDoor (lockDoor (newDoor "vault"))               -- TYPE ERROR (Locked, not Closed)
-- openDoor (unlockDoor (lockDoor (newDoor "vault")))  -- ok


-- Exercise 3: vappend — length is added at the type level
-- -------------------------------------------------------
-- Reuse the `Vec` from section 3. The result length is `m + n`. To express it
-- we need a /type family/ that adds two type-level Nats (TypeFamilies pragma)
-- — addition is a function on types, mirroring the value-level definition.

type family Add (m :: Nat) (n :: Nat) :: Nat where
  Add 'Z     n = n
  Add ('S m) n = 'S (Add m n)

vappend :: Vec m a -> Vec n a -> Vec (Add m n) a
vappend VNil         ys = ys
vappend (VCons x xs) ys = VCons x (vappend xs ys)

-- A length-2 vector to append in front of the length-3 `vec1` above.
vec2of :: Vec ('S ('S 'Z)) Int
vec2of = VCons 4 (VCons 5 VNil)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A runnable tour
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main :: IO ()
main = do
  putStrLn "=== Lecture 10: Beyond ADTs — Extending the Type System ==="

  putStrLn "\n-- 0. Plain ADT: evaluation is partial --"
  print (evalU (UAdd (UInt 1) (UInt 2)))            -- Just (VInt 3)
  print (evalU (UIf (UBool True) (UInt 7) (UInt 0)))-- Just (VInt 7)
  print (evalU (UAdd (UInt 1) (UBool True)))        -- Nothing: nonsense slips
                                                    -- through the ADT, fails
                                                    -- only at runtime

  putStrLn "\n-- 1. Phantom types: a Door state machine --"
  let d0 = newDoor "front"          -- Door Closed
      d1 = openDoor d0              -- Door Open
      d2 = closeDoor d1             -- Door Closed
  putStrLn ("door is named: " ++ doorName d2)
  putStrLn "(openDoor (openDoor d0) would not compile — illegal transition)"

  putStrLn "\n-- 2. GADTs: a total, type-safe interpreter --"
  putStrLn (pretty program   ++ "  ==>  " ++ show (eval program))
  putStrLn (pretty predicate ++ "  ==>  " ++ show (eval predicate))
  putStrLn "(Add (IntLit 1) (BoolLit True) would not compile — wrong index)"

  putStrLn "\n-- 2a. The index fixes type errors, not value-level partiality --"
  print (eval1 (Div1 (Lit1 10) (Lit1 2)))           -- 5
  print (eval1safe (Div1 (Lit1 10) (Lit1 0)))       -- Nothing: div-by-zero
  print (eval1safe (Add1 (Lit1 3) (Lit1 4)))        -- Just 7

  putStrLn "\n-- 2b. A runtime type witness (Ty a) --"
  putStrLn (render TInt  (defaultVal TInt))         -- int: 0
  putStrLn (render TBool (defaultVal TBool))        -- bool: False

  putStrLn "\n-- 2b. Type-safe printf (the format computes the arity) --"
  putStrLn (greet "Ada" 36)                         -- Hello Ada, you are 36

  putStrLn "\n-- 3. DataKinds: length is tracked in the type --"
  print (toList vec1)                               -- [1,2,3]
  print (vhead vec1)                                -- 1 (head is total)
  print (toList (vzipWith (+) vec1 vec2))           -- [11,22,33]
  print (toList (vmap (* 10) vec1))                 -- [10,20,30]
  putStrLn "(vzipWith on different-length vectors would not compile)"

  putStrLn "\n-- Solutions to the exercises --"
  print (evalE exampleEnv (AddE (Var Zero) (Lit 1)))         -- Ex 1: 8
  putStrLn (doorName (openDoor (unlockDoor (lockDoor (newDoor "vault")))))
                                                            -- Ex 2: "vault"
  print (toList (vappend vec2of vec1))                       -- Ex 3: [4,5,1,2,3]
