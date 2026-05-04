module Lecture07 where

import Data.Char (isDigit, isAlpha, isSpace)
import Control.Monad.State

--
-- ==========================================
--  Lecture 7: Monadic Parsing
--   (Hutton & Meijer, "Monadic Parsing in Haskell", JFP 8(4), 1998)
-- ==========================================
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. The Parser type
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Last time:   StateT s m a  ≅  s -> m (a, s)
-- Pick s = String, m = []:
--
--   StateT String [] a   ≅   String -> [(a, String)]
--
-- A Parser takes a string and returns ALL the ways it can produce a
-- value together with the leftover input. Empty list = parse failure.
--
--   []                          — failure
--   [(v, "")]                   — unique complete parse
--   [(v, rest)]                 — unique parse with leftover
--   [(v1,r1),(v2,r2),...]       — ambiguous grammar

type Parser a = StateT String [] a

runParser :: Parser a -> String -> [(a, String)]
runParser = runStateT

-- The Functor / Applicative / Monad / Alternative instances come for
-- free from StateT String [].


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. Three primitives: result, zero, item
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- result — succeed without consuming input (this is `return`)
result :: a -> Parser a
result = pure 

-- zero — always fail
zero :: Parser a
zero = StateT $ const [] 

-- item — consume exactly one character (any character)
item :: Parser Char
item = do  
  string <- get
  case string of 
    x:xs -> do 
      put xs
      pure x
    [] -> zero 
  

-- ghci> runParser item "abc"        -- [('a',"bc")]
-- ghci> runParser item ""           -- []
-- ghci> runParser (result 42) "xy"  -- [(42,"xy")]


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. Sequencing — >>= comes for free from StateT
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Two characters in a row — the second `item` automatically gets the
-- input left over by the first.

twoChars :: Parser (Char, Char)
twoChars = do 
  x <- item 
  y <- item
  pure (x,y)
-- ghci> runParser twoChars "abc"   -- [(('a','b'),"c")]
-- ghci> runParser twoChars "a"     -- []


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4. Choice and failure (MonadPlus-flavoured)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Non-deterministic choice: try BOTH, return all parses of either.
infixr 5 +++
(+++) :: Parser a -> Parser a -> Parser a
(+++) = undefined

-- Laws (a "monad with zero and plus"):
--   zero +++ p         ==  p
--   p +++ zero         ==  p
--   (p +++ q) +++ r    ==  p +++ (q +++ r)
--   zero >>= f         ==  zero
--   (p +++ q) >>= f    ==  (p >>= f) +++ (q >>= f)

-- Deterministic choice: keep only the FIRST successful parse.
infixr 5 <|>
(<|>) :: Parser a -> Parser a -> Parser a
(<|>) = undefined

-- For unambiguous grammars <|> is dramatically faster — no exponential
-- blow-up of alternatives, matches what hand-written recursive-descent does.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 5. Building blocks: sat, char, digit, letter, space, string
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sat :: (Char -> Bool) -> Parser Char
sat predicate = do 
  x <- item
  if predicate x then result x else zero

char :: Char -> Parser Char
char = undefined

digit :: Parser Char
digit = undefined

letter :: Parser Char
letter = undefined

-- (named with a P suffix to avoid clashing with Data.Char.space)
spaceP :: Parser Char
spaceP = undefined

string :: String -> Parser String
string = undefined

-- ghci> runParser (string "let") "let x = 1"   -- [("let"," x = 1")]
-- ghci> runParser (string "let") "lemon"       -- []


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 6. Repetition: many and many1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

many :: Parser a -> Parser [a]
many = undefined

many1 :: Parser a -> Parser [a]
many1 = undefined

-- A non-negative integer.
nat :: Parser Int
nat = undefined

-- ghci> runParser nat "123abc"
-- [(123,"abc"),(12,"3abc"),(1,"23abc")]
-- The list monad gives every prefix; replace +++ with <|> in many
-- to keep only the longest match.

-- Exercise: define `int` that also accepts an optional leading '-'.
-- Hint:  (char '-' >> negate <$> nat) <|> nat
int :: Parser Int
int = undefined


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 7. Whitespace, tokens, separators
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

spaces :: Parser ()
spaces = undefined

token :: Parser a -> Parser a
token = undefined

symbol :: String -> Parser String
symbol = undefined

-- A list of items separated by a separator.
sepby1 :: Parser a -> Parser sep -> Parser [a]
sepby1 = undefined

sepby :: Parser a -> Parser sep -> Parser [a]
sepby = undefined

intList :: Parser [Int]
intList = undefined

-- ghci> runParser intList "[1, 2, 3]xx"


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 8. Left-associative chains: chainl1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Arithmetic expressions need left associativity:
--   1 - 2 - 3 = (1 - 2) - 3, not 1 - (2 - 3).
--
-- The "obvious" grammar  expr ::= expr "+" term | term  is left-recursive
-- and loops in recursive-descent. chainl1 is the textbook fix:
-- parse one term, then a flat sequence of (op term) pairs, folding left.

chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainl1 = undefined

-- Exercise: define chainr1 for right-associative operators
-- (think 2 ^ 3 ^ 2 = 2 ^ (3 ^ 2)).


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 9. Worked example: a calculator
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Grammar:
--   expr   ::= term   ('+' term   | '-' term)*
--   term   ::= factor ('*' factor | '/' factor)*
--   factor ::= nat | '(' expr ')'

expr, term, factor :: Parser Int
expr   = undefined
term   = undefined
factor = undefined

addop, mulop :: Parser (Int -> Int -> Int)
addop = undefined
mulop = undefined

calc :: String -> Int
calc = undefined

-- ghci> calc "1 + 2 * 3"             -- 7
-- ghci> calc "(1 + 2) * 3"           -- 9
-- ghci> calc "100 - 10 - 1"          -- 89   (left-associative!)
-- ghci> calc "2 + 3 * (4 - 1) / 3"   -- 5


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10. Why this is "just" StateT String []
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
--   H&M name      In StateT String []
--   ---------     -----------------------
--   result        return of StateT s []
--   zero          lift []  ~  StateT (\_ -> [])
--   +++           mplus from MonadPlus
--   >>=           >>= of StateT s m
--   item          StateT (\s -> case s of (c:cs) -> [(c,cs)]; _ -> [])
--   sat p         do { c <- item; guard (p c); return c }
--
-- Replace [] with IO and you get parsers that can do I/O during parsing.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 11. Exercises
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
--  1. Write `between :: Parser open -> Parser close -> Parser a -> Parser a`
--     so that  between (symbol "(") (symbol ")") expr  parses a
--     parenthesised expression.
--
--  2. Define `bool :: Parser Bool` that parses "true" or "false".
--
--  3. Extend the calculator with a unary minus, e.g.  -(1+2) * 3 = -9.
--     Where in the grammar does it belong — factor, term, or expr?
--
--  4. Add support for floating-point literals (parse Double instead of Int).
--
--  5. Tiny JSON subset:
--       value  ::= number | string | bool | null | array | object
--       array  ::= '[' (value (',' value)*)? ']'
--       object ::= '{' (pair (',' pair)*)? '}'
--       pair   ::= string ':' value
--     with
--       data JSON = JNum Double | JStr String | JBool Bool | JNull
--                 | JArr [JSON] | JObj [(String, JSON)]
