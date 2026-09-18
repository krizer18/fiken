# App Review notes

Answers to the Guideline 2.1 "Information Needed" request that new developer
accounts get on a first submission. Paste the numbered sections into Resolution
Center, and paste sections 2–6 into **App Review Information → Notes** as well,
where they stay for future submissions.

Nothing here is a code change. Fiken has no accounts, no purchases, no
user-generated content and no network access, so most of what Apple asks about
does not exist in this app — say so plainly rather than leaving it blank.

---

## 1. Screen recording

Record on the iPhone, starting from launch. Easiest route: connect it by USB,
open QuickTime Player → File → New Movie Recording → click the arrow beside the
record button → choose the iPhone as camera and microphone. Export, then share
it as an unlisted YouTube or Vimeo link in your reply.

About ninety seconds is plenty. Shot list:

1. Launch from the Home screen. On a first launch the title card appears —
   swipe up. (Delete and reinstall first if you want that on camera.)
2. **Bubble wrap** — press bubbles, they pop and the counter drops. Shake to
   refill.
3. **Two-finger horizontal swipe** to the next fidget. Do it two or three times
   so it is unmistakably the navigation.
4. **Spinner** — flick it, let it wind down.
5. **Zipper** — drag up, then down.
6. **Detent dial** — rub in a circle.
7. **Light switch** — click, and the page inverts.
8. **Glass** — tap a few times, then shake to reset.
9. **Finger massage** — four fingers on the pads, drag to raise the wave.
10. Menu button, top right → the fidget list → choose one.
11. Settings → paper to dark → press **Feel it**.

Say one thing out loud that video cannot carry: every screen's real output is
haptic. What the camera sees is only the drawing reacting.

---

## 2. Purpose and target audience

> Fiken is a fidget toy for iPhone. It has seven things to touch — bubble wrap,
> a spinner, a zipper, a detent dial, a light switch, a pane of glass, and a
> finger massage — and each one answers your touch with its own haptic pattern
> through the Taptic Engine.
>
> It is for people who think better with their hands busy: during a long video,
> a lecture, a phone queue, a waiting room. The problem it solves is that a
> physical fidget toy is one more object to carry and is often noisy, while the
> phone is already in your hand and can be silent. Sound is off by default.
>
> The app is designed to be used without looking at the screen. Each fidget
> announces itself on arrival with a distinct haptic signature, so you can tell
> which one you have landed on by feel alone. There is no scoring, no progress,
> no content feed and nothing to complete. Audience is general, rated 4+.

---

## 3. Setting up and accessing the main features

> No account, login, or sample data is needed. Nothing is gated. Everything in
> the app is reachable from launch.
>
> On a first launch the app shows a title card with the word Fiken — swipe up to
> begin. After that it opens straight into the last fidget used.
>
> Move between fidgets with a **two-finger horizontal swipe anywhere on the
> screen**, in either direction, or tap the **menu button at the top right** to
> pick from a list. The gesture takes two fingers on purpose, because every
> fidget uses one-finger gestures of its own.
>
> The seven fidgets and how each is used:
>
> - Bubble wrap — press anywhere; bubbles pop and regrow. Shake to refill.
> - Fidget spinner — flick to spin; it slows under friction.
> - Zipper — drag up or down along the teeth.
> - Detent dial — rub in a circle, either direction, endlessly.
> - Light switch — click to flip; the page inverts.
> - Glass — tap anywhere to crack it. Shake to reset.
> - Finger massage — rest four fingers on the pads, drag to raise the wave.
>
> Settings is in the same menu: paper (light/dark), sound (off by default),
> haptic strength, go dark, handedness, and the paper boil animation.
>
> Haptics need a physical device. In the Simulator the app runs and draws
> correctly but produces no vibration, which is most of what the app is.

---

## 4. External services, tools, or platforms

> None. Fiken makes no network requests of any kind and has no backend, no
> accounts, no analytics, no advertising, and no third-party SDKs or packages.
> It links only Apple's own frameworks (SwiftUI, Core Haptics, AVFoundation,
> UIKit, QuartzCore).
>
> No data providers, authentication services, payment processors or AI services
> are used. Settings are stored on the device in UserDefaults and never leave
> it, which is why the App Privacy section is "Data Not Collected".

---

## 5. Regional differences

> None. The app behaves identically in every region. There is no geo-gating, no
> region-specific content, and no server to vary behaviour.
>
> The interface is localized into eleven languages — English, Danish, Dutch,
> Finnish, French, German, Italian, Norwegian Bokmål, Portuguese (Brazil),
> Spanish and Swedish — which changes the wording only. Every feature is present
> in every language and region.

---

## 6. Regulated industry or protected third-party material

> Fiken is not in a regulated industry. It makes no medical, health, financial
> or therapeutic claims, and provides no regulated service. It is a toy.
>
> It contains third-party material, all of it licensed for commercial use, and
> all of it recorded in THIRD-PARTY-NOTICES.md in the project:
>
> - Two sound effects from Pixabay, under the Pixabay Content License, which
>   permits commercial use and requires no attribution.
> - Two typefaces: Fredericka the Great, under the SIL Open Font License 1.1,
>   and Special Elite, under the Apache License 2.0. Both licence texts ship
>   inside the app bundle.
>
> Everything else — all drawing, every haptic pattern, and six synthesised
> sound voices — is original to this project.
