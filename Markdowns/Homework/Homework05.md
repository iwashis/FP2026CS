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

2. **Unique labelling of a tree**

   Given the tree type
   ```haskell
   data Tree a = Leaf a | Node (Tree a) a (Tree a)
   ```
   implement
   ```haskell
   labelTree :: Tree a -> Tree (a, Int)
   ```
   that labels each node and leaf with a unique integer (starting from 0) using the `State` monad.
   The labelling should follow an in-order traversal. Use `get` and `put` (or `modify`)
   and `evalState`.

## StateT and "Treasure Hunters" Game Simulation

### Objective
Implement an interactive adventure game simulation called "Treasure Hunters" using the State monad and IO. Instead of using a random number generator, ask the user to provide the dice roll result and decisions at choice points.

### Game Description
"Treasure Hunters" is a board game in which:
- The board is a map with several paths leading to the treasure
- The player starts at the starting position and must reach the treasure
- The board contains:
  - Decision Points - places where the player can choose one of several available paths
  - Obstacles - which can push the player back or delay their journey
  - Intermediate Treasures - giving the player extra points
  - Traps - which can take away the player's accumulated points
- The player has a certain amount of energy that decreases with each move
- The goal is to reach the main treasure with as many points as possible before running out of energy

### Requirements

Define a `GameState` type representing the game state and a type `AdventureGame a = StateT GameState IO a` representing operations in the game context. Then implement the following functions:

#### Task 1 (3 points)
- `movePlayer :: Int -> AdventureGame Int` - moves the player based on the given dice roll result and returns the number of spaces moved
- `makeDecision :: [String] -> AdventureGame String` - handles a decision point, presenting the player with options and returning their choice

#### Task 2 (3 points)
- `handleLocation :: AdventureGame Bool` - handles the player's current location (obstacle, treasure, trap), returns True if the player has reached the goal
- `playTurn :: AdventureGame Bool` - handles one turn of the game, returns True if the game has ended
- `playGame :: AdventureGame ()` - runs the game until it ends, displaying the game state after each move

#### Task 3 (4 points)
Additionally, implement IO functions for user interaction:
- `getDiceRoll :: IO Int` - asks the user to provide a dice roll result
- `displayGameState :: GameState -> IO ()` - displays the current game state
- `getPlayerChoice :: [String] -> IO String` - asks the user to choose one of the options

### Hints
1. Use the StateT monad to combine the functionality of State (tracking game state) and IO (user interaction).
2. The `lift` function from the Control.Monad.IO.Class module allows you to perform IO operations inside the AdventureGame monad.
3. Think about different effects for different location types:
   - At decision points (Decision), use the `makeDecision` function to let the player choose a path
   - At obstacles (Obstacle), reduce the player's energy or delay their movement
   - At treasures (Treasure), increase the player's score
   - At traps (Trap), decrease the player's score
4. Remember to validate input data in the `getDiceRoll` and `getPlayerChoice` functions.
5. Add visual effects through appropriate text formatting to make the game more engaging.
6. Complete the map implementation by adding different paths to the goal with various challenges.
