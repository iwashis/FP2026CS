{-# LANGUAGE RecordWildCards #-}
module Lecture02 (main) where


-- Haskell has built-in types like Bool:
-- data Bool = True | False


-- An enumeration type for colours with three constructors: Red, Blue, Green.
-- Example: myColor = Red
data Colour = Red | Blue | Green deriving (Show, Eq)


-- A Shape type with three constructors:
--   Rectangle — two (x,y) pairs for the bottom-left and top-right corners.
--   Circle    — a centre (x,y) pair and a radius.
--   Point     — a single (x,y) pair.
-- Examples:
--   square = Rectangle (0,0) (5,5)
--   circle = Circle (3,3) 2
--   point  = Point (1,1)
data Shape
  = Rectangle (Double, Double) (Double, Double)
  | Circle    (Double, Double) Double
  | Point     (Double, Double)
  deriving (Show, Eq)


-- Compute the area of a Shape.
-- Examples:
--   volume (Point (1,1))           = 0
--   volume (Rectangle (0,0) (3,4)) = 12.0
volume :: Shape -> Double
volume (Point _)                    = 0
volume (Circle _ r)                 = pi * r * r
volume (Rectangle (x1,y1) (x2,y2)) = abs (x2 - x1) * abs (y2 - y1)


-- If the shape is a Circle, increase its radius by 5; otherwise return it unchanged.
-- Examples:
--   changeRadiusIfCircle (Circle (0,0) 2)        = Circle (0,0) 7
--   changeRadiusIfCircle (Rectangle (0,0) (3,4)) = Rectangle (0,0) (3,4)
changeRadiusIfCircle :: Shape -> Shape
changeRadiusIfCircle (Circle c r) = Circle c (r + 5)
changeRadiusIfCircle s            = s


-- A Person type holding a first name, last name, and age.
-- Example: person = Person "John" "Smith" 30
data Person = Person String String Int deriving (Show)


-- A Person type using record syntax, which auto-generates accessor functions:
-- name, surname, and age.
-- Examples:
--   person2 = Person2 { name = "John", surname = "Smith", age = 30 }
--   name person2    = "John"
--   surname person2 = "Smith"
--   age person2     = 30
data Person2 = Person2 { name :: String, surname :: String, age :: Int } deriving (Show)


-- Prepend "Mr." to the name field of a Person2.
-- If the surname is empty, return the person unchanged.
-- Uses RecordWildCards for concise record update syntax.
-- Examples:
--   addMr (Person2 "John" "Smith" 30) = Person2 {name = "Mr.John", surname = "Smith", age = 30}
--   addMr (Person2 "John" "" 30)      = Person2 {name = "John", surname = "", age = 30}
addMr :: Person2 -> Person2
addMr p@Person2{..}
  | null surname = p
  | otherwise    = p { name = "Mr." ++ name }


-- A custom integer list type with two constructors:
--   EmptyIntList — the empty list.
--   NonEmptyList — a head value paired with the rest of the list.
-- Example: myList = NonEmptyList 1 (NonEmptyList 2 (NonEmptyList 3 EmptyIntList))
data IntList
  = EmptyIntList
  | NonEmptyList Int IntList
  deriving (Show)


-- Compute the length of an IntList.
-- Examples:
--   length2 EmptyIntList                                    = 0
--   length2 (NonEmptyList 1 (NonEmptyList 2 EmptyIntList)) = 2
length2 :: IntList -> Int
length2 EmptyIntList        = 0
length2 (NonEmptyList _ xs) = 1 + length2 xs


-- A binary tree for integers with two constructors:
--   EmptyTree — an empty tree.
--   IntNode   — a value with left and right subtrees.
-- Example: tree = IntNode 5 (IntNode 3 EmptyTree EmptyTree) (IntNode 7 EmptyTree EmptyTree)
data IntTree
  = EmptyTree
  | IntNode Int IntTree IntTree
  deriving (Show)


-- A generic binary tree over any type a, with two constructors:
--   Empty — an empty tree.
--   Node  — a value with left and right subtrees.
-- Examples:
--   treeInt = Node 5 (Node 3 Empty Empty) (Node 7 Empty Empty)
--   treeStr = Node "root" (Node "left" Empty Empty) (Node "right" Empty Empty)
data Tree a
  = Empty
  | Node a (Tree a) (Tree a)
  deriving (Show)


-- A generic list over any type a, with two constructors:
--   EmptyList — the empty list.
--   Head      — a head value paired with the rest of the list.
-- Examples:
--   listInt = Head 1 (Head 2 (Head 3 EmptyList))
--   listStr = Head "a" (Head "b" (Head "c" EmptyList))
data List a
  = EmptyList
  | Head a (List a)


-- A custom Show instance for List.
-- Example: show (Head 1 (Head 2 EmptyList)) = "1,2,"
instance (Show a) => Show (List a) where
  show EmptyList   = ""
  show (Head x xs) = show x ++ "," ++ show xs


-- A custom Eq instance for List.
-- Two lists are equal when they contain the same elements in the same order.
-- Examples:
--   Head 1 (Head 2 EmptyList) == Head 1 (Head 2 EmptyList) = True
--   Head 1 (Head 2 EmptyList) == Head 1 (Head 3 EmptyList) = False
instance (Eq a) => Eq (List a) where
  EmptyList   == EmptyList   = True
  (Head x xs) == (Head y ys) = x == y && xs == ys
  _           == _           = False


-- A type with two constructors, Pair and Pair2, both holding a value of type a
-- and a value of type b.
-- Examples:
--   pair1 = Pair  "key" 5
--   pair2 = Pair2 "key" 5
data MyPair a b
  = Pair  a b
  | Pair2 a b
  deriving (Show)


-- Type aliases give an existing type a new name, improving readability.
-- Example: x :: NewInt = 5
type Width  = Int
type Height = Int


-- Compute the area of a rectangle given its width and height.
-- Example: volume2 3 4 = 12
volume2 :: Width -> Height -> Int
volume2 w h = w * h


-- Functors
-- A functor F lifts a function f :: a -> b to fmap f :: F a -> F b,
-- satisfying: fmap (f . g) = fmap f . fmap g
--
-- A custom Functor instance for List that maps a function over every element.
-- Examples:
--   fmap (+1) (Head 1 (Head 2 EmptyList)) = Head 2 (Head 3 EmptyList)
--   fmap show (Head 1 (Head 2 EmptyList)) = Head "1" (Head "2" EmptyList)
instance Functor List where
  fmap _ EmptyList   = EmptyList
  fmap f (Head x xs) = Head (f x) (fmap f xs)


-- A custom Semigroup instance for List using concatenation.
-- Example:
--   Head 1 (Head 2 EmptyList) <> Head 3 (Head 4 EmptyList)
--     = Head 1 (Head 2 (Head 3 (Head 4 EmptyList)))
instance Semigroup (List a) where
  EmptyList   <> ys = ys
  (Head x xs) <> ys = Head x (xs <> ys)


-- A custom Monoid instance for List.
-- mempty is the empty list; mappend delegates to (<>).
-- Examples:
--   mempty <> Head 1 (Head 2 EmptyList) = Head 1 (Head 2 EmptyList)
--   Head 1 (Head 2 EmptyList) <> mempty = Head 1 (Head 2 EmptyList)
instance Monoid (List a) where
  mempty = EmptyList


main :: IO ()
main = do
  putStrLn "=== Lecture 02: Algebraic Data Types ==="

  putStrLn "\n-- Colours --"
  print Red
  print Blue
  print Green

  putStrLn "\n-- Shapes --"
  let square = Rectangle (0,0) (5,5)
  let circle = Circle (3,3) 2
  let point  = Point (1,1)
  print square
  print circle
  print point

  putStrLn "\n-- volume --"
  print (volume point)
  print (volume (Rectangle (0,0) (3,4)))
  print (volume circle)

  putStrLn "\n-- changeRadiusIfCircle --"
  print (changeRadiusIfCircle (Circle (0,0) 2))
  print (changeRadiusIfCircle (Rectangle (0,0) (3,4)))

  putStrLn "\n-- Person --"
  let person = Person "John" "Smith" 30
  print person

  putStrLn "\n-- Person2 (record syntax) --"
  let person2 = Person2 { name = "John", surname = "Smith", age = 30 }
  print person2
  putStrLn ("name:    " ++ name person2)
  putStrLn ("surname: " ++ surname person2)
  print (age person2)

  putStrLn "\n-- addMr --"
  print (addMr (Person2 "John" "Smith" 30))
  print (addMr (Person2 "John" "" 30))

  putStrLn "\n-- IntList --"
  let myList = NonEmptyList 1 (NonEmptyList 2 (NonEmptyList 3 EmptyIntList))
  print myList
  print (length2 myList)
  print (length2 (NonEmptyList 1 (NonEmptyList 2 EmptyIntList)))
  print (length2 EmptyIntList)

  putStrLn "\n-- IntTree --"
  let tree = IntNode 5 (IntNode 3 EmptyTree EmptyTree) (IntNode 7 EmptyTree EmptyTree)
  print tree

  putStrLn "\n-- Generic Tree --"
  let treeInt = Node 5 (Node 3 Empty Empty) (Node 7 Empty Empty) :: Tree Int
  let treeStr = Node "root" (Node "left" Empty Empty) (Node "right" Empty Empty)
  print treeInt
  print treeStr

  putStrLn "\n-- Generic List --"
  let listInt = Head 1 (Head 2 (Head 3 EmptyList)) :: List Int
  let listStr = Head "a" (Head "b" (Head "c" EmptyList))
  putStrLn (show listInt)
  putStrLn (show listStr)

  putStrLn "\n-- List Eq --"
  print (Head 1 (Head 2 EmptyList) == (Head 1 (Head 2 EmptyList) :: List Int))
  print (Head 1 (Head 2 EmptyList) == (Head 1 (Head 3 EmptyList) :: List Int))

  putStrLn "\n-- Functor List --"
  putStrLn (show (fmap (+1) (Head 1 (Head 2 EmptyList) :: List Int)))
  putStrLn (show (fmap show (Head 1 (Head 2 EmptyList) :: List Int)))

  putStrLn "\n-- Semigroup & Monoid List --"
  let l1 = Head 1 (Head 2 EmptyList) :: List Int
  let l2 = Head 3 (Head 4 EmptyList) :: List Int
  putStrLn (show (l1 <> l2))
  putStrLn (show (mempty <> l1))
  putStrLn (show (l1 <> mempty))

  putStrLn "\n-- MyPair --"
  let pair1 = Pair  "key" (5 :: Int)
  let pair2 = Pair2 "key" (5 :: Int)
  print pair1
  print pair2

  putStrLn "\n-- volume2 (type aliases) --"
  print (volume2 3 4)
