# RegexEngine: Regular Expressions From Scratch

## Motivation

Regular expressions are arguably the most-used mini-language in computing — every text editor, log analyser, build tool, and scripting language ships one. Behind the syntax sits one of the cleanest results in computer science: regexes correspond exactly to finite automata, and that correspondence (Thompson's construction, the subset construction) is the standard worked example of formal-language theory. This project walks through that theory by hand: parse the regex, compile it to an NFA, optionally determinise to a DFA, and run it against input — building, in miniature, the same kind of engine that ends up at the heart of `grep` and `re2`. It is also a chance to feel why pathological regexes (`(a*)*` on long inputs) blow up backtracking engines but not automaton-based ones.

## Project Overview
This project implements a regular-expression engine end-to-end: a parser that turns a regex string into an AST, a compiler that turns the AST into an automaton, and a matcher that runs the automaton against an input string.

## Key Goals
1. **Parser Implementation**: Convert regex strings into a structured AST.
2. **Compiler & Matcher**: Convert the AST into an NFA, then run that NFA against input strings (subset-construction to a DFA is a natural extension).
3. **Test Suite**: Cover the parser, the compiler, and the matcher on a handful of regexes against carefully chosen positive and negative inputs.
4. **Extensions (stretch)**: Add at least one feature beyond the Kleene-algebra core — character classes, anchors (`^`, `$`), bounded repetition `{n,m}`, capturing groups, or DFA minimisation.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
-- The classical four-constructor regex
data Regex
  = Char    Char
  | Concat  Regex Regex
  | Union   Regex Regex
  | Star    Regex
  | Empty                   -- matches the empty string
  | ...

-- An NFA-like representation: states identified by Int, edges either on
-- a character or epsilon
data NFA = NFA
  { nfaStart  :: Int
  , nfaAccept :: Int
  , nfaEdges  :: [(Int, Maybe Char, Int)]
  }
```

If you go further than the core, your AST and automaton types will grow accordingly.

## Example
```
regex pattern = (a|b)*c;
match "abac"   with pattern;       -- expected: no match
match "ababc"  with pattern;       -- expected: match
```

## Implementation Components

### 1. Parser
- Parse alternation `|`, concatenation, Kleene star `*`, and grouping with parentheses, with the conventional precedences.
- Report syntax errors with useful location information (mismatched parens, dangling `*`, …).

### 2. Compiler & Matcher
- Compile a `Regex` into an NFA — Thompson's construction is the natural fit.
- Implement a matcher: simulate the NFA on the input (track the set of currently active states), or first convert it to a DFA and run that.
- A match should answer at least "does the whole input match?"; ideally also "does any prefix match?" or "find the first match in the input".

### 3. Test Suite
- **Unit tests**: parser round-trips; matching individual constructors against trivial inputs.
- **End-to-end tests**: a curated table of regexes paired with both matching and non-matching strings, including pathological cases like `(a*)*` on long inputs.
- **Property-based tests**: cross-check your matcher against Haskell's `Text.Regex` or `Text.Regex.TDFA` on random regexes built from your AST and random input strings.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
