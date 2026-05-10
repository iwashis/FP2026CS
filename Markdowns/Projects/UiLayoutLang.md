# UiLayoutLang: Declarative UI Layout

## Motivation

Layout engines — Flexbox, CSS Grid, Yoga (the engine inside React Native), the layout systems behind Flutter and SwiftUI — turn nested boxes-with-constraints into pixel-accurate positions on the screen. The job sounds mundane until you try it: a mix of fixed pixels, percentages, and content-driven sizing has to compose in a way that always converges to a sensible answer, even on inputs the author of the layout never imagined. This project is a stripped-down version of a Flexbox-style engine: a tiny DSL for declaring nested boxes plus a layout engine that resolves them to absolute coordinates. It is also a satisfying domain in which to write *property-based* tests, because most of what a layout engine should do can be expressed as invariants ("no child sticks out of its parent").

## Project Overview
UiLayoutLang is a small declarative language for describing UI layouts as nested boxes — a stripped-down Flexbox. Programs declare a tree of boxes with size and direction properties; the engine computes the absolute position and size of every box for a given window size.

## Key Goals
1. **Parser Implementation**: Convert layout descriptions into a structured AST.
2. **Layout Engine**: Compute the absolute `(x, y, width, height)` of every box from the tree of constraints.
3. **Test Suite**: Cover the parser, the layout engine, and a handful of small layouts with hand-computed positions.
4. **Renderer (stretch)**: Render the resolved layout — to an image (PNG/SVG) or a simple terminal/window canvas — so that the result can be inspected visually.

## Suggested Core Data Types

A starting point — adapt to your design. Sizes can be absolute (in pixels) or proportional (as a fraction of the parent), so `Size` carries both forms.

```haskell
data Layout = Box Props [Layout]

data Props = Props
  { width  :: Size
  , height :: Size
  , dir    :: Direction
  , color  :: Maybe String
  }

data Size      = Px Int | Pct Double | ...   -- 0.0 .. 1.0 for Pct
data Direction = Row | Col | ...

-- Result of layout: every box gets absolute coordinates
data Resolved = Resolved
  { rx, ry, rw, rh :: Int
  , rChildren      :: [Resolved]
  }
```

How you split leftover space when children's sizes are *smaller* than the parent (give the rest to the last child? distribute evenly?) is a design decision — pick one and document it. **Overflow** (children larger than the parent), on the other hand, is not a free design choice: the engine must clamp the layout so that no child sticks out of its parent. Two standard rules — both acceptable — are (a) clip each child to the parent's remaining space along the layout axis, or (b) scale all children proportionally so their sizes sum to the parent. Whichever you pick, the property test below assumes it.

## Example Layout
```
window "Main" 800 x 600 {
  row {
    box { width: 20%, height: 100%, color: red  }
    box { width: 80%, height: 100%, color: blue }
  }
}
```

## Implementation Components

### 1. Parser
- Parse window declarations, `row`/`col` containers, and box property blocks.
- Report syntax errors with useful location information.
- Support comments.

### 2. Layout Engine
- Compute `(x, y, w, h)` for every box, top-down, given the window size.
- Handle a mix of absolute and percentage sizes within the same container.
- Be deterministic — the same input must always produce the same `Resolved` tree.

### 3. Test Suite
- **Unit tests**: parser correctness; per-property behaviour (a single box with `width: 100%` fills the parent; a row with two `50%` children splits exactly at the middle).
- **End-to-end tests**: small layouts whose box positions you compute by hand.
- **Property-based tests**: invariants — every child's bounding box lies inside its parent's; the sum of children's sizes along the layout axis is at most the parent's size along that axis (these two only hold because of the overflow rule fixed above; if you skip that rule, the invariants will fail on randomly generated layouts).

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
