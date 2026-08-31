@AGENTS.md
# Fiken — build brief

## Fill this in before you send it

- **Platform:** _(SwiftUI + Core Haptics / Jetpack Compose / other)_
- **Repo state:** _(empty repo / existing project at `<path>` / Xcode project already set up)_
- **Figma file:** _(paste the file link, and node links for individual frames if you have them)_

Everything below assumes SwiftUI with Core Haptics. If you're on Android, say so — the haptics
sections change, because `VibrationEffect.Composition` can't do continuous intensity ramps, and
the massage fidget needs redesigning around discrete texture instead.

---

## The app

Fiken is a fidget app. Each screen is one fidget — a thing you touch that pushes back with
haptics. The whole thing is drawn to look hand-sketched in ink on cream paper.

The core use case: someone opens it on their phone while watching something on a laptop, and
uses it **without looking at the screen**. That constraint drives most of the design decisions
below, and it's the thing to protect when you're making judgement calls.

## Design system

Everything is drawn. There are no stock system controls, no SF Symbols, no photographs, and no
solid filled shapes larger than a thumbprint.

**Colour** — only three values:
- paper `#F2EFE6`
- ink `#1A1A1A`
- pencil accent `#B4463C` (lifts to `#D9705F` in dark mode, or it disappears against ink)

Dark mode swaps paper and ink and redraws. It is not an inversion filter.

**Type**
- `Fredericka the Great` — titles and big numbers only. It falls apart below 24pt.
- `Special Elite` — body text, labels, captions.

**The sketch look** — three techniques, applied consistently:

1. *Hatching.* Always at 45°, never any other angle. Default spacing 6px, stroke width 1.1.
   When something needs to read darker, tighten the spacing (range 3.6–9.5px) — never change
   the angle. Only hatch strokes thick enough to carry it, not every surface.
2. *Wobble.* Resample each path edge every ~14px and offset each point by ±0.9px. Past about
   ±1.5px it stops reading as a steady hand and starts looking broken.
3. *Double outline.* Draw every outline twice — second pass at 0.6× width and 55% opacity, with
   fresh wobble. This is what stops it looking like a traced vector.

Stroke weights: outline 2.4, detail 1.6, hatch 1.1.

**The boil.** At runtime, regenerate the wobble and hatch offsets with a new seed at ~8fps. The
drawings appear to breathe. This is the app's signature effect and it must be defeatable from
settings (some people find that much motion unpleasant, and it costs battery).

## Working from the designs

The SVG files are the source of truth for layout and proportion. Every hatch line and wobble in
them is a real baked path, because Figma drops SVG filters and pattern fills on import.

**Do not port the baked paths into the app.** Generate the geometry procedurally so it can boil
and animate. The SVGs tell you *what it should look like*; the parameters above tell you *how to
make it*.

Each design file has a "Build" panel artboard on the right with the specific numbers for those
screens. Read those before implementing a screen.

## Screens

Nine total. Each fidget is a full-screen page.

### 1. Light switch
Thumb-sized lever, centre screen. **A click anywhere on screen throws it** — anywhere, not on the
lever, so there is still nothing to aim at. The lever overshoots slightly on the snap. Flipping
it off inverts the entire page. One sharp impact haptic fired the moment the lever hits the
stop, **not** on release; timing it to the visual rather than the touch is what sells it.

The page **keeps its colour mode** either way — only the lever and the ON/OFF labels change.
(It used to invert the whole page when switched off. That made the light switch the one screen
whose appearance fought the rest of the app, and it fought the Paper setting too.)

The impact is a compound pattern — a sharp transient over a short decaying continuous event.
A lone transient caps out at intensity 1.0 and still reads thin; the continuous layer is what
gives it mass.

### 2. Fidget spinner
Angular velocity from the flick, then `v *= 0.98` each frame. One haptic tick every time
accumulated rotation crosses 2π/3, so the tick rate slows as the spinner winds down and you feel
it losing energy.

- The bearing is drawn **outside** the rotating group and never moves. This is what makes the
  rotation read as fast — don't nest it.
- Hatching is generated in the body's own coordinate space, so it rotates with the object. The
  ink is on the object, not on the screen.
- Ghost strokes trail at −46°/−30°/−15° with opacity 0.16/0.26/0.42. Outline only — hatched
  ghosts turn to grey mush at speed.
- Hatch spacing opens from 6px to 7.5px while spinning, so the body reads lighter at speed.
- Geometry: hub r52 hole 32; three lobes r60 at distance 104, holes 34, at −90°/30°/150°.

The tick is a compound impact — a transient at intensity 1.0, sharpness 0.8, over a 20ms
continuous body. A bare transient caps at 1.0 and still reads thin; the body is what gives it
weight. Ticks are capped at 45Hz: above that they stop resolving as separate events anyway, and
each one costs a pattern and a player to build.

The 0.98 is a starting point — expect to tune it by thumb.

### 3. Finger massage
Four fingers rest on the screen. A drawn wave is both the control and the readout: drag anywhere
on the strip and the wave grows taller. Amplitude maps to haptic intensity 0.0–1.0; sharpness
stays fixed at 0.35 (soft, not buzzy); frequency never changes. Hatch density under the wave
tightens from 9.5px to 4.5px as level climbs.

**Important physical constraint:** the phone has one taptic engine. The four pads *cannot* buzz
independently. Sequence them instead — fire in a roll, index to little, 40ms apart. The
vibration is global but your brain assigns it to whichever pad just lit up. If that illusion
doesn't hold up when we test it, fall back to two alternating contact zones.

Finger guide dashes fade to zero over 300ms once all four contacts are detected.

### 4. Detent dial
Rub a circle anywhere on screen. Transient at intensity 0.5, sharpness 0.8, one per 15° of arc
travel. Infinite in both directions — no start, no end, no zero to wind back to, and no pointer
(a pointer implies a value this doesn't have).

### 5. Bubble wrap
4×6 grid at 78px pitch — roughly thumb width, so there's no gap you can land in and miss.
Transient at 0.9/0.9, one per pop, never repeats. Popped bubbles become slack wrinkled skin and
stay popped for **two seconds and then grow back on their own**, so the sheet never runs out and
there is nothing to reach for. Long enough that a bubble stays popped under your thumb, short
enough that a sweep back across the sheet finds it full again. (This replaced first a shake, then
a refill button — both of which made you stop fidgeting to do housekeeping. Glass still resets on
shake, because a cracked pane is meant to accumulate.)

### 6. Zipper
Drag along any vertical path. Transient at 0.6/0.7, tick rate follows finger speed across
6–40Hz. Reverse direction to re-zip. Teeth splay above the slider and mesh below it.

### 7. Glass
Tap anywhere; cracks spread from the contact point. Burst haptic: one heavy transient over a
short continuous body, then six taps decaying over 400ms, intensity 1.0 → 0.15, sharpness 0.9.
Accumulates without limit; resets on shake.

Crack generation: walk outward from the impact with small angle jitter, add branches, then join
the radials with three irregular concentric rings. Those rings are what make it read as glass
rather than a spider web.

Cracks are **unlimited** — keep tapping and the pane keeps going. Only the six most recent stay
live and boiling; older ones are baked once into a single static path, or an hour-old pane would
be rebuilding every crack it ever drew on every boil frame.

### 8. Settings
Rows: paper (light/dark), sound (off by default), strength (0.4/0.7/1.0),
go dark (never/4s/10s — **defaults to never**), fingers (left/right),
paper boil. Then a "Feel it" button that fires one of each kind of haptic in the app
back to back.

Selection is **circled**, not filled — a solid highlight block is the one thing that would make
this look like a normal settings app.

### 9. About the maker — **not built, and currently unreachable**
The settings entry point was removed, so nothing links here. Left in the brief in case it comes
back. Static content, not a form. Ship a bundled `about.json` with name, role, five lines of text, and
up to three links. No text fields, no keyboard, no storage. Fields are ruled lines you write on,
not bordered input boxes.

## Interaction model

- **Navigation is a tab on the left edge.** Tap it and a panel slides out listing the fidgets by
  name; tap a name to go there. The order is bubble wrap, spinner, zipper, dial, light switch,
  glass, massage — set by the declaration order of `FidgetRouter.Fidget`. Selection in that list is circled, like everything else.
  (This replaces the original shake-to-cycle: shaking fired by accident too easily to be the
  only way between screens. Shake detection stays in the codebase — bubble wrap refills and
  glass resets still need it.)
- **Arriving anywhere fires one long swell.** The same feel every time — switching fidget, and
  leaving the opening screen.
  (This replaces the four distinct per-fidget signatures. Those existed so you could tell where
  blind shake-cycling had dumped you; now you pick a fidget by name from the left tab, so you
  already know, and four different arrivals only made the switch feel inconsistent.)
- **The screen stays on by default.** Out of the box the drawing stays visible the whole time.
  "Go dark" is opt-in from settings: with 4s or 10s selected the screen blanks after that much
  continuous contact, and **comes straight back the moment you let go**. The dark screen never
  takes a touch, so the fidget carries on underneath it — that is the whole point of blanking.
  When it *is* enabled the original reasoning holds: the drawings are onboarding, you look once
  to learn the gesture, and blanking saves the battery cost of a whole episode.
- Screen-off being optional does **not** relax the eyes-free rule. Every fidget still has to work
  without aiming: whole screen is the target, nothing smaller than a thumb.
- **Settings lives behind three bars** in the top-right corner, in the same spot on every screen.
- Sound effects layer under the haptics and are **off by default**. Most people open this next to
  something already playing — the audio session is `.ambient` with `.mixWithOthers`, so Fiken
  never interrupts what is already going and honours the ring/silent switch.
- **Every sound is synthesised at launch, not loaded from a file.** The drawings are generated
  rather than shipped, and the audio works the same way: a few kilobytes of code instead of
  megabytes of samples, no licensing, and each voice rendered in several differently-seeded
  variants so a run of pops sounds like a run of bubbles rather than one sample repeated.
  Eight voices — tick, clack, detent, pop, zip, crack, roll, swell — each normalised to the same
  headroom so `Voice.gain` is the only thing setting relative loudness.
- **Every voice is noise plus a pitched body.** Noise is what makes a sound read as a physical
  object rather than a synthesiser: a pop without it is a bloop, a zipper without it is a note.
  A pass that removed the noise entirely made the whole palette sound animated and fake — the
  calm has to come from where the pitch sits and how fast it decays, not from taking the noise out.
- **Any voice can be replaced by a recording.** Drop an audio file into
  `Fiken/Resources/Audio/` and it is used instead of the synthesis for that voice. The bubble pop
  and the light switch are recordings today; everything else is still generated.
  Matching is on a **filename fragment**, declared per voice in `Voice.recordingKeywords`
  ("pop"/"bubble", "switch") — these files arrive named things like
  `dragon-studio-light-switch-382712.mp3`, and a hardcoded filename that no longer matches falls
  back to synthesis *silently*, which looks like nothing happened.
  Each recording is downmixed to mono, trimmed of silence at both ends, and resampled to several
  pitches so a repeated sample does not sound repeated — six for bubbles, which vary a lot, three
  barely-there ones for the switch, which is the same bit of plastic every time.
  The trim is not cosmetic: these files carry 45–105ms of silence before the transient, and left
  in, every sound would land that far behind its own haptic.
- **The light switch is fitted to a real recording**, not designed by ear. The
  reference clips live in `design/audio/`. Measuring onset spacing, decay and band energy turned
  up what guessing had missed: a wall switch is *three* transients 23–36ms apart, not one.
  Re-measure against that file before changing the voice — but tune tone by ear, not to the
  numbers. Matching the reference's brightness exactly read as harsh, and matching the old bubble
  reference's band energy exactly read as dull.
- Roll-off is **per voice**, not shared. The dial and the glass carry none at all, because those
  two were already right and filtering would only drift them. The voices that repeat fastest —
  tick at up to 45/s, zip at up to 40/s — are the quietest, because a sound you hear that often
  has to be one you stop noticing.
- The sound is fired from inside the haptic call rather than beside it, so the two cannot drift
  apart when a line gets reordered. The massage roll is the one exception to one-sound-per-event:
  it pulses 25 times a second, so it sounds only on the index finger, once per roll.

## Fitting the screen

The drawn fidgets are laid out in a fixed **393 x 852** design space, taken from the Figma frames,
and scaled to the device. Scale by `min(width/393, height/852)` — **not** by width alone. Width
alone overflows vertically on shorter phones: on an iPhone SE it pushed the title and caption
straight off the bottom edge. Fitting leaves a small margin at the sides on narrow devices, which
is the right trade.

Anything that converts a touch back into design coordinates has to subtract `originX` as well as
`originY`, or taps land offset on any device where the design does not fill the width.

## Accessibility

A haptics-first app is one of the few kinds a blind person can use exactly as a sighted person
does. That is only true if the gestures survive VoiceOver, which by default they would not.

- **Every fidget surface is a direct-touch area** (`accessibilityDirectTouch(.silentOnTouch)`).
  VoiceOver normally swallows custom gestures to drive its own cursor, which would make every
  screen here inert. Direct touch passes flick, rub, drag and press through untouched, and the
  silent option keeps VoiceOver quiet so the haptics are what you hear.
- Each fidget carries a label, a live value (RPM, bubbles left, cracks, amplitude) and a hint
  naming its gesture. The chrome — three bars, navigation tab — is labelled as buttons.
- **Reduce Motion switches the paper boil off on its own.** The manual toggle can only narrow
  that, never override it; when the system setting is on, the row says so and greys out. Screen
  transitions become fades.
- **Settings scales with Dynamic Type** all the way through the accessibility sizes: rows stack
  vertically instead of side by side, and the drawn controls grow with `@ScaledMetric`. The
  fidget screens stay at fixed sizes — they are laid out in a 393 x 852 design space against
  drawn artwork, and reflowing the type would tear the labels off the drawing.

## Localization

Eleven languages: English plus **es, fr, de, it, pt-BR, nl, nb, sv, da, fi**, in a String
Catalog at `Fiken/Resources/Localizable.xcstrings`. Counted strings (bubbles left, cracks) use
real plural variations, not a number glued to a noun.

**The language set is decided by the fonts, not by market size.** Fredericka the Great — the
title face — covers Latin-1 and no further. Special Elite reaches Latin Extended-A. Neither has
CJK or Cyrillic. So Japanese, Chinese, Korean, Russian, Polish, Czech and Turkish would fall
back to system fonts and lose the entire drawn look, which is the app. Adding them means finding
or drawing faces that cover those scripts first.

Right-to-left is also unshipped: the navigation tab is anchored to the left edge and the drawn
screens are not mirrored, so Arabic and Hebrew need layout work before they would be honest.

Note that `rawValue` on the settings enums is a **storage key** and must never be translated —
each has a separate `label` for display.

## How I'd like you to work

Propose a plan before writing code, and let me look at it. Build one screen at a time and stop
so I can feel it on a device before moving on — most of the parameters above are guesses that
need tuning by hand, and there's no point stacking six screens of untested haptics.

Don't refactor across screens without asking. If something in this brief doesn't survive contact
with the platform, tell me rather than working around it silently.

Start with the spinner. It exercises the drawing system, the boil, and speed-dependent haptics
all at once, so if it feels right the rest should follow.