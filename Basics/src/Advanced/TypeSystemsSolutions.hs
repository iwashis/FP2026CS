{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-missing-export-lists #-}

-- | Lecture 10 — worked solutions to the slide exercises, to be written
-- /live/ during the lecture. Everything here compiles; `demo` runs the
-- examples. Not wired into the executable — it is an instructor reference.
module Advanced.TypeSystemsSolutions where


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Exercise 1: add Div — and what the type system did NOT fix
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Adding the constructor and its eval case is trivial. The teaching point:
-- the GADT index guarantees Div receives two Int expressions (no `1 / True`),
-- but `eval` is STILL partial — division by zero throws at runtime. Unlike
-- the UExpr case, the *type error* is gone; the *value-level* partiality is
-- not, because the index `Int` cannot say "non-zero".

data E1 a where
  Lit1 :: Int -> E1 Int
  Add1 :: E1 Int -> E1 Int -> E1 Int
  Div1 :: E1 Int -> E1 Int -> E1 Int

eval1 :: E1 a -> a
eval1 (Lit1 n)   = n
eval1 (Add1 a b) = eval1 a + eval1 b
eval1 (Div1 a b) = eval1 a `div` eval1 b      -- crashes when (eval1 b == 0)

-- If we want totality back we must reintroduce `Maybe` — note the type index
-- gave us no help with this particular failure:
eval1safe :: E1 a -> Maybe a
eval1safe (Lit1 n)   = Just n
eval1safe (Add1 a b) = (+) <$> eval1safe a <*> eval1safe b
eval1safe (Div1 a b) = do
  x <- eval1safe a
  y <- eval1safe b
  if y == 0 then Nothing else Just (x `div` y)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Exercise 2: variables and a typed environment
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A plain `[(String, ???)]` environment cannot work: different variables have
-- different types, so the values can't share one element type. The fix is a
-- *typed de Bruijn index* — a pointer into the environment that carries, in
-- its own type, the type of the thing it points at.
--
-- The environment is a nested tuple of values; `Idx env a` is a typed pointer
-- into it. The lookup the exercise asks for is:
--
--     lookupVar :: Idx env a -> env -> a
--
-- i.e. the index determines the result type `a`.

data Idx env a where
  Zero :: Idx (a, env) a               -- points at the head
  Succ :: Idx env a -> Idx (b, env) a  -- skip the head, look deeper

data Expr env a where
  Lit  :: Int -> Expr env Int
  AddE :: Expr env Int -> Expr env Int -> Expr env Int
  Var  :: Idx env a -> Expr env a

lookupVar :: Idx env a -> env -> a
lookupVar Zero     (x, _)  = x
lookupVar (Succ i) (_, xs) = lookupVar i xs

evalE :: env -> Expr env a -> a
evalE _   (Lit n)    = n
evalE env (AddE a b) = evalE env a + evalE env b
evalE env (Var i)    = lookupVar i env

-- An environment holding an Int (position 0) and a Bool (position 1).
-- `Var Zero` has type Expr (Int,(Bool,())) Int; the Bool is reachable as
-- `Var (Succ Zero)` and would have type ... Bool.
exampleEnv :: (Int, (Bool, ()))
exampleEnv = (7, (True, ()))

-- evalE exampleEnv (AddE (Var Zero) (Lit 1))  ==>  8


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Exercise 3: a third door state, Locked
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Add the tag and the two new transitions. A Locked door must be unlocked
-- (to Closed) before it can be opened — the types make any other order a
-- compile error.

data Open
data Closed
data Locked

newtype Door state = Door String

newDoor    :: String      -> Door Closed
newDoor    = Door

openDoor   :: Door Closed -> Door Open
openDoor   (Door n) = Door n

closeDoor  :: Door Open    -> Door Closed
closeDoor  (Door n) = Door n

lockDoor   :: Door Closed  -> Door Locked
lockDoor   (Door n) = Door n

unlockDoor :: Door Locked  -> Door Closed
unlockDoor (Door n) = Door n

doorName :: Door state -> String
doorName (Door n) = n

-- openDoor (lockDoor (newDoor "vault"))            -- TYPE ERROR (Locked, not Closed)
-- openDoor (unlockDoor (lockDoor (newDoor "vault"))) -- ok


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Exercise 4: vappend — length is added at the type level
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The result length is `m + n`. To express it we need a *type family* that
-- adds two type-level Nats (TypeFamilies pragma) — addition is a function on
-- types, mirroring the value-level definition.

data Nat = Z | S Nat

data Vec (n :: Nat) a where
  VNil  :: Vec 'Z a
  VCons :: a -> Vec n a -> Vec ('S n) a

type family Add (m :: Nat) (n :: Nat) :: Nat where
  Add 'Z     n = n
  Add ('S m) n = 'S (Add m n)

vappend :: Vec m a -> Vec n a -> Vec (Add m n) a
vappend VNil         ys = ys
vappend (VCons x xs) ys = VCons x (vappend xs ys)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Exercise 5: vmap preserves the length index
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- `vmap` returns `Vec n b` for the SAME `n`. It is "obviously" length-
-- preserving because each VCons in the input becomes exactly one VCons in the
-- output, and VNil maps to VNil — so the structure (and hence the index) is
-- untouched. GHC sees it for the same reason: the recursive call returns
-- `Vec n' b` for the tail's length `n'`, and `VCons _ :: ... -> Vec ('S n') b`
-- rebuilds the same `'S n'` the input had.

vmap :: (a -> b) -> Vec n a -> Vec n b
vmap _ VNil         = VNil
vmap f (VCons x xs) = VCons (f x) (vmap f xs)

toList :: Vec n a -> [a]
toList VNil         = []
toList (VCons x xs) = x : toList xs

vec2 :: Vec ('S ('S 'Z)) Int
vec2 = VCons 1 (VCons 2 VNil)

vec3 :: Vec ('S ('S ('S 'Z))) Int
vec3 = VCons 3 (VCons 4 (VCons 5 VNil))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Run all the solutions
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

demo :: IO ()
demo = do
  putStrLn "-- Ex 1: Div (partial vs safe) --"
  print (eval1 (Div1 (Lit1 10) (Lit1 2)))         -- 5
  print (eval1safe (Div1 (Lit1 10) (Lit1 0)))     -- Nothing
  print (eval1safe (Add1 (Lit1 3) (Lit1 4)))      -- Just 7

  putStrLn "\n-- Ex 2: typed environment --"
  print (evalE exampleEnv (AddE (Var Zero) (Lit 1)))   -- 8

  putStrLn "\n-- Ex 3: door with Locked state --"
  putStrLn (doorName (openDoor (unlockDoor (lockDoor (newDoor "vault")))))

  putStrLn "\n-- Ex 4: vappend (length 2 ++ length 3 = length 5) --"
  print (toList (vappend vec2 vec3))              -- [1,2,3,4,5]

  putStrLn "\n-- Ex 5: vmap preserves length --"
  print (toList (vmap (* 10) vec3))               -- [30,40,50]
