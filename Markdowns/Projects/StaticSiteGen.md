# StaticSiteGen: A Tiny Static Site Generator

## Motivation

Static site generators — Jekyll, Hugo, Eleventy, Hakyll, Zola — power a large fraction of the web's documentation, blogs, and project landing pages. They sit in a sweet spot: the user writes content as Markdown with a tiny bit of metadata, the generator turns it into a complete HTML site once at build time, and the output is then trivially cheap to serve. Underneath, the job is a clean three-step pipeline — read content, apply templates, write files — that lends itself unusually well to functional programming. (Hakyll, the Haskell entry, is itself a strong existence proof.) This project is a small static site generator: one command turns a directory of source files into a directory of HTML.

## Project Overview
This project implements a small static site generator. The user maintains a folder of Markdown posts and HTML templates; the generator reads them, slots each post into the right template, copies static assets (CSS, images), and writes the result to an output folder ready to be served.

## Key Goals
1. **Content Loader**: Walk the input directory, parse front matter, and produce an in-memory representation of every page and post.
2. **Site Builder**: Apply templates, write the resulting HTML, and copy static assets to the output directory.
3. **Test Suite**: Cover the loader, the builder, and a handful of small example sites.
4. **Incremental Build (stretch)**: On a re-run, rebuild only the pages whose source (or whose template) actually changed, leaving the rest of the output directory alone.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
-- One source page: its metadata and its content
data Page = Page
  { pagePath  :: FilePath          -- where it lives in the input tree
  , pageMeta  :: [(String, String)]  -- key/value pairs from the front matter
  , pageBody  :: String            -- raw Markdown body
  }

-- A template: a name plus the template text (with placeholders like {{title}})
data Template = Template
  { tmplName :: String
  , tmplBody :: String
  }

-- The collected site, ready to render
data Site = Site
  { sitePages     :: [Page]
  , siteTemplates :: [Template]
  , siteAssets    :: [FilePath]
  }
```

You can use an existing Haskell Markdown library (e.g. `cmark` or `pandoc`) for the Markdown-to-HTML step — that part is not the project. The interesting work is everything around it.

## Example

Input directory:

```
site/
  templates/
    default.html
  posts/
    2026-04-01-hello.md
    2026-05-10-followup.md
  static/
    style.css
```

A post (`hello.md`) starts with front matter:

```
---
title: Hello, world
date: 2026-04-01
---

Welcome to my site.
```

Running `stack run -- build site/ out/` produces `out/posts/2026-04-01-hello.html`, `out/posts/2026-05-10-followup.html`, `out/static/style.css`, and an `out/index.html` listing the posts.

## Implementation Components

### 1. Content Loader
- Walk the input directory and discover pages, templates, and assets.
- Parse YAML/TOML-style front matter at the top of each post into a key/value map; report an error if the front matter is malformed.
- Build the in-memory `Site` representation.

### 2. Site Builder
- For each page, pick the template named in its front matter (or a default), substitute placeholders, write the resulting HTML to the right path under the output directory.
- Copy static assets through unchanged, preserving directory structure.
- Generate at least one *index* page that lists the posts in some order (e.g. by date, descending).
- Fail loudly on missing templates or unknown placeholders, instead of silently producing broken output.

### 3. Test Suite
- **Unit tests**: front-matter parsing on hand-written examples; template substitution on small templates; asset path resolution.
- **End-to-end tests**: a small sample site checked into the test fixtures, built into a temp directory, with the produced files compared against expected output.
- **Property-based tests**: invariants — running the build twice in a row produces byte-identical output; every input page produces exactly one output HTML file.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
