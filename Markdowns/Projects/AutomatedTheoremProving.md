# Automated Theorem Proving Language

## Motivation

Mathematical proof assistants — Coq, Lean, Isabelle, Agda — let mathematicians and software engineers state theorems and prove them mechanically. They sit behind landmark results like the four-colour theorem, the Kepler conjecture, and the formal verification of the seL4 microkernel; they are also the way some industrial software (compilers, cryptographic libraries) is being held to a much higher correctness bar than testing alone allows. This project is a deliberately tiny version of the same idea: a language in which the user states a claim and proves it step by step, and a small engine that checks each step actually follows from the previous ones. The interesting work is not the propositional logic itself — it is walking syntax trees, applying inference rules, and managing a logical context, all of which are textbook applications of functional programming.

## Project Overview
This project implements a small domain-specific language for stating and checking propositional-logic proofs. The language provides constructs for declaring axioms, stating theorems, and building proofs as a sequence of justified steps that an evaluator can verify mechanically.

## Key Goals
1. **Parser Implementation**: Convert textual proof scripts into a structured AST.
2. **Proof Evaluator & Rule Engine**: Validate that each proof step follows from previous facts via the available inference rules.
3. **Test Suite**: Cover the parser, the rule engine, and a handful of small end-to-end proofs.
4. **Interactive Proof Mode (stretch)**: A REPL where the user introduces premises and applies rules step-by-step, with the engine reporting the current goal and remaining obligations.

## Suggested Core Data Types

The shapes below are a starting point only — feel free to adapt them, drop pieces you don't need, or add what your design requires.

```haskell
-- A program is a sequence of top-level statements
data Program = Program [Statement]

-- Propositional formulas
data Formula
  = Var String
  | Const Bool
  | Not Formula
  | BinOp LogOp Formula Formula
  | ...

data LogOp = And | Or | Implies | ...   -- extend as needed (e.g. Iff)

-- Top-level statements
data Statement
  = Axiom   String Formula           -- a named, assumed formula
  | Theorem String Formula Proof     -- a named claim together with its proof
  | ...
```

A `Proof` is a list of justified steps (or a tree of them, or a tactic script) — pick a representation that fits the inference rules you plan to support. Whatever shape you choose, two ingredients are non-negotiable:

- A **context** that tracks the hypotheses currently in scope and the formulas already established in the current proof.
- A **substitution** mechanism. An axiom or rule like `contrapositive : (P -> Q) -> (~Q -> ~P)` is a *schema*: `P` and `Q` stand for any propositions, and applying the axiom means instantiating those schema variables. Without substitution your engine can only check proofs that re-state the axiom verbatim, which is not interesting.

## Example Proof Script
```
theorem and_comm: (A /\ B) -> (B /\ A)
proof
  intro    h    : A /\ B;          -- assume the antecedent
  have     ha   : A           by and_elim_left  h;
  have     hb   : B           by and_elim_right h;
  have     goal : B /\ A      by and_intro hb ha;
  exact    goal;
qed
```

This proof exercises three things the engine has to get right: discharging the introduced hypothesis `h` when the theorem closes, looking up named facts (`h`, `ha`, `hb`) in the current context, and instantiating the conjunction rules at the right propositions. The concrete syntax is up to you — Unicode (`→`, `∧`, `¬`) or ASCII (`->`, `/\`, `~`) are both fine, as long as the parser is consistent.

## Implementation Components

### 1. Parser
- Read proof scripts and produce the AST.
- Report syntax errors with useful location information.
- Support comments.

### 2. Proof Evaluator & Rule Engine
- Maintain a proof context (axioms in scope, hypotheses introduced so far, the current goal).
- Implement substitution of formulas for schema variables, so that an axiom or rule stated once can be applied at any instance.
- Implement a small set of inference rules (your choice — e.g. modus ponens, conjunction intro/elim, implication intro, proof by contradiction).
- Reject proof steps that are not justified by the rules and the available facts.
- Produce a clear error message pointing to the offending step.

### 3. Test Suite
- **Unit tests**: parser round-trips, individual inference-rule applications, rejection of malformed proofs.
- **End-to-end tests**: a handful of small theorems whose proofs the engine should accept (e.g. `A -> A`, `(A /\ B) -> (B /\ A)`, modus-ponens-style chains), plus negative cases that should be rejected (steps with the wrong instantiation, references to facts not in scope).
- **Property-based tests**: a real soundness check — write a small truth-table evaluator for `Formula`, then for every theorem the engine accepts, randomly assign truth values to its propositional variables and verify that the proved formula evaluates to `True` under every assignment. (Anything your engine accepts must be a tautology.) This is the property test that actually pins down the prover; a `parse . pretty == id` round-trip is fine to have alongside but is not a substitute.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `Homework/` folder.
