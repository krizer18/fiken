# Third-party notices

Everything Fiken ships that someone else made, and the terms it comes under.
Details below are taken from the files themselves (the fonts' embedded `name`
table), not from memory.

---

## Fonts

Both are bundled in `Fiken/Resources/Fonts/` and registered at launch.

### Fredericka the Great
- Copyright (c) 2011 Font Diner, Inc. DBA Tart Workshop — Reserved Font Name
  "Fredericka the Great"
- Designer: Crystal Kluge
- **Licence: SIL Open Font License, Version 1.1** — https://scripts.sil.org/OFL

Licence text: `Fiken/Resources/Fonts/OFL.txt`, shipped inside the app bundle.
This is the copy distributed with the font itself, so it carries the correct
Reserved Font Name notice.

### Special Elite
- Copyright (c) 2010 Brian J. Bonislawsky DBA Astigmatic (AOETI)
- Designer: Astigmatic (AOETI)
- **Licence: Apache License, Version 2.0** — https://www.apache.org/licenses/LICENSE-2.0

Licence text: `Fiken/Resources/Fonts/LICENSE-Apache-2.0.txt`, shipped inside the
app bundle. The font ships no `NOTICE` file, so the copyright line above plus the
licence satisfies section 4.

---

## Audio

In `Fiken/Resources/Audio/`. Two voices are recordings; the other six are
synthesised in `SoundEngine.swift` and are original to this project.

| File | Used for |
|---|---|
| `bubble_pop.mp3` | bubble wrap pop |
| `light_switch.mp3` | light switch |

Both were confirmed by the project owner as free for commercial use.

> Worth recording the source site and licence name here, for your own records.
> These arrived named `universfield-bubble-pop-06-351337.mp3` and
> `dragon-studio-light-switch-382712.mp3` — contributor plus asset ID, the
> naming pattern of a stock audio library. The rename erased that trail, so a
> link is the only durable evidence if the licence is ever questioned; "I
> checked at the time" is not something you can produce later.

If the two files are ever removed, the synthesised voices take over
automatically and nothing breaks.

---

## Everything else

All drawing, haptic patterns, and the six synthesised sound voices are original
to this project. No third-party code or packages are linked — Fiken has no
dependencies beyond Apple's own frameworks.
