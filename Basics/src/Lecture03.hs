module Lecture03 (main) where
import qualified Data.Monoid as M

-- how foldl and foldr work:
-- foldl (#) seed [a1..an] -> ((..(seed#a1)#a2#..)#an

ourFoldl :: (b -> a -> b) -> b -> [a] -> b
ourFoldl f seed [] = seed
ourFoldl f seed (x:xs) = ourFoldl f (f seed x) xs
-- foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)

-- foldl :: (b -> a -> b) -> b -> [a] -> b

-- The function initl builds a list of all initial sublists.
-- Example: initl [1,2,3] = [[], [1], [1,2], [1,2,3]]
-- Uses foldl to build the result step by step.
-- The seed value is a list containing the empty list.
-- At each step, we append the last sublist extended by the current element.
--
-- initl :: [a] -> [[a]]


-- Now write initl using foldr.
-- foldr :: (a -> b -> b) -> b -> [a] -> b
ourFoldr :: (a -> b -> b) -> b -> [a] -> b
ourFoldr f seed [] = seed
ourFoldr f seed (x:xs) = f x (ourFoldr f seed xs)
-- foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)
--
-- initr :: [a] -> [[a]]


-- Sum of a list.
-- Example: sumList [1,2,3,4,5] = ((((0+1)+2)+3)+4)+5 = 15
--
-- sumList :: [Int] -> Int
sumList :: [Int] -> Int
sumList = foldl (+) 0

-- Reverse a list.
-- Example: reverseList [1,2,3] = [3,2,1]
-- Step by step:
--   1. acc = [], x = 1 => x : acc = [1]
--   2. acc = [1], x = 2 => x : acc = [2,1]
--   3. acc = [2,1], x = 3 => x : acc = [3,2,1]
--
-- reverseList :: [a] -> [a]


-- Count occurrences of an element.
-- Example: countOccurrences 'a' "abracadabra" = 5
--
countOccurrences :: Eq a => a -> [a] -> Int
countOccurrences x list = foldl (\y z -> if x == z then y + 1 else y) 0 list
--
-- Folds on other data types
--
-- Definition of a binary tree.
data Tree a = EmptyTree | Leaf a | Node a (Tree a) (Tree a)

treeFoldr :: (a -> b -> b) -> b -> Tree a -> b
treeFoldr f seed EmptyTree = seed
treeFoldr f seed (Leaf x) = f x seed
treeFoldr f seed (Node x left right) =  f x rightFolded
  where
      leftFolded = treeFoldr f seed left
      rightFolded = treeFoldr f leftFolded right
-- Example tree with strings.
tree :: Tree String
tree = Node "a" (Node "b" EmptyTree (Leaf "c")) (Node "d" EmptyTree EmptyTree)

-- Example tree with integers.
tree2 :: Tree Int
tree2 = Node 1 (Node 5 EmptyTree (Leaf 7)) (Node 3 EmptyTree EmptyTree)


treeFoldMap :: (Monoid m) => (a -> m) -> Tree a -> m
treeFoldMap f EmptyTree = mempty
treeFoldMap f (Leaf x)= f x
treeFoldMap f (Node x left right) = treeFoldMap f left <> f x <> treeFoldMap f right
-- Implement the Foldable interface for Tree.
-- This allows the use of fold, foldMap, foldr, foldl, etc. on trees.
instance Foldable Tree where
  foldMap = treeFoldMap
--   foldMap :: Monoid m => (a -> m) -> Tree a -> m
--   Maps each tree element to a monoid and combines the results.
--   The empty tree maps to the monoid identity element.
--   A leaf maps to the value transformed by f.
--   A node combines left subtree, node value, and right subtree (inorder).
--
--   foldr :: (a -> b -> b) -> b -> Tree a -> b
--   Folds the tree "from the right".
--   The empty tree returns the seed value.
--   A leaf applies f to its value and the seed.
--   A node is processed right subtree first, then the node value, then the left subtree.
--
-- instance Foldable Tree where


-- Define a helper newtype:
-- data Any = Any { getAny :: Bool }
-- and provide Semigroup and Monoid instances so we can use foldMap.
--
-- instance Semigroup Any where
-- instance Monoid Any where


-- Check whether a tree contains a given value.
-- Example: treeContains 7 tree2 = True
-- Example: treeContains 10 tree2 = False
--
-- treeContains :: Eq a => a -> Tree a -> Bool


-- Collect all values from a tree into a list (inorder).
-- Example: treeToList tree  = ["b", "c", "a", "d"]
-- Example: treeToList tree2 = [5, 7, 1, 3]
--
-- treeToList :: Tree a -> [a]


main :: IO ()
main = do
  putStrLn "=== Lecture 03: Folds ==="

  putStrLn "\n-- ourFoldl --"
  print (ourFoldl (+) 0 [1,2,3,4,5 :: Int])

  putStrLn "\n-- ourFoldr --"
  print (ourFoldr (+) 0 [1,2,3,4,5 :: Int])

  putStrLn "\n-- sumList --"
  print (sumList [1,2,3,4,5])

  putStrLn "\n-- countOccurrences --"
  print (countOccurrences 'a' "abracadabra")

  putStrLn "\n-- treeFoldr --"
  print (treeFoldr (\x acc -> acc ++ [x]) [] tree)
  print (treeFoldr (+) 0 tree2)

  putStrLn "\n-- Foldable Tree (foldMap, foldr) --"
  print (foldr (\x acc -> acc ++ [x]) [] tree)
  print (foldr (+) 0 tree2)
