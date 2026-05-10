# ImageFilters: A Composable Image-Processing Pipeline

## Motivation

Image-processing toolkits — ImageMagick, GIMP, OpenCV, Pillow, the Photoshop filter pipeline — are built around the same architectural idea: an image is just a 2D array of pixels, a *filter* is a function from images to images, and a pipeline is a composition of filters. That structure happens to be one of the cleanest matches between a real-world problem and functional programming there is: filters are pure functions, composition is `(.)`, and the pipeline as a whole is itself a value the user can pass around. This project takes that idea seriously: read an image, run it through a pipeline of filters declared in code (or in a tiny config file), and write the result.

## Project Overview
This project implements a small image-processing toolkit. The user provides an input image and a pipeline of filters; the program reads the image, applies the filters in order, and writes the result. The filter library should be extensible: adding a new effect should be a matter of writing one function with the right type and registering it.

## Key Goals
1. **Image I/O & Representation**: Read and write at least one common format (PPM is the easiest to parse by hand; PNG via an existing library is fine), and represent the image in a form your filters can work with.
2. **Filter Library & Pipeline**: A library of basic filters (greyscale, threshold, blur, edge detect, brightness/contrast) plus a composition mechanism that lets the user build a pipeline.
3. **Test Suite**: Cover the I/O round-trip, individual filters, and a handful of end-to-end pipelines.
4. **Convolution Engine (stretch)**: Implement filters as convolutions over a kernel matrix, so that adding a new filter (Sobel, Gaussian, sharpen, …) means writing down its kernel rather than its loop.

## Suggested Core Data Types

A starting point — adapt to your design. The right choice for `pixels` depends on what you do with them: `[[Pixel]]` is the easiest to start with; `Data.Array` or `Data.Vector` are faster and saner once filters get non-trivial.

```haskell
data Pixel = Pixel
  { red, green, blue :: ...        -- Word8 or Double in [0,1]; pick one
  | ...
  }

data Image = Image
  { width  :: Int
  , height :: Int
  , pixels :: ...                  -- 2D structure of Pixels
  }

-- A filter is a pure function on images
type Filter = Image -> Image

-- A pipeline is a list of filters applied in order
runPipeline :: [Filter] -> Image -> Image
runPipeline fs img = foldl (flip ($)) img fs
```

Greyscale needs a single intensity per pixel; you may either keep `Pixel` RGB throughout (greyscale = `r == g == b`) or introduce a separate single-channel image type. Either is fine — pick one and stay consistent.

## Example

A pipeline applied to one image, driven from `main`:

```
main = do
  img <- readPPM "in.ppm"
  let out = runPipeline
              [ greyscale
              , gaussianBlur 3
              , sobelEdges
              , threshold 0.4
              ]
              img
  writePPM "out.ppm" out
```

Or driven from a tiny config file:

```
input:  in.ppm
output: out.ppm
pipeline:
  - greyscale
  - blur 3
  - sobel
  - threshold 0.4
```

## Implementation Components

### 1. Image I/O & Representation
- Read at least one image format. PPM (the plain-text P3 variant or the binary P6) is small enough to parse by hand and is the recommended starting point.
- Provide `readImage` and `writeImage` that round-trip — reading then writing should produce a file that, when read back, is byte-identical to the original.
- Decide on your in-memory representation up front; switching it later is more painful than it sounds.

### 2. Filter Library & Pipeline
- Implement a handful of filters: at least greyscale, brightness/contrast, threshold, a blur of your choice, and one edge-detection filter.
- Make filter composition trivial — a list of `Filter` values folded over the image is enough.
- Reject filter parameters outside their valid ranges (negative blur radius, threshold > 1) with a clear error.

### 3. Test Suite
- **Unit tests**: I/O round-trip on a small fixture image; each filter on hand-built tiny images (a 3×3 black image stays black under blur; threshold on a constant image is itself constant).
- **End-to-end tests**: a known-good pipeline applied to a fixture, with the output compared pixel-for-pixel against a saved expected output.
- **Property-based tests**: invariants — every filter preserves image dimensions; greyscale is idempotent (`greyscale . greyscale == greyscale`); threshold-then-threshold with the same parameter is idempotent.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
