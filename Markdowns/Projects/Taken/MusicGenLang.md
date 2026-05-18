# MusicGenLang: Algorithmic Music Composition

## Motivation

Algorithmic and live-coded music — TidalCycles, Sonic Pi, SuperCollider, ChucK — has grown into a real performance and research community, and music generation has become one of the better playgrounds for procedural-content and ML work. Underneath the artistry, generating music is a textbook FP problem: a recursive structure (notes inside measures inside parts inside songs) is folded into a flat sequence of timed events. Repetition, transposition, and variation are simple combinators on those structures. This project is a small DSL for describing such structures and a small engine that turns them into events — and, optionally, into a MIDI file that an actual player can open.

## Project Overview
MusicGenLang is a small domain-specific language for describing musical patterns and lightweight algorithmic composition rules. Programs declare instruments and a sequence of notes (or pattern-generating rules); the runtime turns them into a concrete sequence of timed events.

## Key Goals
1. **Parser Implementation**: Convert scores into a structured AST.
2. **Music Engine**: Interpret the score into a flat sequence of timed events `(time, pitch, duration, velocity)`.
3. **Test Suite**: Cover the parser, the engine, and a handful of small scores with hand-computed event sequences.
4. **MIDI Export (stretch)**: Serialise the generated event sequence to a standard MIDI file that a regular player can open.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Score = Score
  { tempo :: Int           -- BPM
  , parts :: [Part]
  }

data Part = Part
  { instrument :: String
  , body       :: [Item]
  }

-- Items in a part: literal notes, rests, repetitions, ...
data Item
  = Note   Pitch    Duration
  | Rest   Duration
  | Repeat Int      [Item]
  | Group  [Item]               -- a useful nesting form for rules
  | ...

data Pitch    = Pitch Char Int Int   -- letter, accidental (-1..1), octave
data Duration = Whole | Half | Quarter | Eighth | Sixteenth | ...
```

If you want algorithmic generation (e.g. arpeggios, scales, transposition), add operators that build `[Item]` from a smaller specification.

## Example Score
```
song "AlgoBeat" tempo 120 {
  instrument piano {
    repeat 4 {
      C4 q  E4 q  G4 q  C5 q
    }
  }
}
```

## Implementation Components

### 1. Parser
- Parse song headers, instruments, repetitions, and note literals (pitch + duration).
- Report syntax errors with useful location information.
- Support comments.

### 2. Music Engine
- Convert the score into a list of timed events: each event has a start time (in seconds or ticks), a pitch, a duration, and a velocity.
- Handle repetitions and grouping correctly — the second occurrence starts where the first ended.
- Use the score's tempo to convert symbolic durations into real time.

### 3. Test Suite
- **Unit tests**: parser correctness; that a single `Note Quarter` at 120 BPM lasts 0.5 s; that `Repeat n body` produces `n` concatenated copies.
- **End-to-end tests**: small scores whose event sequences you can compute by hand, compared against the engine's output.
- **Property-based tests**: invariants — for each individual `Part`, the time of the last event plus its duration equals the sum of that part's `Item` durations (parts run in parallel, so summing across parts would be wrong — the *score's* total duration is the maximum over parts, not the sum); transposing every pitch by `+k` shifts every event's pitch by exactly `+k`; doubling the tempo halves every event's start time and duration.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
