---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 7


## Lecture code
Lecture07.hs


## Reference
G. Hutton and E. Meijer, *Monadic Parsing in Haskell*, JFP 8(4), 1998.

---

# A real-life use of `StateT s m` — parsers

Last time we introduced `StateT s m a ≅ s -> m (a, s)`. We will now pick a very particular instance:
```haskell
s = String     -- the input text being consumed
m = []         -- non-determinism: a parser may succeed in many ways
```
Plug those in:
```haskell
StateT String [] a   ≅   String -> [(a, String)]
```
That type is the central object of Hutton & Meijer's 1998 paper *Monadic Parsing in Haskell*. They call it
```haskell
newtype Parser a = Parser (String -> [(a, String)])
```
A `Parser a` takes a string and returns a list of all the ways it can produce a value of type `a` together with the **leftover input** still to be consumed. The empty list `[]` means the parser fails on this input.


---

# Why this composition is the right one

Two effects occur in parsing, and they correspond exactly to the two layers of `StateT String []`:

1. **State** (`StateT String`) — the input is consumed left-to-right. Each step reads a prefix and passes the remainder to the next step.
2. **Non-determinism** (`[]`) — a grammar may admit several parses (ambiguity), or several alternatives may be tried (`p` *or* `q`). The list collects them all.

Putting these two together gives the type
```haskell
String -> [(a, String)]
```
that we called `Parser a`. Notice the order matters: we want the list **inside** so that *each* alternative carries its own leftover string. Stacking `[]` outside `StateT String` would put the non-determinism on the *outside*, which is not what we want.

## A useful sanity check
For every parser `p :: Parser a` and input `inp :: String`:
```
runParser p inp :: [(a, String)]
```
- `[]`             — failure, no parse,
- `[(v, "")]`      — unique complete parse with value `v`,
- `[(v, rest)]`    — unique parse with leftover `rest`,
- `[ (v1,r1), (v2,r2), ... ]` — the grammar is **ambiguous** at this point.

---

# The Parser type — wrapped and unwrapped

We will use the wrapped version (a `newtype` so the compiler keeps the abstraction):
```haskell
newtype Parser a = Parser { runParser :: String -> [(a, String)] }
```
We could equivalently write
```haskell
type Parser a = StateT String [] a
```
and inherit `Functor`, `Applicative`, `Monad`, `Alternative` for free from `StateT` and `[]`. The Hutton–Meijer paper predates monad transformers in their modern form, so it defines everything from scratch — and so will we, to make every step explicit.

## The plan
1. Three primitive parsers: `result`, `zero`, `item`.
2. A `Monad` instance (sequencing).
3. A `MonadPlus`-like instance (choice and failure).
4. Derived combinators: `sat`, `char`, `string`, `many`, `many1`, `sepby`, `chainl1`.
5. A complete arithmetic-expression parser as a worked example.

---

# The three primitives

## `result` — succeed without consuming input
```haskell
result :: a -> Parser a
result v = Parser (\inp -> [(v, inp)])
```
This is the `return` of the parser monad. Compare with `StateT`:
`return v = StateT (\s -> return (v, s)) = StateT (\s -> [(v, s)])`. Same thing.

## `zero` — fail
```haskell
zero :: Parser a
zero = Parser (\_ -> [])
```
The empty list means: this parser produces no result on any input.

## `item` — consume one character (any character)
```haskell
item :: Parser Char
item = Parser $ \inp -> case inp of
  []     -> []                 -- nothing to read → fail
  (c:cs) -> [(c, cs)]          -- read c, leftover is cs
```

## Try it
```haskell
ghci> runParser item "abc"        -- [('a',"bc")]
ghci> runParser item ""           -- []
ghci> runParser (result 42) "xy"  -- [(42,"xy")]
```

---

# Sequencing — the `Monad` instance

The whole point of monadic parsing is that we can *bind* one parser to the next: the leftover of `p` becomes the input of `f x`.
```haskell
instance Monad Parser where
  return = result
  p >>= f = Parser $ \inp ->
    [ (y, out) | (x, mid) <- runParser p inp
               , (y, out) <- runParser (f x) mid ]
```
Read this list comprehension carefully — it threads the state through both parsers and aggregates all alternatives. It is exactly the `>>=` of `StateT String []`.

## Functor and Applicative come for free
```haskell
instance Functor Parser where
  fmap f p = p >>= return . f

instance Applicative Parser where
  pure  = result
  pf <*> px = pf >>= \f -> px >>= \x -> return (f x)
```

## Reading two characters in a row
```haskell
twoChars :: Parser (Char, Char)
twoChars = do
  c1 <- item
  c2 <- item
  return (c1, c2)

ghci> runParser twoChars "abc"   -- [(('a','b'),"c")]
ghci> runParser twoChars "a"     -- []
```
Note how the second `item` automatically gets the input left over by the first.

---

# Choice and failure — `MonadPlus`-flavoured operators

Two parsers in parallel:
```haskell
(+++) :: Parser a -> Parser a -> Parser a
p +++ q = Parser (\inp -> runParser p inp ++ runParser q inp)
```
Read `p +++ q` as "try `p`, *and also* try `q`, return all parses of either". Together with `zero` this gives the structure of a *monad with zero and plus* (today: `Alternative` / `MonadPlus`):

```
zero +++ p     ==   p
p +++ zero     ==   p
(p +++ q) +++ r == p +++ (q +++ r)
```
Plus the distributive laws:
```
zero >>= f      ==   zero
(p +++ q) >>= f ==   (p >>= f) +++ (q >>= f)
```

## Variant: deterministic choice
H&M observe that for unambiguous grammars one only ever needs the *first* successful parse. Define
```haskell
(<|>) :: Parser a -> Parser a -> Parser a
p <|> q = Parser $ \inp -> case runParser (p +++ q) inp of
  []     -> []
  (x:_)  -> [x]
```
Most real grammars use `<|>` because it is dramatically faster — no exponential blow-up of alternatives — and matches what hand-written recursive-descent parsers do.

---

# Building blocks: `sat`, `char`, `digit`, `string`

`item` reads any character. We very rarely want that — usually we want a character satisfying some predicate. Hence:
```haskell
sat :: (Char -> Bool) -> Parser Char
sat p = do
  c <- item
  if p c then return c else zero
```
From `sat` everything else flows:
```haskell
char :: Char -> Parser Char
char c = sat (== c)

digit :: Parser Char
digit = sat isDigit

letter :: Parser Char
letter = sat isAlpha

space :: Parser Char
space = sat isSpace
```

## Matching a fixed string
```haskell
string :: String -> Parser String
string []     = return []
string (c:cs) = do { _ <- char c; _ <- string cs; return (c:cs) }

ghci> runParser (string "let") "let x = 1"   -- [("let"," x = 1")]
ghci> runParser (string "let") "lemon"       -- []
```
Note how naturally recursion on the structure of the input pattern gives us the parser. This is the *combinator* style: parsers are values you build out of smaller parsers.

---

# Repetition: `many` and `many1`

Reading zero or more occurrences of `p`:
```haskell
many :: Parser a -> Parser [a]
many p = many1 p +++ return []

many1 :: Parser a -> Parser [a]
many1 p = do
  x  <- p
  xs <- many p
  return (x:xs)
```
`many1` insists on at least one `p`; `many` is the same but accepts zero.

## A first useful parser: a non-negative integer
```haskell
nat :: Parser Int
nat = do
  ds <- many1 digit
  return (read ds)

ghci> runParser nat "123abc"   -- [(123,"abc"), (12,"3abc"), (1,"23abc")]
```
Two things to notice:
1. `many1 digit` produces *every* possible split — that is the list monad doing its job.
2. If you want only the longest match, use the deterministic `<|>` version of `many` (just replace `+++` with `<|>` in the definition above).

## Exercise
Define `int :: Parser Int` that also accepts an optional leading `'-'`. Hint: `(char '-' >> negate <$> nat) <|> nat`.

---

# Whitespace, tokens, and `sepby`

Most languages allow whitespace between tokens. The standard idiom:
```haskell
spaces :: Parser ()
spaces = do { _ <- many space; return () }

token :: Parser a -> Parser a
token p = do { v <- p; spaces; return v }

symbol :: String -> Parser String
symbol cs = token (string cs)
```
A *token parser* eats trailing whitespace; a top-level parser starts by eating leading whitespace once.

## A list of items separated by a separator
```haskell
sepby1 :: Parser a -> Parser sep -> Parser [a]
p `sepby1` sep = do
  x  <- p
  xs <- many (do { _ <- sep; p })
  return (x:xs)

sepby :: Parser a -> Parser sep -> Parser [a]
p `sepby` sep = (p `sepby1` sep) +++ return []
```
Now we can parse `"[1,2,3]"`:
```haskell
intList :: Parser [Int]
intList = do
  _  <- symbol "["
  xs <- token nat `sepby` symbol ","
  _  <- symbol "]"
  return xs

ghci> runParser intList "[1, 2, 3]xx"   -- [([1,2,3],"xx"), ...]
```

---

# Left-associative chains: `chainl1`

Arithmetic expressions need left associativity: `1 - 2 - 3 = (1 - 2) - 3`, not `1 - (2 - 3)`. The standard combinator is:
```haskell
chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainl1` op = do
  x <- p
  rest x
  where
    rest x = (do f <- op
                 y <- p
                 rest (f x y))
             +++ return x
```
Read it like this:
- parse one `p`,
- then *repeatedly* parse `op` followed by another `p`, folding everything to the left,
- when no further `op` parses, return what we have.

## Why `chainl1` and not plain recursion
The "obvious" recursive grammar
```
expr ::= expr "+" term | term
```
is **left-recursive** — a recursive-descent parser written from it loops forever. `chainl1` is the textbook fix: parse one term, then a *flat* sequence of `op term` pairs, folding as you go.

## Exercise
Define `chainr1` for right-associative operators (think `2 ^ 3 ^ 2 = 2 ^ (3 ^ 2)`).

---

# Worked example: a calculator

Grammar:
```
expr   ::= term   ('+' term   | '-' term)*
term   ::= factor ('*' factor | '/' factor)*
factor ::= nat | '(' expr ')'
```
Translation, almost line for line:
```haskell
expr, term, factor :: Parser Int

expr   = term   `chainl1` addop
term   = factor `chainl1` mulop
factor = token nat
     +++ do { _ <- symbol "("; n <- expr; _ <- symbol ")"; return n }

addop  = (symbol "+" >> return (+))
     +++ (symbol "-" >> return (-))

mulop  = (symbol "*" >> return (*))
     +++ (symbol "/" >> return div)

calc :: String -> Int
calc s = case runParser (do { spaces; n <- expr; return n }) s of
  ((n, "") : _) -> n
  _             -> error "parse error"
```
That is a complete, working, left-associative, precedence-respecting expression parser in about ten lines.

## Try it
```haskell
ghci> calc "1 + 2 * 3"            -- 7
ghci> calc "(1 + 2) * 3"          -- 9
ghci> calc "100 - 10 - 1"         -- 89   (left-associative!)
ghci> calc "2 + 3 * (4 - 1) / 3"  -- 5
```

---

# Why this is "just" `StateT String []`

Every combinator on the previous slides is forced by the choice of monad:

| H&M name      | What it is in `StateT String []`            |
|---------------|---------------------------------------------|
| `result`      | `return` of `StateT s []`                   |
| `zero`        | `lift []`, i.e. `StateT (\_ -> [])`         |
| `+++`         | `mplus` from `MonadPlus`                    |
| `>>=`         | `>>=` of `StateT s m`                       |
| `item`        | `StateT (\s -> case s of (c:cs) -> [(c,cs)]; _ -> [])` |
| `sat p`       | `do { c <- item; guard (p c); return c }`   |

So if you build the same library on top of `StateT String []` you get *exactly* the same parsers, just with `lift`, `get`, `put`, and `mplus` written instead of bespoke names.

## Lift to `StateT String IO`?
Replace `[]` with `IO` and you get a parser that can do I/O during parsing — useful for `#include` directives, dynamic loading, etc. Same combinators, just a different inner monad.

---

# What modern libraries change

The Hutton–Meijer parser is wonderful for teaching. Industrial parser libraries (`parsec`, `megaparsec`, `attoparsec`) refine it in three ways:

1. **Better error reports.** They track an error position and a "what was expected" set, so you do not just get `[]` but a useful message.
2. **Predictive parsing.** They commit after consuming any input (the `try` combinator marks the only places you may backtrack). This rules out exponential blow-ups and gives `O(n)` parsing for `LL(1)` grammars.
3. **Streaming input.** The state is not a `String` but an efficient `Text`/`ByteString` cursor.

But the *core* — a state monad of input strings layered with a non-determinism / failure monad — is still exactly what we built today.

---

# Exercises

1. Write `between :: Parser open -> Parser close -> Parser a -> Parser a` so that `between (symbol "(") (symbol ")") expr` parses a parenthesised expression.

2. Define `bool :: Parser Bool` that parses `"true"` or `"false"`.

3. Extend the calculator with a unary minus, e.g. `-(1+2) * 3 = -9`. Where in the grammar does it belong — in `factor`, `term`, or `expr`?

4. Add support for floating-point literals to the calculator (parse with `Double` instead of `Int`).

5. Write a parser for a tiny JSON subset:
```
value  ::= number | string | bool | null | array | object
array  ::= '[' (value (',' value)*)? ']'
object ::= '{' (pair (',' pair)*)? '}'
pair   ::= string ':' value
```
You will need a sum data type `data JSON = JNum Double | JStr String | JBool Bool | JNull | JArr [JSON] | JObj [(String, JSON)]` and one parser per constructor.

6. Re-implement the whole library on top of `StateT String []` from `Control.Monad.State`. Check that nothing changes from the user's point of view.
