# State Monad, IO Monad, and Monad Transformers

1. **State Monad for tracking state**

   Define a function `runningSum :: [Int] -> [Int]` that, given a list of integers, returns a list of partial sums.
   For example, for the list `[1, 2, 3, 4]` the result should be `[1, 3, 6, 10]`. Implement this function
   using the State monad, making use of `get`, `put`, and `runState` or `evalState`.

2. **A pseudo-random number generation using State monad**

   Implement a simple pseudo-random number generator using the State monad. Define a function
   `randomInt :: Int -> Int -> State Int Int` that generates an integer in the given range `[a, b]`,
   using a [linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).
   Then write a function `randomList :: Int -> Int -> Int -> State Int [Int]` that generates a list
   of `n` random numbers from the range `[a, b]`. Use `evalState` to run the computation with a given seed.

3. **Binary tree and labelling with State**

   Define a binary tree type `data Tree a = Empty | Node a (Tree a) (Tree a)`. Then implement a function
   `labelTree :: Tree a -> State Int (Tree (a, Int))` that labels each node of the tree with a unique number,
   using the State monad to track the counter. The numbering should be in preorder.
   Also write a function `countNodes :: Tree a -> State (Sum Int) (Tree a)` that counts the nodes in the tree,
   using the State monad for accumulation.

4. **Interactive calculation using IO**

   Write a program `calculator :: IO ()` that reads two numbers and an operation (addition, subtraction,
   multiplication, division) from the user and prints the result. The program should handle errors
   (e.g. division by zero) and ask the user whether they want to continue. Use `getLine`, `readLn`,
   and `putStrLn` to interact with the user.

5. **A safer calculator with MaybeT**

   The `calculator :: IO ()` from task 4 uses `readLn :: IO Int`, which throws a runtime exception
   whenever the user types something that is not a valid integer (e.g. `"abc"` or an empty line).
   Rewrite the calculator using the `MaybeT` transformer from `Control.Monad.Trans.Maybe`
   so that bad input is reported as `Nothing` instead of crashing the program.

   * Define a helper `readInt :: MaybeT IO Int` that reads a line from standard input and
     produces `Nothing` when the line is not a valid integer (use `readMaybe` from `Text.Read`,
     or check the input by hand with `Data.Char.isDigit`).
   * Define a helper `readOp :: MaybeT IO (Int -> Int -> Int)` that reads an operation name
     (e.g. `"sum"`, `"difference"`, `"product"`) and returns the corresponding function, or
     `Nothing` if the name is not recognised.
   * Implement `goodCalculator :: MaybeT IO ()` that reads two integers and an operation
     using the helpers above and prints the result.

6. **Combining StateT and IO**

   Implement a simple ATM simulator using the StateT transformer. Define a type `BankState` containing
   the account balance. Write the following functions:
   * `withdraw :: Int -> StateT BankState IO Bool` — attempts to withdraw a given amount
   * `deposit :: Int -> StateT BankState IO ()` — deposits a given amount
   * `checkBalance :: StateT BankState IO Int` — checks the current balance
   * `atmSession :: StateT BankState IO ()` — runs an interactive session with the user

   Each operation should print appropriate messages on the screen and update the account state.

7. **Implementing a stack of transformers**

   Define a type `AppM a = ReaderT Config (StateT AppState (ExceptT AppError IO)) a`, where:
   * `Config` contains configuration parameters (e.g. `maxAttempts :: Int`)
   * `AppState` contains the application state (e.g. `counter :: Int`, `lastOperation :: String`)
   * `AppError` is a type representing possible errors (e.g. `NetworkError String`, `ValidationError String`)

   Then implement the following helper functions:
   * `getConfig :: AppM Config` — retrieves the configuration
   * `getState :: AppM AppState` — retrieves the state
   * `modifyState :: (AppState -> AppState) -> AppM ()` — modifies the state
   * `throwAppError :: AppError -> AppM a` — raises an error
   * `runApp :: Config -> AppState -> AppM a -> IO (Either AppError (a, AppState))` — runs the computation

   Finally, implement an example business function `processTransaction :: Transaction -> AppM Result`
   that uses the helper functions above.
