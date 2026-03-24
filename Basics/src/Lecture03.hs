module Lecture03 (main) where


-- How foldl and foldr work:
-- foldl (#) seed [a1..an] -> ((..(seed#a1)#a2)#..)#an
-- foldr (*) seed [a1..an] -> a1*(a2*..(an*seed)..)


-- Our own foldl implementation.
-- Example: ourFoldl (+) 0 [1,2,3] = ((0+1)+2)+3 = 6
ourFoldl :: (b -> a -> b) -> b -> [a] -> b
ourFoldl _ seed []     = seed
ourFoldl f seed (x:xs) = ourFoldl f (f seed x) xs


-- Our own foldr implementation.
-- Example: ourFoldr (+) 0 [1,2,3] = 1+(2+(3+0)) = 6
ourFoldr :: (a -> b -> b) -> b -> [a] -> b
ourFoldr _ seed []     = seed
ourFoldr f seed (x:xs) = f x (ourFoldr f seed xs)


-- The function initl builds a list of all initial sublists using foldl.
-- The seed is [[]], and at each step we extend the last sublist by one element.
-- Example: initl [1,2,3] = [[], [1], [1,2], [1,2,3]]
-- Step by step:
--   acc = [[]]                        , x = 1 => [[], [1]]
--   acc = [[], [1]]                   , x = 2 => [[], [1], [1,2]]
--   acc = [[], [1], [1,2]]            , x = 3 => [[], [1], [1,2], [1,2,3]]
initl :: [a] -> [[a]]
initl = foldl (\acc x -> acc ++ [last acc ++ [x]]) [[]]


-- The function initr builds all initial sublists using foldr.
-- The seed is [[]], and at each step we prepend [] and map (x:) over the rest.
-- Example: initr [1,2,3] = [[], [1], [1,2], [1,2,3]]
-- Step by step (foldr processes right to left):
--   x = 3, acc = [[]]                    => [[], [3]]
--   x = 2, acc = [[], [3]]               => [[], [2], [2,3]]
--   x = 1, acc = [[], [2], [2,3]]        => [[], [1], [1,2], [1,2,3]]
initr :: [a] -> [[a]]
initr = foldr (\x acc -> [] : map (x:) acc) [[]]


-- Sum of a list using foldl.
-- Example: sumList [1,2,3,4,5] = ((((0+1)+2)+3)+4)+5 = 15
sumList :: [Int] -> Int
sumList = foldl (+) 0


-- Reverse a list using foldl.
-- Example: reverseList [1,2,3] = [3,2,1]
-- Step by step:
--   acc = [], x = 1 => 1 : [] = [1]
--   acc = [1], x = 2 => 2 : [1] = [2,1]
--   acc = [2,1], x = 3 => 3 : [2,1] = [3,2,1]
reverseList :: [a] -> [a]
reverseList = foldl (\acc x -> x : acc) []


-- Count occurrences of an element using foldl.
-- Example: countOccurrences 'a' "abracadabra" = 5
countOccurrences :: Eq a => a -> [a] -> Int
countOccurrences x = foldl (\acc y -> if x == y then acc + 1 else acc) 0


----------------------------------------------------------------------
-- Folds on other data types
----------------------------------------------------------------------


-- A binary tree with empty trees, leaves, and internal nodes.
data Tree a = EmptyTree | Leaf a | Node a (Tree a) (Tree a)
  deriving (Show)


-- A right fold over a Tree (pre-order: node, then right, then left).
-- Example: treeFoldr (\x acc -> acc ++ [x]) [] tree = ["d","c","b","a"]
treeFoldr :: (a -> b -> b) -> b -> Tree a -> b
treeFoldr _ seed EmptyTree         = seed
treeFoldr f seed (Leaf x)          = f x seed
treeFoldr f seed (Node x left right) = f x rightFolded
  where
    leftFolded  = treeFoldr f seed left
    rightFolded = treeFoldr f leftFolded right


-- Example trees.
tree :: Tree String
tree = Node "a" (Node "b" EmptyTree (Leaf "c")) (Node "d" EmptyTree EmptyTree)

tree2 :: Tree Int
tree2 = Node 1 (Node 5 EmptyTree (Leaf 7)) (Node 3 EmptyTree EmptyTree)


-- foldMap maps each element to a monoid and combines them (inorder traversal).
treeFoldMap :: (Monoid m) => (a -> m) -> Tree a -> m
treeFoldMap _ EmptyTree              = mempty
treeFoldMap f (Leaf x)               = f x
treeFoldMap f (Node x left right)    = treeFoldMap f left <> f x <> treeFoldMap f right


-- Implement the Foldable interface for Tree.
-- This gives us fold, foldMap, foldr, foldl, toList, elem, etc. for free.
instance Foldable Tree where
  foldMap = treeFoldMap


----------------------------------------------------------------------
-- A custom monoid: OurAny
----------------------------------------------------------------------


-- A newtype wrapping Bool, with a monoid that represents logical OR.
-- This mirrors Data.Monoid.Any.
newtype OurAny = OurAny { getOurAny :: Bool }
  deriving (Show)

instance Semigroup OurAny where
  OurAny a <> OurAny b = OurAny (a || b)

instance Monoid OurAny where
  mempty = OurAny False


-- Check whether a tree contains a given value using foldMap with OurAny.
-- Example: treeContains 7 tree2  = True
-- Example: treeContains 10 tree2 = False
treeContains :: Eq a => a -> Tree a -> Bool
treeContains x = getOurAny . foldMap (\y -> OurAny (x == y))


-- Collect all values from a tree into a list (inorder) using foldMap.
-- Example: treeToList tree  = ["b", "c", "a", "d"]
-- Example: treeToList tree2 = [5, 7, 1, 3]
treeToList :: Tree a -> [a]
treeToList = foldMap (: [])


main :: IO ()
main = do
  putStrLn "=== Lecture 03: Folds ==="

  putStrLn "\n-- ourFoldl --"
  print (ourFoldl (+) 0 [1,2,3,4,5 :: Int])

  putStrLn "\n-- ourFoldr --"
  print (ourFoldr (+) 0 [1,2,3,4,5 :: Int])

  putStrLn "\n-- initl (initial sublists via foldl) --"
  print (initl [1,2,3 :: Int])

  putStrLn "\n-- initr (initial sublists via foldr) --"
  print (initr [1,2,3 :: Int])

  putStrLn "\n-- sumList --"
  print (sumList [1,2,3,4,5])

  putStrLn "\n-- reverseList --"
  print (reverseList [1,2,3 :: Int])

  putStrLn "\n-- countOccurrences --"
  print (countOccurrences 'a' "abracadabra")

  putStrLn "\n-- treeFoldr --"
  print (treeFoldr (\x acc -> acc ++ [x]) [] tree)
  print (treeFoldr (+) 0 tree2)

  putStrLn "\n-- Foldable Tree (foldMap, foldr) --"
  print (foldr (\x acc -> acc ++ [x]) [] tree)
  print (foldr (+) 0 tree2)

  putStrLn "\n-- OurAny monoid --"
  print (OurAny True <> OurAny False)
  print (OurAny False <> OurAny False)
  print (mempty <> OurAny True :: OurAny)

  putStrLn "\n-- treeContains --"
  print (treeContains 7 tree2)
  print (treeContains 10 tree2)
  print (treeContains "c" tree)
  print (treeContains "z" tree)

  putStrLn "\n-- treeToList --"
  print (treeToList tree)
  print (treeToList tree2)
