# Baton Club

A better iOS scorer for the Finnish lawn game **Mölkky** — fast to set up, delightful
to score, and built in a heritage lawn-sport aesthetic. Fully **local and offline**:
no account, no backend, no network. Everything lives on the device.

> **v0.1 scaffold.** This is the first cut of the real app, authored to match an
> interactive design prototype. It has **not yet been compiled** (see note below).

## Requirements

- Xcode 16+ (project format uses synchronized file groups, `objectVersion = 77`)
- iOS 17+ (SwiftUI + SwiftData)

## Run it

1. Open `MolkkyApp.xcodeproj`.
2. Pick a simulator (iPhone) and hit **Run**. No signing team needed for the simulator.
3. Fonts are bundled and registered in `MolkkyApp/Info.plist` — no setup required.

## What's here

```
MolkkyApp/
  MolkkyApp.swift          # @main, SwiftData ModelContainer
  Models/                  # Player, Game, GameParticipant (SwiftData @Model)
  Engine/                  # ScoringEngine (pure), GameController (turn flow)
  DesignSystem/            # Palette, Typography (Momo Signature + SUSE), Components
  Screens/                 # Home, NewGameSetup, Scoring, GamesList, Settings, Rules, Overlays
  Resources/Fonts/         # MomoSignature-Regular, SUSE ExtraLight/SemiBold/ExtraBold
  Assets.xcassets/         # AccentColor (chartreuse), AppIcon placeholder
Tests/
  ScoringEngineTests.swift # engine unit tests (see "Tests" below)
```

## Design

- **Palette** (from the moodboard): deep forest `#0C3B2E` / teal `#0B4550` grounds,
  electric chartreuse `#E6FF4B` pop, warm cream `#F9F7F2` paper.
- **Type**: **Momo Signature** (Google Fonts, OFL) for signature-script page headers;
  **SUSE** for all UI in ExtraLight / SemiBold / ExtraBold.
  - The three SUSE weights are static instances baked from the SUSE **variable** font
    at wght 200 / 600 / 800 (the variable font's default instance is *Thin*, which makes
    weight selection unreliable, so we instanced clean static faces). `Font.custom` uses
    the exact PostScript names: `SUSE-ExtraLight`, `SUSE-SemiBold`, `SUSE-ExtraBold`.

## Rules engine

A single throw is always worth **0–12** in Mölkky (one pin = its number, multiple pins =
the count), so scoring input is a 0–12 pad.

The pad stays **hidden between throwers** — a deliberate pause that cuts accidental taps and
gives the scorekeeper a beat to review the board and announce who's up. Tap **"Enter [name]'s
throw"** to reveal it; picking a number confirms and the pad hides again. There is **no undo**:
mistakes are fixed by tapping **any** player to reveal their throws and editing the specific one
(the real error mode), which recomputes everything downstream.

`ScoringEngine` (pure, no UI/SwiftData) applies:

- First to **exactly 50** wins (configurable).
- **Overshoot** the target → reset to **25** (configurable).
- **3 consecutive misses** → eliminated (configurable); **first-timers** get +1 strike
  via a per-player checkmark on the scoring screen.
- **Winner** = reaches target, or last player standing.

All four rules are adjustable per-game from the in-game rules cog.

## Tests

`Tests/ScoringEngineTests.swift` covers accumulation, overshoot reset, exact win,
strike elimination, first-timer strikes, and custom rules. The engine is dependency-free.
To run them, add a **Unit Testing Bundle** target in Xcode and add this file to it.
(The algorithm in these cases was validated during development before this scaffold landed.)

## Not yet done

- Compiled/run in Xcode — this scaffold was authored on Linux (no Xcode available), so a
  first build pass on a Mac is expected to shake out minor fixes.
