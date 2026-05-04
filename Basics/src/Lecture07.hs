module Lecture07 where

import Data.Char (isDigit, isAlpha, isSpace)

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

newtype Parser a = Parser { runParser :: String -> [(a, String)] }


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. Three primitives: result, zero, item
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- result — succeed without consuming input (this is `return`)
result :: a -> Parser a
result v = Parser (\inp -> [(v, inp)])

-- zero — always fail
zero :: Parser a
zero = Parser (\_ -> [])

-- item — consume exactly one character (any character)
item :: Parser Char
item = Parser $ \inp -> case inp of
  []     -> []
  (c:cs) -> [(c, cs)]

-- ghci> runParser item "abc"        -- [('a',"bc")]
-- ghci> runParser item ""           -- []
-- ghci> runParser (result 42) "xy"  -- [(42,"xy")]


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. Functor / Applicative / Monad
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The Monad is the heart of the library — sequencing one parser
-- after another, threading the leftover string through.

instance Functor Parser where
  fmap f p = p >>= return . f

instance Applicative Parser where
  pure  = result
  pf <*> px = pf >>= \f -> px >>= \x -> return (f x)

instance Monad Parser where
  return = pure
  -- (>>=) of StateT String [] written out by hand:
  p >>= f = Parser $ \inp ->
    [ (y, out) | (x, mid) <- runParser p inp
               , (y, out) <- runParser (f x) mid ]

-- Two characters in a row — the second `item` automatically gets the
-- input left over by the first.
twoChars :: Parser (Char, Char)
twoChars = do
  c1 <- item
  c2 <- item
  return (c1, c2)
-- ghci> runParser twoChars "abc"   -- [(('a','b'),"c")]
-- ghci> runParser twoChars "a"     -- []


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4. Choice and failure (MonadPlus-flavoured)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Non-deterministic choice: try BOTH, return all parses of either.
infixr 5 +++
(+++) :: Parser a -> Parser a -> Parser a
p +++ q = Parser (\inp -> runParser p inp ++ runParser q inp)

-- Laws (a "monad with zero and plus"):
--   zero +++ p         ==  p
--   p +++ zero         ==  p
--   (p +++ q) +++ r    ==  p +++ (q +++ r)
--   zero >>= f         ==  zero
--   (p +++ q) >>= f    ==  (p >>= f) +++ (q >>= f)

-- Deterministic choice: keep only the FIRST successful parse.
infixr 5 <|>
(<|>) :: Parser a -> Parser a -> Parser a
p <|> q = Parser $ \inp -> case runParser (p +++ q) inp of
  []    -> []
  (x:_) -> [x]

-- For unambiguous grammars <|> is dramatically faster — no exponential
-- blow-up of alternatives, matches what hand-written recursive-descent does.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 5. Building blocks: sat, char, digit, letter, space, string
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sat :: (Char -> Bool) -> Parser Char
sat p = do
  c <- item
  if p c then return c else zero

char :: Char -> Parser Char
char c = sat (== c)

digit :: Parser Char
digit = sat isDigit

letter :: Parser Char
letter = sat isAlpha

-- (named with a P suffix to avoid clashing with Data.Char.space)
spaceP :: Parser Char
spaceP = sat isSpace

string :: String -> Parser String
string []     = return []
string (c:cs) = do { _ <- char c; _ <- string cs; return (c:cs) }

-- ghci> runParser (string "let") "let x = 1"   -- [("let"," x = 1")]
-- ghci> runParser (string "let") "lemon"       -- []


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 6. Repetition: many and many1
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

many :: Parser a -> Parser [a]
many p = many1 p +++ return []

many1 :: Parser a -> Parser [a]
many1 p = do
  x  <- p
  xs <- many p
  return (x:xs)

-- A non-negative integer.
nat :: Parser Int
nat = do
  ds <- many1 digit
  return (read ds)

-- ghci> runParser nat "123abc"
-- [(123,"abc"),(12,"3abc"),(1,"23abc")]
-- The list monad gives every prefix; replace +++ with <|> in many
-- to keep only the longest match.

-- Exercise: define `int` that also accepts an optional leading '-'.
-- Hint:  (char '-' >> negate <$> nat) <|> nat
int :: Parser Int
int = (char '-' >> fmap negate nat) <|> nat


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 7. Whitespace, tokens, separators
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

spaces :: Parser ()
spaces = do { _ <- many spaceP; return () }

token :: Parser a -> Parser a
token p = do { v <- p; spaces; return v }

symbol :: String -> Parser String
symbol cs = token (string cs)

-- A list of items separated by a separator.
sepby1 :: Parser a -> Parser sep -> Parser [a]
p `sepby1` sep = do
  x  <- p
  xs <- many (do { _ <- sep; p })
  return (x:xs)

sepby :: Parser a -> Parser sep -> Parser [a]
p `sepby` sep = (p `sepby1` sep) +++ return []

intList :: Parser [Int]
intList = do
  _  <- symbol "["
  xs <- token nat `sepby` symbol ","
  _  <- symbol "]"
  return xs

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
p `chainl1` op = do
  x <- p
  rest x
  where
    rest x = (do f <- op
                 y <- p
                 rest (f x y))
             +++ return x

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
expr   = term   `chainl1` addop
term   = factor `chainl1` mulop
factor = token nat
     +++ do { _ <- symbol "("; n <- expr; _ <- symbol ")"; return n }

addop, mulop :: Parser (Int -> Int -> Int)
addop  = (symbol "+" >> return (+))
     +++ (symbol "-" >> return (-))
mulop  = (symbol "*" >> return (*))
     +++ (symbol "/" >> return div)

calc :: String -> Int
calc s = case runParser (do { spaces; n <- expr; return n }) s of
  ((n, "") : _) -> n
  _             -> error "parse error"

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
--
--  6. Re-implement the whole library on top of `StateT String []` from
--     Control.Monad.State and check that nothing changes for the user.
