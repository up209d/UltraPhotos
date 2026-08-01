# UltraPhotos

A macOS **Photos editing extension** that applies 3D LUT (`.cube`) color grades to
photos, non-destructively, from inside Apple's Photos app.

The extension — `FilterPlus` — shows a live before/after preview, a scrollable
strip of LUT thumbnails rendered from the photo you are actually editing, and an
intensity slider that blends the graded image back over the original.

## Features

- **3D LUT color grading** via `CIColorCubeWithColorSpace`, forced to sRGB IEC61966-2.1.
- **Adjustable intensity** — the LUT result is blended over the source through a
  constant-alpha mask (`CIBlendWithAlphaMask`), so 0–100 is a true opacity mix.
- **Live thumbnail strip** — every bundled LUT is rendered against a 256px
  downscale of the current photo, in parallel on background queues, so the
  previews reflect your image rather than a generic swatch.
- **Hold-to-compare** — press the preview button to fade the graded preview out
  and reveal the original underneath.
- **Non-destructive edits** — the selected LUT path and intensity are persisted in
  `PHAdjustmentData` (format identifier `com.up209d.dev`), so reopening the photo
  in the extension restores the previous edit instead of baking it in.

## Requirements

| | |
|---|---|
| Xcode | 16 or newer (project `objectVersion` 77) |
| macOS | 15.0+ (app and extension); project base SDK 15.5 |
| Swift | 5.0 |
| Signing | Your own team — bundle IDs are namespaced under `com.up209d.dev` |

## Project layout

```
UltraPhotos.xcodeproj
├── UltraPhotos/          # Host app (SwiftUI + SwiftData). Currently the stock
│   │                     #   Xcode template — it exists to ship the extension.
│   ├── UltraPhotosApp.swift
│   ├── ContentView.swift
│   └── Item.swift
│
├── FilterPlus/           # The Photos editing extension (the real project)
│   ├── PhotoEditingViewController.swift   # PHContentEditingController: LUT parsing,
│   │                                      #   CoreImage pipeline, preview + export
│   ├── LUTSelectionViewController.swift   # NSCollectionView data source/delegate
│   │                                      #   for the LUT thumbnail strip
│   ├── LUTThumbnail.swift                 # Programmatic NSCollectionViewItem
│   ├── Clickable.swift                    # NSButton/NSImageView with mouse-down/up hooks
│   ├── Cache.swift                        # In-memory NSImage cache (not yet wired up)
│   ├── Error.swift
│   ├── Base.lproj/PhotoEditingViewController.xib
│   └── LUTs/                              # Bundled .cube files
│
├── PhotoExtension/       # Superseded first attempt at the extension. Present as a
│                         #   file group only — it is not a build target.
│
├── UltraPhotosTests/     # Stock template tests
└── UltraPhotosUITests/
```

Targets in the project: `UltraPhotos` (app), `FilterPlus` (app extension),
`UltraPhotosTests`, `UltraPhotosUITests`.

## Building and running

1. Open `UltraPhotos.xcodeproj` in Xcode.
2. Select your own development team for both the `UltraPhotos` and `FilterPlus`
   targets (Signing & Capabilities). Both are sandboxed with
   `com.apple.security.files.user-selected.read-only`.
3. Build and run the `UltraPhotos` scheme once. Launching the host app registers
   the bundled extension with the system.
4. Enable the extension: **System Settings → Privacy & Security → Extensions →
   Photos Editing** → tick **FilterPlus**.
5. In **Photos**, open an image → **Edit** → the extension menu (`•••`) → **FilterPlus**.

To debug the extension itself, run the `FilterPlus` scheme and pick **Photos** as
the host application.

## Adding your own LUTs

Drop `.cube` files into `FilterPlus/LUTs/` and add them to the `FilterPlus`
target's *Copy Bundle Resources* phase. At runtime the extension scans the
directory containing `Default.cube` inside the bundle and lists every `.cube`
it finds, so no code change is needed.

Notes on the parser in `loadCubeLUT(from:)`:

- `LUT_3D_SIZE` is required; `DOMAIN_MIN` / `DOMAIN_MAX` lines are skipped rather
  than applied, so LUTs relying on a non-`0…1` domain will not grade correctly.
- Comments (`#`) and blank lines are ignored.
- Each RGB triplet is expanded to RGBA with `a = 1.0` for `inputCubeData`.

`Default.cube` is a 2×2×2 identity LUT and is treated specially: it is the
fallback when nothing is selected and is always sorted to the front of the
thumbnail strip.

Free `.cube` packs used during development came from
[luts.iwltbap.com](https://luts.iwltbap.com/).

## Known gaps

- `PhotoExtension/` and its shared scheme are dead weight from an earlier
  iteration and can be deleted.
- The `Cinematic 0*.cube` files at the repository root are duplicates of the ones
  in `FilterPlus/LUTs/` and are not referenced by any target.
- `Cache` is implemented but never used — thumbnails are re-rendered on every
  editing session.
- The host app is still the SwiftUI/SwiftData template and does nothing useful.
- `LUTProcessor.createCubeData(from:dimension:)` returns an all-zero identity
  stub; the live code path does not use it.

## License

No license file is present. All rights reserved by the author unless one is added.
