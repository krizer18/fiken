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

The OFL requires that the licence text accompany the font. Place a verbatim copy
of `OFL.txt` beside the `.ttf` before shipping; it is distributed with the font
on Google Fonts.

### Special Elite
- Copyright (c) 2010 Brian J. Bonislawsky DBA Astigmatic (AOETI)
- Designer: Astigmatic (AOETI)
- **Licence: Apache License, Version 2.0** — https://www.apache.org/licenses/LICENSE-2.0

Apache 2.0 requires a copy of the licence and any `NOTICE` file to be
distributed with the work. Place `LICENSE-2.0.txt` beside the `.ttf`.

---

## Audio

In `Fiken/Resources/Audio/`. Two voices are recordings; the other six are
synthesised in `SoundEngine.swift` and are original to this project.

| File | Used for |
|---|---|
| `bubble_pop.mp3` | bubble wrap pop |
| `light_switch.mp3` | light switch |

> **UNRESOLVED — must be settled before submitting.**
> These arrived named `universfield-bubble-pop-06-351337.mp3` and
> `dragon-studio-light-switch-382712.mp3`, which is the naming pattern of a
> stock audio library — contributor name plus asset ID. They have since been
> renamed, so the provenance now lives only here. Record the source site, the
> licence, and whether attribution is required. "Free to download" is
> not the same as "free to ship in a paid or commercial app", and App Review
> will not check this — but the rights holder can, afterwards.
>
> If the licence cannot be established, the fallback is cheap: delete the two
> files and the synthesised voices take over automatically.

---

## Everything else

All drawing, haptic patterns, and the six synthesised sound voices are original
to this project. No third-party code or packages are linked — Fiken has no
dependencies beyond Apple's own frameworks.
