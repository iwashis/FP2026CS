{-# LANGUAGE DeriveFunctor #-}
module Lecture04 where
import qualified Data.Map as Map
import Control.Monad
--
-- ==========================================
--  Lecture 4: Applicative Functors & Monads
-- ==========================================
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 0. Not every parameterised type is a Functor
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Recall: class Functor f where
--           fmap :: (a -> b) -> f a -> f b
--
-- A Functor lets you transform the value "inside" a context.
-- But this only works when the parameter appears in *output*
-- (covariant) position.
--
-- Counter-example: a predicate *consumes* an `a` rather than
-- producing one, so it cannot be a Functor.

newtype Predicate a = Predicate (a -> Bool)
    
-- If we try to write fmap for Predicate:
--   fmap :: (a -> b) -> Predicate a -> Predicate b
--   fmap f (Predicate p) = Predicate (\b -> ???)
--
-- We have:
--   f :: a -> b
--   p :: a -> Bool
--   b :: b
--
-- We need a (b -> Bool), but we can only go from a to b,
-- not from b to a.  There is no way to feed `b` to `p`.
--
-- Rule of thumb: if the type parameter appears to the *left*
-- of an arrow (input position), you cannot write a lawful fmap.
-- (Such types are called *contravariant*.)

isEven :: Predicate Int
isEven = Predicate even


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. Applicative Functors
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Before we get to monads, we need to understand applicative functors,
-- which are an important intermediate link in the type hierarchy.
--
-- class Functor f => Applicative f where
--   pure  :: a -> f a
--   (<*>) :: f (a -> b) -> f a -> f b
--
-- An applicative functor extends a regular functor with two operations:
--   pure  - places a value into a context (similar to return in monads)
--   (<*>) - applies a function in a context to a value in a context
--
-- Applicative laws:
--   pure id <*> v = v                            -- identity
--   pure (.) <*> u <*> v <*> w = u <*> (v <*> w) -- composition
--   pure f <*> pure x = pure (f x)               -- homomorphism
--   u <*> pure y = pure ($ y) <*> u               -- interchange


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1a. Maybe as Applicative
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

data Maybe' a = Just' a | Nothing'
    deriving (Show, Functor)


instance Applicative Maybe' where
  -- pure :: a -> Maybe' a  
  pure = Just' 
  -- (<*>) :: Maybe' ( a-> b) -> Maybe' a -> Maybe' b
  Nothing' <*> _ = Nothing' 
  Just' f <*> Nothing' = Nothing'
  Just' f <*> (Just' x)= Just' (f x)

-- Example: Just' (+3) <*> Just' 5             = Just' 8
-- Example: Just' (*) <*> Just' 5 <*> Just' 3  = Just' 15
-- Example: Nothing' <*> Just' 5               = Nothing'


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1c. Applicative in practice: liftA2
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
-- liftA2 f x y = fmap f  (x <*> y)

data User = User String Int
    deriving (Show)
createUser :: String -> Int -> User
createUser = User

maybeCreate:: Maybe' String -> Maybe' Int -> Maybe' User
maybeCreate Nothing' _ = Nothing'
maybeCreate (Just' name) Nothing' = Nothing'
maybeCreate (Just' name) (Just' age) = Just' (User name age) 

-- Use liftA2 to create a user from Maybe values.
-- Example: maybeCreateUser (Just "Jan") (Just 30) = Just (User "Jan" 30)
-- Example: maybeCreateUser Nothing (Just 30)      = Nothing
--
maybeCreate' :: Maybe' String -> Maybe' Int -> Maybe' User
maybeCreate' = liftA2 createUser


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1d. Exercise: Applicative instance for lists
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- A type isomorphic to [a].
data MyList a = Nil | NonEmptyList a (MyList a)
    deriving (Show, Functor)

concat' :: MyList a -> MyList a -> MyList a
concat' Nil list = list
concat' (NonEmptyList x tail) list = NonEmptyList x (concat' tail list) 

instance Applicative MyList where
  pure x = NonEmptyList x Nil
  -- <*> :: MyList (a -> b) -> MyList a -> MyList b
  Nil <*> _ = Nil 
  (NonEmptyList f fs) <*> list =  concat' (fmap f list) (fs <*> list)


-- List Applicative — all combinations:
--
-- sizes  = ["S", "M", "L"]
-- colors = ["red", "blue"]
--
-- ghci> (,) <$> sizes <*> colors
-- [("S","red"),("S","blue"),("M","red"),("M","blue"),("L","red"),("L","blue")]
--
-- Useful for generating test cases, board game moves, brute-force search, …

sizes :: [String]
sizes = ["S", "M", "L"]

colors :: [String]
colors = ["red", "blue"]

allCombinations :: [(String, String)]
allCombinations = liftA2 (,) sizes colors

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- *. A Functor that is NOT Applicative
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Not every Functor can be made Applicative.
-- You already know Map k from this lecture — it is a Functor:
--
--   fmap f m = Map.map f m     -- apply f to every value
--
-- Can we write pure?
--   pure :: a -> Map k a
--   pure x = ???   -- a Map that maps *every possible key* to x?
--
-- A Map is finite, but the key space may be infinite (e.g. Map Int a).
-- There is no way to build a map that contains *all* keys.
-- So pure cannot be implemented.
--
-- What about (<*>)?
--   (<*>) :: Map k (a -> b) -> Map k a -> Map k b
--   We could intersect keys and apply — but without a lawful pure,
--   the applicative laws break down.
--
-- Lesson: pure demands the ability to create a context from nothing.
-- A finite Map cannot represent "a value everywhere",
-- so it cannot be Applicative.




-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. Monads — the problem first
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Suppose we want to chain several operations that can each fail.
-- Without any abstraction we get deeply nested case expressions:

users :: Map.Map Int String
users = Map.fromList [(1, "alice"), (2, "bob")]

emails :: Map.Map String String
emails = Map.fromList [("alice", "alice@example.com")]

-- The ugly nested-case version:
lookupEmailUgly :: Int -> Maybe String
lookupEmailUgly uid =
  case Map.lookup uid users of
    Nothing   -> Nothing
    Just name -> case Map.lookup name emails of
                   Nothing    -> Nothing
                   Just email -> Just email

-- Every step must manually check for failure. This does not scale.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. The Maybe Monad
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The Maybe monad instance lets us chain fallible steps without manual checking:
--
-- data Maybe' a = Just' a | Nothing' deriving (Show, Functor, Applicative)

instance Monad Maybe' where
  -- return = pure 
  Nothing' >>= _ = Nothing' 
  (Just' x )>>= f = f x 

-- (>>=) (bind): if the left side is Nothing, stop and return Nothing;
-- otherwise, feed the value inside Just to the next step.
-- return: wrap a plain value into Just.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3a. Safe division — chaining without crashing
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)

-- ghci> safeDiv 100 10 >>= safeDiv 5   -- Just 2
-- ghci> safeDiv 100 0  >>= safeDiv 5   -- Nothing


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3b. Dictionary lookup chain — revisited
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Clean version using >>=:
lookupEmail :: Int -> Maybe String
lookupEmail uid = Map.lookup uid users >>= \name -> Map.lookup name emails

-- ghci> lookupEmail 1   -- Just "alice@example.com"
-- ghci> lookupEmail 2   -- Nothing  (bob has no email)
-- ghci> lookupEmail 99  -- Nothing  (unknown user)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3c. Safe head and tail
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The functions head and tail in Haskell are partial.
-- We can make them safe:

head' :: [a] -> Maybe a
head' []    = Nothing
head' (x:_) = Just x

tail' :: [a] -> Maybe [a]
tail' []     = Nothing
tail' (_:xs) = Just xs

-- Exercise: using head' and tail', write a function that returns
-- the 3rd element of a list.
-- Example: third [1,2,3,4] = Just 3
-- Example: third [1,2]     = Nothing
--
-- third :: [a] -> Maybe a


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4. Monads — the general pattern
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A monad is a functor m with two operations:
--   (>>=)  :: m a -> (a -> m b) -> m b   -- chain a computation into the next step
--   return ::   a -> m a                  -- wrap a plain value, no effects
--
-- Think of m a as "a computation that produces an a"
-- (possibly with failure, non-determinism, I/O, …).
--
-- Monad laws:
--   return x >>= f         = f x                       -- left identity
--   m >>= return           = m                         -- right identity
--   (m >>= f) >>= g        = m >>= (\x -> f x >>= g)  -- associativity



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4a. Composing monadic functions
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A monadic function has type a -> m b.
-- Two such functions can be composed with the fish operator:
--   (>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c
--   f >=> g = \x -> f x >>= g
--
-- Relationship between >=> and >>=:
--   f >=> g     = \x -> ( f x >>= g )
--   x >>= g     = (const x >=> g) ()

-- The ugly lookupEmailUgly from section 2 rewritten with >=>:
lookupNice :: Int -> Maybe String
lookupNice x = ((\uid -> Map.lookup uid users) >=> (\name -> Map.lookup name emails)) x


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 5. Do Notation
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Chaining many >>= calls with lambdas gets noisy.
-- Haskell provides do notation as syntactic sugar:

-- With >>=:
--
f emails name = Map.lookup name emails

lookupEmail' :: Int -> Maybe String
lookupEmail' uid =
  Map.lookup uid users >>= f emails

-- With do notation:
lookupEmailDo :: Int -> Maybe String
lookupEmailDo uid = do
  name  <- Map.lookup uid users 
  (do 
    email <- Map.lookup name emails
    return email)

-- Another version (cf. lookupEmailUgly from section 2):
lookupVeryNice :: Int -> Maybe String
lookupVeryNice i = do
  name <- Map.lookup i users
  email <- Map.lookup name emails
  return email

-- Each "x <- action" is just "action >>= \x -> …" in disguise.
-- The compiler desugars do notation into >>= chains automatically.
--
-- Do notation desugaring rules:
--   do { x <- m ; rest }  =  m >>= \x -> do { rest }
--   do { m ; rest }        =  m >>  do { rest }
--   do { return x }        =  return x
--
-- (>>) is just >>= that discards the result:
--   (>>) :: Monad m => m a -> m b -> m b
--   m >> k = m >>= \_ -> k


--   ...
