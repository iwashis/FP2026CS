{-# LANGUAGE ScopedTypeVariables #-}
module Tutorials05 where

-- You may need to add `mtl` (and `transformers`) to the package dependencies
-- in order to use the modules below.
import Control.Monad.State
import Control.Monad.Trans.Maybe
import Data.Char (isDigit)

-- # State Monad, IO Monad, and Monad Transformers
--
-- 1. **State Monad for tracking state**
--
--    Define a function `runningSum :: [Int] -> [Int]` that, given a list of integers,
--    returns a list of partial sums. For example, for the list `[1, 2, 3, 4]` the result
--    should be `[1, 3, 6, 10]`. Implement this function using the State monad, making use
--    of `get`, `put`, and `runState` or `evalState`.

type RunningSum a = State ([Int], Int) a

runningSumHelper :: [Int] -> RunningSum [Int]
runningSumHelper []     = gets fst
runningSumHelper (x:xs) = do
  (acc, total) <- get
  let total' = total + x
  put (acc ++ [total'], total')
  runningSumHelper xs

runningSum :: [Int] -> [Int]
runningSum xs = evalState (runningSumHelper xs) ([], 0)


-- 2. **A pseudo-random number generation using State monad**
--
--    Implement a simple pseudo-random number generator using the State monad. Define a
--    function `randomInt :: Int -> Int -> State Int Int` that generates an integer in the
--    given range `[a, b]`, using a linear congruential generator
--    (https://en.wikipedia.org/wiki/Linear_congruential_generator).
--    Then write a function `randomList :: Int -> Int -> Int -> State Int [Int]` that
--    generates a list of `n` random numbers from the range `[a, b]`. Use `evalState` to
--    run the computation with a given seed.
--      lcg a c m seed = (\x -> (a * x + c) `mod` m)
--      Common parameters (e.g., glibc): a = 1103515245, c = 12345, m = 2^31.

type Random a = State Int a

randomInt :: Int -> Int -> Random Int
randomInt lo hi = do
  let a = 1103515245
      c = 12345
      m = 2 ^ (31 :: Int)
  seed <- get
  let seed' = (a * seed + c) `mod` m
  put seed'
  return $ lo + seed' `mod` (hi - lo)

randomList :: Int -> Int -> Int -> Random [Int]
randomList 0 _  _  = return []
randomList n lo hi = do
  x  <- randomInt lo hi
  xs <- randomList (n - 1) lo hi
  return (x : xs)


-- 3. **Binary tree and labelling with State**
--
--    Define a binary tree type `data Tree a = Empty | Node a (Tree a) (Tree a)`. Then
--    implement a function `labelTree :: Tree a -> State Int (Tree (a, Int))` that labels
--    each node of the tree with a unique number, using the State monad to track the
--    counter. The numbering should be in preorder. Also write a function
--    `countNodes :: Tree a -> State (Sum Int) (Tree a)` that counts the nodes in the
--    tree, using the State monad for accumulation.

data Tree a = Empty | Node a (Tree a) (Tree a) deriving Show

labelTree :: Tree a -> State Int (Tree (a, Int))
labelTree Empty          = return Empty
labelTree (Node x l r) = do
  label <- get
  put (label + 1)
  l' <- labelTree l
  r' <- labelTree r
  return $ Node (x, label) l' r'

countNodes :: Tree a -> State Int Int
countNodes Empty          = get
countNodes (Node _ l r) = do
  modify (+ 1)
  _ <- countNodes l
  countNodes r


-- 4. **Interactive calculation using IO**
--
--    Write a program `calculator :: IO ()` that reads two numbers and an operation (addition, subtraction,
--    multiplication, division) from the user and prints the result. The program should handle errors
--    (e.g. division by zero) and ask the user whether they want to continue. Use `getLine`, `readLn`,
--    and `putStrLn` to interact with the user.

calculator :: IO ()
calculator = do
  x :: Int <- readLn
  putStrLn "Choose operation add/multiply:"
  op <- getLine
  y :: Int <- readLn
  print $ translateOp op x y
  where
    translateOp :: String -> (Int -> Int -> Int)
    translateOp "add"      = (+)
    translateOp "multiply" = (*)
    translateOp _          = error "unknown operation"


-- 5. **A safer calculator with MaybeT**
--
--    The `calculator :: IO ()` from task 4 uses `readLn :: IO Int`, which throws a runtime exception
--    whenever the user types something that is not a valid integer (e.g. `"abc"` or an empty line).
--    Rewrite the calculator using the `MaybeT` transformer from `Control.Monad.Trans.Maybe`
--    so that bad input is reported as `Nothing` instead of crashing the program.
--
--    * Define a helper `readInt :: MaybeT IO Int` that reads a line from standard input and
--      produces `Nothing` when the line is not a valid integer (use `readMaybe` from `Text.Read`,
--      or check the input by hand with `Data.Char.isDigit`).
--    * Define a helper `readOp :: MaybeT IO (Int -> Int -> Int)` that reads an operation name
--      (e.g. `"sum"`, `"difference"`, `"product"`) and returns the corresponding function, or
--      `Nothing` if the name is not recognised.
--    * Implement `goodCalculator :: MaybeT IO ()` that reads two integers and an operation
--      using the helpers above and prints the result.

type ErrorIO = MaybeT IO

readInt :: ErrorIO Int
readInt = do
  line <- lift getLine
  if not (null line) && all isDigit line
    then pure (read line)
    else hoistMaybe Nothing

readOperation :: ErrorIO (Int -> Int -> Int)
readOperation = do
  line <- lift getLine
  case line of
    "add"      -> pure (+)
    "multiply" -> pure (*)
    _          -> hoistMaybe Nothing

goodCalculatorErrorIO :: ErrorIO ()
goodCalculatorErrorIO = do
  x  <- readInt
  op <- readOperation
  y  <- readInt
  lift $ print (op x y)

goodCalculator :: IO ()
goodCalculator = do
  _ <- runMaybeT goodCalculatorErrorIO
  pure ()


-- 6. **StateT — state on top of another monad**
--
--    Recall `State s a ≅ s -> (a, s)`. Wrapping the result in an
--    arbitrary monad `m` gives the state monad transformer:

newtype StateT' s m a = StateT' { runStateT' :: s -> m (a, s) }

--    A value of type `StateT s m a` is a stateful step whose result lives in `m`.
--
--    **(a) The `Functor`/`Applicative`/`Monad` instances.**

instance Functor m => Functor (StateT' s m) where
  -- fmap :: (a -> b) -> StateT' s m a -> StateT' s m b
  fmap f (StateT' pf) =
    StateT' $ fmap (\(x, s) -> (f x, s)) . pf

instance Monad m => Applicative (StateT' s m) where
  -- pure :: a -> StateT' s m a
  pure x = StateT' $ \s -> pure (x, s)
  -- (<*>) :: StateT' s m (a -> b) -> StateT' s m a -> StateT' s m b
  --
  -- We need `Monad m` (not just `Applicative m`): the new state `s'`
  -- produced by the first action lives *inside* `m`, and only `>>=`
  -- can pull it out to feed the second action.
  StateT' mf <*> StateT' ma = StateT' $ \s ->
    mf s  >>= \(f, s')  ->
    ma s' >>= \(x, s'') ->
    pure (f x, s'')

instance Monad m => Monad (StateT' s m) where
  return = pure
  StateT' g >>= f = StateT' $ \s -> do
    (x, s') <- g s
    runStateT' (f x) s'

--    **(b) The `MonadTrans` instance.**

instance MonadTrans (StateT' s) where
  -- lift :: m a -> StateT' s m a
  lift ma = StateT' $ \s -> do
    x <- ma
    pure (x, s)


-- 7. **Combining StateT and IO**
--
--    Implement a simple ATM simulator using the StateT transformer. Define a type `BankState`
--    containing the account balance. Write the following functions:
--    * `withdraw :: Int -> StateT BankState IO Bool` — attempts to withdraw a given amount
--    * `deposit  :: Int -> StateT BankState IO ()`   — deposits a given amount
--    * `checkBalance :: StateT BankState IO Int`     — checks the current balance
--    * `atmSession  :: StateT BankState IO ()`       — runs an interactive session with the user
--
--    Each operation should print appropriate messages on the screen and update the account state.

newtype BankState = BankState { portfolio :: Int } deriving (Show, Eq, Ord)

withdraw :: Int -> StateT BankState IO Bool
withdraw amount = do
  BankState current <- get
  let new = current - amount
  if new >= 0
    then do
      put (BankState new)
      lift $ putStrLn "Withdrawal complete"
      return True
    else do
      lift $ putStrLn "Error: insufficient funds"
      return False

deposit :: Int -> StateT BankState IO ()
deposit amount = do
  BankState current <- get
  put (BankState (current + amount))
  lift $ putStrLn $ "Deposit of " ++ show amount ++ " done."

atmSession :: StateT BankState IO ()
atmSession = do
  lift $ putStrLn "(d) Deposit, (w) Withdraw"
  c <- lift getChar
  case c of
    'd' -> do
      lift $ putStrLn "Enter amount to deposit"
      amount <- lift (readLn :: IO Int)
      deposit amount
      atmSession
    'w' -> do
      lift $ putStrLn "Enter amount to withdraw"
      amount <- lift (readLn :: IO Int)
      _ <- withdraw amount
      atmSession
    _   -> atmSession


-- 8. **Implementing a stack of transformers**
--
--    Define a type `AppM a = ReaderT Config (StateT AppState (ExceptT AppError IO)) a`, where:
--    * `Config` contains configuration parameters (e.g. `maxAttempts :: Int`)
--    * `AppState` contains the application state (e.g. `counter :: Int`, `lastOperation :: String`)
--    * `AppError` is a type representing possible errors (e.g. `NetworkError String`, `ValidationError String`)
--
--    Then implement the following helper functions:
--    * `getConfig    :: AppM Config`                       — retrieves the configuration
--    * `getState     :: AppM AppState`                     — retrieves the state
--    * `modifyState  :: (AppState -> AppState) -> AppM ()` — modifies the state
--    * `throwAppError :: AppError -> AppM a`               — raises an error
--    * `runApp :: Config -> AppState -> AppM a -> IO (Either AppError (a, AppState))` — runs the computation
--
--    Finally, implement an example business function `processTransaction :: Transaction -> AppM Result`
--    that uses the helper functions above.

main :: IO ()
main = do
  putStrLn "=== Tutorials 05 ==="
  print $ evalState (runningSumHelper [1, 2, 3, 4]) ([], 0)
  print $ evalState (randomInt 4 10) 44
  print $ evalState (randomList 5 1 100) 2
  print $ evalState (labelTree exampleTree) 0
  print $ evalState (countNodes exampleTree) 0
  -- calculator
  where
    exampleTree = Node 'a' (Node 'b' Empty Empty) (Node 'c' Empty Empty)
