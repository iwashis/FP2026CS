# Grammar-Based Parsing Language

## Motivation

Parser generators — yacc, bison, ANTLR, Happy, the various PEG tools — let you describe a language's syntax declaratively and produce a parser from that description automatically. They are the foundation of essentially every compiler, configuration loader, query language, and DSL you have ever used. This project sits one level up from "write a parser by hand": you write a *grammar* in a small DSL, and the engine either generates parsing code from it or interprets the grammar directly to parse input strings. It is also a chance to see why some grammars are friendly to a recursive-descent style and others are not — left recursion, ambiguity, and lookahead all show up naturally as soon as you try to build the engine.

## Project Overview
This project implements a small domain-specific language for describing context-free grammars and producing a parser from such a description. Users write grammar rules in an EBNF-like syntax; the system reads a description and either generates code for a parser or interprets the grammar directly to parse input strings.

## Key Goals
1. **Parser Implementation**: Convert grammar descriptions into a structured AST.
2. **Grammar Engine**: Either *generate* a parser (e.g. recursive descent) or *interpret* the grammar to parse arbitrary input — pick one and explain the choice.
3. **Test Suite**: Cover the parser of grammar descriptions, and the parsing behaviour on a handful of small grammars.
4. **Parse-Tree Visualisation (stretch)**: Render the parse tree of a given input under a given grammar in some readable form (text, DOT/Graphviz, …).

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Grammar = Grammar [Rule]

-- A rule names a non-terminal and gives one or more alternatives
data Rule = Rule String [Alternative]

-- An alternative is a sequence of symbols
type Alternative = [Symbol]

-- Symbols appearing in alternatives
data Symbol
  = Term    String          -- a literal terminal
  | NonTerm String          -- reference to another rule
  | Opt     Symbol          -- 0 or 1
  | Many    Symbol          -- 0 or more
  | Many1   Symbol          -- 1 or more
  | ...
```

If you want semantic actions, add them as a separate annotation on alternatives or symbols rather than mixing them into `Symbol` itself.

## Example Grammar
```
// Simple arithmetic expressions
Expr   ::= Term  (("+" | "-") Term)* ;
Term   ::= Factor (("*" | "/") Factor)* ;
Factor ::= Number | Var | "(" Expr ")" ;

Number ::= digit+ ;
Var    ::= letter (letter | digit)* ;
```

How you handle character classes (`digit`, `letter`) — whether they are built-in non-terminals, regex-style classes, or something else — is a design choice.

## Implementation Components

### 1. Parser (of grammar descriptions)
- Parse rule declarations and alternatives.
- Report syntax errors with useful location information.
- Support comments.

### 2. Grammar Engine
- Either generate parsing code (recursive descent is a natural fit) or interpret the grammar directly over an input string.
- Produce a parse tree (or fail with a useful message) for an input that the grammar accepts.
- Detect at least one class of problematic grammars (left recursion is the obvious candidate for a recursive-descent approach) and report them clearly instead of looping.

### 3. Test Suite
- **Unit tests**: parsing of grammar descriptions; building parse trees for tiny grammars by hand.
- **End-to-end tests**: a handful of small grammars (arithmetic expressions, simple JSON, …) with positive and negative inputs.
- **Property-based tests**: for each test grammar, generate strings derivable from the grammar and check that the engine accepts them; randomly mutate them and check that ill-formed strings are rejected.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
