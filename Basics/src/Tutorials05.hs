{-# LANGUAGE ScopedTypeVariables #-}
module Tutorials05 where

-- You may need to add `mtl` (and `transformers`) to the package dependencies
-- in order to use the modules below.
import Control.Monad.State
import Control.Monad.Trans.Maybe
import Data.Char
-- import Control.Monad.Reader
-- import Control.Monad.Except
-- import Control.Monad.Trans.Class (lift)

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
runningSumHelper [] = gets fst 
runningSumHelper (x:xs) = do
  (list,value) <- get 
  put (list ++ [value + x] , value + x)
  runningSumHelper xs

runningSum :: [Int] -> [Int]
runningSum list = evalState (runningSumHelper list) ([],0)  


-- 2. **A pseudo-random number generation using State monad**
--
--    Implement a simple pseudo-random number generator using the State monad. Define a
--    function `randomInt :: Int -> Int -> State Int Int` that generates an integer in the
--    given range `[a, b]`, using a linear congruential generator
--    (https://en.wikipedia.org/wiki/Linear_congruential_generator).
--    Then write a function `randomList :: Int -> Int -> Int -> State Int [Int]` that
--    generates a list of `n` random numbers from the range `[a, b]`. Use `evalState` to
--    run the computation with a given seed.
  -- lcg a c m seed = (\x -> (a * x + c) `mod` m) 
  -- Common parameters (e.g., glibc): a = 1103515245, c = 12345, m = 2^31.

type Random a = State Int a

randomInt :: Int -> Int -> Random Int
randomInt x y = do
  let a = 1103515245
      c = 12345
      m  = 2^(31 :: Int)
  seed0 <- get 
  let seed1 = (a * seed0 + c) `mod` m
  put seed1
  return $ x + seed1 `mod` (y -x)

randomList :: Int -> Int -> Int -> Random [Int]
randomList 0 a b = return [] 
randomList n a b = do
  x <- randomInt a b
  xs <- randomList (n-1) a b
  pure $ x:xs
 
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
labelTree Empty = return Empty 
labelTree (Node x left right) = do
  label <- get 
  put $ label + 1
  leftLabelledTree <- labelTree left
  rightLabelledTree <- labelTree right
  return $ Node (x,label) leftLabelledTree rightLabelledTree 

countNodes :: Tree a -> State Int Int
countNodes Empty  = get
countNodes (Node _ left right) = do
 modify (+1)
 countNodes left
 countNodes right

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
  operation <- getLine
  y :: Int <- readLn 
  print $ (translateOp operation) x y   
  where 
    translateOp :: String -> (Int -> Int -> Int)
    translateOp "add" = (+)
    translateOp "multiply" = (*)

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
  if all isDigit line then 
    pure (read line :: Int)
    else hoistMaybe Nothing 

readOperation :: ErrorIO (Int -> Int -> Int) 
readOperation = do 
  line <- lift getLine
  case line of 
    "add" -> pure (+) 
    "multiply" -> pure (*) 
    _ -> hoistMaybe Nothing


goodCalculatorErrorIO :: ErrorIO ()
goodCalculatorErrorIO = do
  x <- readInt 
  operation <- readOperation
  y <- readInt
  lift $ print (operation x y)

goodCalculator :: IO ()
goodCalculator = do 
  _ <- runMaybeT goodCalculatorErrorIO
  pure ()


-- 6. **StateT — state on top of another monad**
--
--    Recall `State s a ≅ s -> (a, s)`. Wrapping the result in an 
--    arbitrary monad `m` gives the state monad transformer:
--
--    ```haskell
--    newtype StateT s m a = StateT { runStateT :: s -> m (a, s) }
--    ```
--    A value of type `StateT s m a` is a stateful step whose result lives in `m`.
--
--    **(a) The `Monad` instance.** Complete the following definition:
--
--    ```haskell
--    instance Monad m => Monad (StateT s m) where
--      return a          = StateT $ \s -> ???
--      (StateT g) >>= f  = StateT $ \s -> ???
--    ```
--
--    **(b) The `MonadTrans` instance.** Complete the lifting operation:
--
--    ```haskell
--    instance MonadTrans (StateT s) where
--      lift ma = StateT $ \s -> ???   -- use fmap to pair the result of ma with s
--    ```
--
-- 7. **Combining StateT and IO**
--
--    Implement a simple ATM simulator using the StateT transformer. Define a type `BankState` containing
--    the account balance. Write the following functions:
--    * `withdraw :: Int -> StateT BankState IO Bool` — attempts to withdraw a given amount
--    * `deposit :: Int -> StateT BankState IO ()` — deposits a given amount
--    * `checkBalance :: StateT BankState IO Int` — checks the current balance
--    * `atmSession :: StateT BankState IO ()` — runs an interactive session with the user
--
--    Each operation should print appropriate messages on the screen and update the account state.
--
-- 8. **Implementing a stack of transformers**
--
--    Define a type `AppM a = ReaderT Config (StateT AppState (ExceptT AppError IO)) a`, where:
--    * `Config` contains configuration parameters (e.g. `maxAttempts :: Int`)
--    * `AppState` contains the application state (e.g. `counter :: Int`, `lastOperation :: String`)
--    * `AppError` is a type representing possible errors (e.g. `NetworkError String`, `ValidationError String`)
--
--    Then implement the following helper functions:
--    * `getConfig :: AppM Config` — retrieves the configuration
--    * `getState :: AppM AppState` — retrieves the state
--    * `modifyState :: (AppState -> AppState) -> AppM ()` — modifies the state
--    * `throwAppError :: AppError -> AppM a` — raises an error
--    * `runApp :: Config -> AppState -> AppM a -> IO (Either AppError (a, AppState))` — runs the computation
--
--    Finally, implement an example business function `processTransaction :: Transaction -> AppM Result`
--    that uses the helper functions above.
main :: IO ()
main = do
  putStrLn "=== Tutorials 05 ==="
  print $ evalState (runningSumHelper [1,2,3,4]) ([],0)
  print $ evalState (randomInt 4 10) 44
  print $ evalState (randomList 5 1 100) 2
  print $ evalState (labelTree (Node 'a' (Node 'b' Empty Empty) (Node 'c' Empty Empty))) 0
  print $ evalState (countNodes (Node 'a' (Node 'b' Empty Empty) (Node 'c' Empty Empty))) 0
  -- calculator
