# Shipping Fiken

Ordered by dependency. Everything in step 1 is free and worth doing before you
spend anything.

---

## 1. Before you pay Apple

**Feel the massage screen.** It is the one thing in the app nobody has judged.
The brief's own note says that if the four-pad illusion doesn't hold up, the
fallback is two alternating contact zones instead of four. Rest four fingers on
the pads and see whether you can tell *where* each pulse came from, or whether
it just reads as one buzz. This is the last open design question and it costs
ten seconds.

**Run the app at all.** The Release build has never been launched on hardware.
It installs, but the first launch was blocked by an untrusted profile, which is
normal for a free account: Settings → General → VPN & Device Management → your
Apple ID → Trust. Don't submit something nobody has held.

**Record where the audio came from.** `THIRD-PARTY-NOTICES.md` has a placeholder
for it. You've confirmed the two clips are free for commercial use, but the
rename erased the original filenames, which were the only trace of the source.
A link is the only thing you can produce later if it is ever questioned.

**Check the name — properly.** App names are unique on the App Store, so search
it there first. But also know that **Fiken is one of Norway's best-known
accounting platforms** (fiken.no), and this app ships a Norwegian localization,
which makes the overlap more visible than it would otherwise be. That is a
Guideline 5.2.1 risk as well as an availability one. Decide before you create
the app record, because the name is baked into the bundle ID, the icon and the
wordmark, and changing it after submission is far more annoying than changing it
now.

**Turn on GitHub Pages.** The policy now lives at `docs/index.md` with a
`docs/_config.yml` beside it, which is the layout Pages expects:

- GitHub → `krizer18/fiken` → Settings → Pages → Source: `main`, folder `/docs`
- It lands at `https://krizer18.github.io/fiken/` — open it and confirm before
  you paste it into App Store Connect

---

## 2. Apple Developer Program — $99/year

developer.apple.com/programs — enrol as an individual. Approval is usually
quick but can take a day or two, and occasionally asks for ID.

Nothing past this point is possible without it. Your free Apple ID can sideload
to your own phone and nothing else.

Once it's active, two things improve immediately: builds stop expiring after
seven days, and TestFlight becomes available if you want people testing it
before it's public.

### Which Apple ID this project uses

`KabirSharma2004@icloud.com`, team `Kabir Sharma` (`35L86WVALV`). Xcode records
that team as `isFreeProvisioningTeam: false`, `teamType: Individual` — a paid
individual membership rather than free provisioning. Enrolling an Apple ID that
already had a personal team keeps the same team ID, which is why nothing in the
project had to change.

Two leftovers from before enrolment are still on this machine. Both are
harmless and clear themselves:

- the cached provisioning profile is still a 7-day one, expiring 21 September.
  Xcode replaces it with a year-long profile next time it refreshes signing.
- there is no **Apple Distribution** certificate yet, only `Apple Development`.
  Xcode creates the distribution one the first time you run Distribute App (or
  `xcodebuild -exportArchive`). You get two distribution certificates per
  account, so let Xcode manage them rather than creating them by hand.

Where to confirm any of this yourself:

| Where | Shows |
|---|---|
| Xcode → Settings → Accounts (⌘,) | the Apple ID, with its teams listed beneath |
| developer.apple.com/account | membership status, Team ID, renewal date |
| appstoreconnect.apple.com → Users and Access | which Apple ID holds which role |

### If you ever sign in with a different Apple ID

Not the situation today, but the failure mode is confusing enough to write
down.

1. Xcode → Settings → Accounts → **+** → Apple ID → sign in with the paid one.
   Keep both signed in; they don't conflict.
2. Target → Signing & Capabilities → **Team** → pick the paid team.
   `DEVELOPMENT_TEAM` in the project will change away from `35L86WVALV`.
3. Expect one snag: `com.krizer18.Fiken` was auto-registered to the personal
   team, and a bundle ID can only belong to one team. If the paid account is a
   *different* Apple ID, Xcode may report the identifier unavailable — and free
   teams can't release identifiers through the developer portal. The cheap fix
   is to change the bundle ID (`com.krizer18.fiken.app`, or anything unused).
   Nothing is on the App Store yet, so it costs you nothing but reinstalling on
   your own phone.
4. Enrol with an Apple ID you intend to keep. It becomes your developer
   identity, it's what customers see as the seller, and memberships can't be
   merged afterwards.

---

## 3. Create the app record

appstoreconnect.apple.com → **My Apps → + → New App**

- Platform: iOS
- Name: Fiken (see the name check in step 1)
- Primary language: English
- Bundle ID: `com.krizer18.Fiken` — Xcode registers this for you once the paid
  account is attached
- SKU: anything unique and private, e.g. `fiken-001`

---

## 4. Fill in the listing

**App Information** (applies to every version)

| Field | Value |
|---|---|
| Subtitle | `Seven fidgets, drawn by hand` (28 of 30 characters) |
| Category | Entertainment |
| Privacy Policy URL | `https://krizer18.github.io/fiken/` |
| Age rating | answer the questionnaire — Fiken should come out 4+ |

**The version page**

| Field | Value |
|---|---|
| Screenshots | `design/appstore/` — drag all six in, in order |
| Description | below |
| Keywords | below |
| Support URL | `https://github.com/krizer18/fiken` |
| Copyright | `2026 Kabir Sharma` |

The six screenshots are 1320×2868, the 6.9" iPhone size. One set covers every
iPhone size — App Store Connect will say so if it ever wants another.

### Description

```
Fiken is a pocketful of things to fidget with, drawn by hand in ink on paper.

Seven of them. Pop a sheet of bubble wrap. Spin a spinner and feel it lose
speed. Rub a dial that clicks forever, in both directions. Throw a light
switch. Crack the glass. Work a zipper. Rest four fingers down for a massage.

Every one of them pushes back. Fiken is built around the Taptic Engine, so
what you feel is the point — the drawing is only there to tell your thumb
where to go. Each fidget announces itself with its own haptic signature, so
you can move between them and know where you landed without looking down.

Made for the times your hands want something to do and your eyes are
somewhere else: a long video, a longer lecture, a waiting room.

• Seven fidgets, each with its own feel
• Drawn by hand, and the ink keeps moving while you use it
• Works without looking
• Dark paper, adjustable haptic strength, optional sound
• No account, no network, nothing collected. Nothing leaves your phone.
```

### Keywords

100 characters, comma-separated, no spaces after the commas. Don't include
"Fiken" — the app name is already indexed.

```
fidget,haptic,stress,focus,bubble,wrap,spinner,pop,calm,relax,sensory,stim,restless,quiet,hands
```

That's 95 characters. `anxiety` and `adhd` are the obvious additions and both
fit, but keywords naming a condition invite a closer read of whether the
listing implies a medical benefit (Guideline 1.4.1). The description above
claims nothing therapeutic; keep it that way if you add them.

### Promotional text (optional, 170 characters, editable without review)

```
Seven hand-drawn fidgets that push back. Built around the Taptic Engine, so
you can use it without looking at the screen.
```

**App Privacy** — a separate section, and the easiest part of this whole list.
Fiken collects nothing, so answer **"Data Not Collected"** throughout. That
earns the cleanest possible privacy label on your listing.

---

## 5. Build and upload

In Xcode:

1. Select **Any iOS Device** as the destination (not a simulator, not your phone)
2. **Product → Archive**
3. When the Organizer opens: **Distribute App → App Store Connect → Upload**

Export compliance is already declared in the project
(`ITSAppUsesNonExemptEncryption = NO`), so it won't ask you on every upload.

`Fiken/PrivacyInfo.xcprivacy` declares the one required-reason API the app
touches — `UserDefaults`, category `NSPrivacyAccessedAPICategoryUserDefaults`,
reason `CA92.1`. Without it Apple emails an ITMS-91053 notice after every
upload. If you ever add file-timestamp, disk-space or boot-time calls, they go
in the same file.

The build takes a few minutes to finish processing before it can be selected on
the version page.

Release configuration has been built and verified — 2.7 MB, with all eleven
localizations, both fonts, both licence texts, both audio files and the privacy
manifest confirmed present in the bundle.

---

## 6. Submit

Attach the processed build to the version, then **Add for Review → Submit**.

Review is typically a day or two. Rejections are normal and usually specific —
they tell you the guideline number and what to fix. The most likely one for an
app like this is metadata rather than code.

---

## Still open

- **The massage screen** has never been judged on a real hand (step 1)
- **No build has ever been run** on a device (step 1)
- **Audio provenance** is unrecorded (step 1)
- **The name** is unchecked, and collides with a Norwegian accounting platform
  (step 1)
- **Two things in the brief were never built**: the About screen (no view, no
  `about.json`, no button in Settings) and the "open on" setting, along with the
  last-used-fidget restore it controls. Neither blocks submission. Decide
  whether 1.0 ships without them.
- **The launch screen is paper, not the wordmark.** `Config/Info.plist` sets the
  launch background to the `LaunchBackground` colour so the first frame isn't a
  white flash, but iOS launch screens can only show an asset-catalog image, not
  text in a bundled font. A drawn wordmark PNG would be needed for the real
  thing. Note also that the launch colour follows the *system* appearance while
  the app follows your Paper setting, so forcing dark paper on a light phone
  will flash cream for an instant.

## Not needed

- No account system, no server, no backend — Fiken has no network code at all
- No third-party SDKs or packages; Apple frameworks only
- No App Store Connect API keys, no CI, no fastlane. Archive and upload by hand
  is the right amount of process for a one-person app
