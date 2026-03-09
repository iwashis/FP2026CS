# Algebraic Data Types

## Enumeration Types

Haskell has built-in data types such as `Bool`, defined as:

```haskell
-- data Bool = True | False
```

We can define our own enumeration types the same way. Here is a type `BasicColors` representing primary colours:

```haskell
data BasicColors = Red | Blue | Green
```

`BasicColors` has three constructor values: `Red`, `Blue`, and `Green`. We can use it like this:

```
> let colour = Red
> :t colour
colour :: BasicColors
```

## Algebraic Data Types

Algebraic data types (ADTs) allow us to define more complex structures. Consider a type `Shape` representing different geometric shapes:

```haskell
data Shape
    = Rectangle (Double, Double) (Double, Double)
    | Circle (Double, Double) Double
    | Point (Double, Double)
```

`Shape` has three constructors:
- `Rectangle` takes two coordinate pairs (bottom-left and top-right corners)
- `Circle` takes a coordinate pair for the centre and a radius
- `Point` takes a coordinate pair

Examples:

```
> let square = Rectangle (0,0) (5,5)
> let circle = Circle (3,3) 2
> let point  = Point (1,1)
```

We can now define functions that operate on these shapes. For example, a function computing the area:

```haskell
volume :: Shape -> Double
volume (Point (_, _))           = 0
volume (Circle _ r)             = pi * (r ^ 2)
volume (Rectangle (x, y) (z, t)) = abs (z - x) * abs (t - y)
```

Examples:

```
> volume (Point (1,1))
0
> volume (Rectangle (0,0) (3,4))
12.0
> volume (Circle (0,0) 2)
12.566370614359172
```

We can also define functions that transform shapes, such as increasing a circle's radius by 5:

```haskell
changeRadiusIfCircle :: Shape -> Shape
changeRadiusIfCircle (Circle point r) = Circle point (r + 5)
changeRadiusIfCircle x = x
```

Examples:

```
> changeRadiusIfCircle (Circle (0,0) 2)
Circle (0,0) 7
> changeRadiusIfCircle (Rectangle (0,0) (3,4))
Rectangle (0,0) (3,4)
```

## Records

Haskell provides a convenient way to define data types with named fields using records. Compare two ways of defining a `Person` type:

Standard definition:

```haskell
data Person = Person String String Int
    deriving (Show)

p = Person "Tom" "Smith" 25
```

Record definition:

```haskell
data Person2 = Person2
    { name    :: String
    , surname :: String
    , age     :: Int
    }
    deriving (Show)

p2 = Person2 "Tom" "Smith" 25
```

Records automatically generate field accessor functions:

```
> name p2
"Tom"
> surname p2
"Smith"
> age p2
25
```

We can also use the `RecordWildCards` extension for more convenient record manipulation:

```haskell
addMr :: Person2 -> Person2
addMr p@Person2{name = name, surname = surname, ..} =
    if surname /= ""
        then Person2{name = "Mr." ++ name, ..}
        else p
```

This adds the prefix "Mr." to a person's name, provided the surname is non-empty. The `..` preserves the remaining fields unchanged.

Examples:

```
> addMr (Person2 "John" "Smith" 30)
Person2 {name = "Mr.John", surname = "Smith", age = 30}
> addMr (Person2 "John" "" 30)
Person2 {name = "John", surname = "", age = 30}
```

## Recursive Data Structures

We can define recursive data structures in Haskell. Here is a custom integer list:

```haskell
data IntList = EmptyIntList | NonEmptyList Int IntList
    deriving (Show)

listExample = NonEmptyList 4 (NonEmptyList 5 EmptyIntList)
```

The list is either empty (`EmptyIntList`) or non-empty (`NonEmptyList`), holding an `Int` and the rest of the list. We can define functions over this structure, such as computing its length:

```haskell
length2 :: IntList -> Int
length2 EmptyIntList          = 0
length2 (NonEmptyList _ list) = 1 + length2 list
```

Examples:

```
> length2 EmptyIntList
0
> length2 (NonEmptyList 1 (NonEmptyList 2 EmptyIntList))
2
> length2 listExample
2
```

Similarly, a binary tree for integers:

```haskell
data IntTree = EmptyTree | IntNode Int IntTree IntTree
```

## Parameterised Types

Defining separate types for lists or trees of every possible element type would be impractical. Haskell supports parameterised (generic) types:

```haskell
data Tree a = Empty | Node a (Tree a) (Tree a)
    deriving (Show)

exampleTree :: Tree [Int]
exampleTree = Node [1, 2] Empty (Node [4] Empty Empty)
```

`Tree a` is a binary tree storing values of type `a`. We can store numbers, strings, lists, or even other trees:

```
> Node 5 (Node 3 Empty Empty) (Node 7 Empty Empty) :: Tree Int
Node 5 (Node 3 Empty Empty) (Node 7 Empty Empty)
> Node "root" (Node "left" Empty Empty) (Node "right" Empty Empty) :: Tree String
Node "root" (Node "left" Empty Empty) (Node "right" Empty Empty)
```

A generic list type:

```haskell
data List a = EmptyList | Head a (List a)
```

## Type Class Instances

### Show — Converting to String

We can write a custom `Show` instance for our `List` type:

```haskell
instance (Show a) => Show (List a) where
    show EmptyList          = ""
    show (Head a EmptyList) = show a
    show (Head a list)      = show a ++ "," ++ show list
```

```
> Head 1 (Head 50 EmptyList)
1,50
```

### Eq — Comparing Values

```haskell
instance (Eq a) => Eq (List a) where
    EmptyList    == EmptyList    = True
    (Head a _)   == EmptyList    = False
    EmptyList    == (Head a _)   = False
    (Head a xs)  == (Head b ys)  = a == b && xs == ys
```

```
> Head 1 (Head 2 EmptyList) == Head 1 (Head 2 EmptyList)
True
> Head 1 (Head 2 EmptyList) == Head 1 (Head 3 EmptyList)
False
```

## Type Aliases

Type aliases improve code readability without introducing new types:

```haskell
type NewInt = Int

type Width  = Int
type Height = Int

volume2 :: Width -> Height -> Int
volume2 h w = h * w
```

```
> volume2 3 4
12
```

## Functors, Semigroups, and Monoids

### Functor

A **functor** is a type class for types that can be mapped over. Its formal definition is:

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

The single law a functor must satisfy:
- **Identity**: `fmap id == id`
- **Composition**: `fmap (f . g) == fmap f . fmap g`

A functor allows applying a function to a value wrapped in a context:

```haskell
instance Functor List where
    fmap _ EmptyList     = EmptyList
    fmap f (Head a list) = Head (f a) (fmap f list)
```

```
> fmap (+1) (Head 1 (Head 2 EmptyList))
2,3
> fmap show (Head 1 (Head 2 EmptyList))
"1","2"
```

### Semigroup and Monoid

A **semigroup** is a type with an associative binary operation. Its formal definition:

```haskell
class Semigroup a where
    (<>) :: a -> a -> a
```

The law it must satisfy:
- **Associativity**: `(x <> y) <> z == x <> (y <> z)`

A **monoid** extends a semigroup with a neutral element:

```haskell
class Semigroup a => Monoid a where
    mempty  :: a
    mappend :: a -> a -> a
    mappend = (<>)
    mconcat :: [a] -> a
    mconcat = foldr (<>) mempty
```

Additional laws:
- **Left identity**: `mempty <> x == x`
- **Right identity**: `x <> mempty == x`

Instances for our `List` type:

```haskell
instance Semigroup (List a) where
    EmptyList   <> ys = ys
    (Head x xs) <> ys = Head x (xs <> ys)

instance Monoid (List a) where
    mempty  = EmptyList
    mappend = (<>)
```

```
> Head 1 (Head 2 EmptyList) <> Head 3 (Head 4 EmptyList)
1,2,3,4
> mempty <> Head 1 (Head 2 EmptyList)
1,2
> Head 1 (Head 2 EmptyList) <> mempty
1,2
```
