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

The project does **not** have to define a small language, and it does **not** have to involve a parser. What it must do is split into three coherent components.

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

## Submitting Your Proposal

1. Write the file following the structure above.
2. Send it to the tutor and **wait for approval** before starting on the implementation.
3. Once it is approved, treat the agreed proposal as the contract for the project: the three parts in *Key Goals* are what you will be assessed on.

## Submitting the Completed Project

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder. The same applies whether you picked one of the curated proposals or had your own approved.
