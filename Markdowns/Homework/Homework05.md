# Homework 05

## State Monad

1. **Stack machine**

   Define a stack-based instruction set:
   ```haskell
   data Instr = PUSH Int | POP | DUP | SWAP | ADD | MUL | NEG
   ```
   and implement
   ```haskell
   execInstr :: Instr -> State [Int] ()
   ```
   that executes a single instruction on a stack (a list of `Int`). Then implement
   ```haskell
   execProg :: [Instr] -> State [Int] ()
   ```
   that executes a sequence of instructions, and a wrapper
   ```haskell
   runProg :: [Instr] -> [Int]
   ```
   that runs the program starting with an empty stack and returns the final stack.
   If an instruction requires more operands than are on the stack, it should be silently skipped.

2. **Expression evaluator with variable bindings**

   Consider the following expression language with mutable variables:
   ```haskell
   data Expr
     = Num Int
     | Var String
     | Add Expr Expr
     | Mul Expr Expr
     | Neg Expr
     | Assign String Expr   -- bind the value of the expression to the name, return that value
     | Seq  Expr Expr       -- evaluate the left, then the right; return the value of the right
   ```
   Using `Data.Map` as the variable environment, implement
   ```haskell
   eval :: Expr -> State (Map String Int) Int
   ```
   so that `Assign` updates the environment, `Var` looks a name up (you may assume all referenced
   variables have been assigned earlier), and the remaining constructors behave as expected.
   Use `get`, `put`, and/or `modify`. Then provide the wrapper
   ```haskell
   runEval :: Expr -> Int
   ```
   which runs `eval` starting from the empty environment using `evalState`.

3. **Memoised edit (Levenshtein) distance**

   The edit distance between two strings is the minimum number of single-character insertions,
   deletions, and substitutions required to transform one into the other. Implement it using
   the `State` monad so that the overlapping subproblems of the naive recursion are reused.

   Use a cache of type `Map (Int, Int) Int` whose entry at key `(i, j)` stores the edit distance
   between the prefixes of length `i` and `j` of the two input strings. Implement
   ```haskell
   editDistM :: String -> String -> Int -> Int -> State (Map (Int, Int) Int) Int
   ```
   where `editDistM xs ys i j` returns the edit distance between `take i xs` and `take j ys`.
   Each call should first consult the cache; if the entry is present, return it, otherwise
   compute it using the standard recurrence
   ```
   d(0, j) = j
   d(i, 0) = i
   d(i, j) = d(i-1, j-1)                      if  xs!!(i-1) == ys!!(j-1)
   d(i, j) = 1 + min { d(i-1, j)              -- deletion
                     , d(i,   j-1)            -- insertion
                     , d(i-1, j-1) }          -- substitution
   ```
   store the result in the cache, and return it. Finally provide the pure wrapper
   ```haskell
   editDistance :: String -> String -> Int
   ```

## StateT and "Treasure Hunters" Game Simulation

Implement an interactive adventure game simulation called "Treasure Hunters" using the `State` monad
and `IO`. Instead of using a random number generator, the player is asked to provide the dice roll
result and decisions at choice points. The board is a map with several paths leading to the treasure;
the player starts at a starting position and must reach the treasure. The board contains:

- **Decision points** — places where the player can choose one of several available paths
- **Obstacles** — which can push the player back or delay their journey
- **Intermediate treasures** — giving the player extra points
- **Traps** — which can take away the player's accumulated points

The player has a certain amount of energy that decreases with each move; the goal is to reach the main
treasure with as many points as possible before running out of energy. Define a `GameState` type
representing the game state and a type
```haskell
type AdventureGame a = StateT GameState IO a
```
representing operations in the game context. Then solve the following problems.

4. **Player movement and decisions**

   Implement
   ```haskell
   movePlayer   :: Int -> AdventureGame Int
   makeDecision :: [String] -> AdventureGame String
   ```
   where `movePlayer` moves the player based on the given dice roll result and returns the number
   of spaces moved, and `makeDecision` handles a decision point by presenting the player with options
   and returning their choice.

5. **Game loop**

   Implement
   ```haskell
   handleLocation :: AdventureGame Bool
   playTurn       :: AdventureGame Bool
   playGame       :: AdventureGame ()
   ```
   where `handleLocation` handles the player's current location (obstacle, treasure, trap) and returns
   `True` if the player has reached the goal; `playTurn` handles one turn of the game and returns
   `True` if the game has ended; `playGame` runs the game until it ends, displaying the game state
   after each move.

6. **User interaction in `IO`**

   Implement the supporting `IO` functions
   ```haskell
   getDiceRoll      :: IO Int
   displayGameState :: GameState -> IO ()
   getPlayerChoice  :: [String] -> IO String
   ```
   which ask the user to provide a dice roll result, display the current game state, and ask the
   user to choose one of the given options, respectively.

### Hints

1. Use the `StateT` transformer to combine state tracking with `IO` interaction.
2. The `lift` function from `Control.Monad.IO.Class` allows you to perform `IO` operations inside
   the `AdventureGame` monad.
3. Think about different effects for different location types:
   - at decision points, use `makeDecision` to let the player choose a path;
   - at obstacles, reduce the player's energy or delay their movement;
   - at treasures, increase the player's score;
   - at traps, decrease the player's score.
4. Remember to validate input data in `getDiceRoll` and `getPlayerChoice`.
5. Add visual effects through appropriate text formatting to make the game more engaging.
6. Complete the map implementation by adding different paths to the goal with various challenges.
