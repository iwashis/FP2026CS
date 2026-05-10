# TEMPLATE: Proposing Your Own Project

The other files in this directory are projects you can pick from directly. If none of them appeals, you are welcome to propose your own — this file describes what such a proposal must look like.

> **Important:** every self-proposed project must be discussed with the tutor and **agreed in advance**. Do not start work on a project of your own design before you have written it up and had it approved. If you have an idea, write it down following the outline below and bring it to office hours or send it over for review.

The proposal itself is a single Markdown file in this folder, written in the same style as the existing ones. Read two or three of them before you start — for instance `RegexEngine.md`, `SpreadsheetLang.md`, and `BuildSysLang.md` — to get a feel for the tone and the level of detail.

## What Every Proposal Must Have

Whatever the topic, every project — chosen or self-proposed — has **three parts**. Roughly equal effort goes into each; if one part is much smaller than the others, the scope is wrong.

- **Part 1 and Part 2 — two project-specific components.** What these are depends on what the project does. The two parts should be the things that *together* make the project work end-to-end. Any of the following pairings (and many others) are reasonable:
  - parser + interpreter (the most common shape in this folder, but **not required**)
  - simulator + analysis pass
  - representation + algorithm (e.g. a graph data structure + a search procedure)
  - server + client
  - core library + a small CLI / web / GUI front-end
  - data ingestion + a query/reporting layer
- **Part 3 — Test Suite.** This part is **mandatory and identical for every project**. See *The Test Suite* below.

The project does **not** have to define a small language, and it does **not** have to involve a parser. What it must do is split into three coherent, testable components.

## Required Structure of the Proposal File

Use the following section headings, in this order. Adapt the section names of Part 1 and Part 2 to your project; keep `## Test Suite` exact.

```
# <ProjectName>: <one-line tagline>

## Motivation
<one paragraph: where this idea comes from in the real world (which
 systems / fields use it), and why it is worth building a small version
 of it. This section is for context — say *why* before you say *what*.>

## Project Overview
<one short paragraph: what the project is, what a user can do with it,
 and why it is interesting>

## Key Goals
1. **<Part 1 name>**: ...
2. **<Part 2 name>**: ...
3. **Test Suite**: ...
4. **<Stretch Goal>** (optional): ...

## Suggested Core Data Types
<a Haskell code block sketching the central data structures, plus a
 short note that the shapes are a starting point only>

## Example
<a small concrete example: input the user gives, output the system
 produces — one screenful at most. If your project does define a small
 language, this is an example program; otherwise it can be sample
 input/output, a session transcript, a usage snippet, etc.>

## Implementation Components
### 1. <Part 1 name>
- ...
### 2. <Part 2 name>
- ...
### 3. Test Suite
- **Unit tests**: ...
- **End-to-end tests**: ...
- **Property-based tests**: ...
```

## The Test Suite

Tests are not an afterthought. Every project's test suite has the same three layers:

- **Unit tests** — small, fast checks for individual functions in isolation. One function, one expected behaviour per test.
- **End-to-end tests** — a handful of complete scenarios run all the way through the system, with the expected outcome computed by hand and compared against the program's output. These are the only tests that catch wiring mistakes between Part 1 and Part 2.
- **Property-based tests** — invariants checked against randomly generated inputs (round-trips, conservation laws, monotonicity, agreement with a reference implementation). One or two strong properties are worth more than ten weak ones.

A test plan without all three layers is incomplete.

## Notes on the Other Sections

- **Motivation** — one paragraph. Connect the project to the real-world systems or ideas it abstracts (which industrial tools use this pattern? which area of CS does it draw from?) and say why it is worth building a small version. This is *not* about your implementation; it is about why the project deserves to exist.
- **Project Overview** — one paragraph. Say what the project does and what makes it interesting; do *not* describe the implementation here.
- **Key Goals** — four bullet points, mirroring the structure above. The fourth is a **stretch goal**: something genuinely interesting that you would do *if* the first three parts work. Pick one you would actually attempt.
- **Suggested Core Data Types** — sketch the central data structures (use Haskell). Stay generic: prefer one constructor with a parameter over enumerating every special case. Add one line saying the shapes are a starting point and the reader is welcome to adapt them. The other proposals in this folder show the right level of detail.
- **Example** — short, concrete, and consistent with the data types you sketched. If your example refers to a feature your data types cannot represent, either extend the types or simplify the example — the two must agree.
- **Implementation Components** — say *what* each part must do, not *how*. "Detect cycles in the dependency graph" is fine; "use Tarjan's algorithm with a pre-order index stack" is too much detail for a proposal.

## What to Avoid

- **Vague core parts.** "Implement an engine that runs the program" is not a goal. Say what the part *does* with its inputs.
- **Stretch goals dressed up as core.** If your "Key Goal #2" is "implement a JIT compiler", you have either picked too much or mislabelled the stretch goal as core.
- **Test plans without invariants.** `prop_works x = engine x /= error` is not a property-based test; `prop_parse_roundtrip x = parse (pretty x) == x` is.
- **Skipping approval.** A polished proposal you wrote without talking to the tutor is still an unapproved proposal — talk first, polish second.

## Submitting Your Proposal

1. Write the file following the structure above and save it in this directory under a short, descriptive name (e.g. `MyProject.md`).
2. Send it to the tutor or bring it to office hours and **wait for approval** before starting on the implementation.
3. Once it is approved, treat the agreed proposal as the contract for the project: the three parts in *Key Goals* are what you will be assessed on.

## Submitting the Completed Project

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder. The same applies whether you picked one of the curated proposals or had your own approved.
