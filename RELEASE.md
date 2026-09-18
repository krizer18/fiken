# Shipping Fiken

Ordered by dependency. Everything in step 1 is free and worth doing before you
spend anything.

---

## 1. Before you pay Apple

**The app has been held, and the massage screen passes.** The Release build is
installed on the phone and was launched from here; four fingers on the pads
reads correctly on a real hand, so the four-pad sequence stays and the
two-alternating-zones fallback in the brief is not needed. That was the last
open design question.

**Audio provenance is recorded.** Both clips came from Pixabay under the
Pixabay Content License — commercial use allowed, attribution not required.
Filenames, contributors and asset IDs are written down in
`THIRD-PARTY-NOTICES.md`, which is the trail back to the source if it is ever
questioned.

**The name is decided: `Fiken: Fidgeting App`.** 20 of the 30 characters
allowed. The suffix does two useful things — it separates the listing from
**Fiken, one of Norway's best-known accounting platforms** (fiken.no), which
matters more than usual because this app ships a Norwegian localization; and it
gives you a name that is still available even if plain "Fiken" is taken, since
App Store names have to be unique.

Availability is only confirmed when you type it into the New App form. If it
bounces, add to the suffix rather than touching `Fiken` itself — the bundle ID,
icon and wordmark all say Fiken, and the home screen name stays `Fiken`
regardless. The store name and the icon caption are separate fields, and
nothing in the app has to change for this.

**Both listing URLs are live.** Checked by fetching them, not assumed:

| Field | URL | State |
|---|---|---|
| Privacy Policy URL | `https://krizer18.github.io/fiken/` | 200, serving "Privacy Policy for Fiken" |
| Support URL | `https://github.com/krizer18/fiken` | 200, repo public |

Pages builds from `main` / `/docs`. If the policy ever changes, edit
`docs/index.md` and push — the site rebuilds itself within a minute. Keep both
URLs working for as long as the app is on sale: a privacy policy that goes 404
later is grounds for removal, not merely rejection.

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

Confirmed the only way it can really be confirmed: a store export succeeded,
which free provisioning cannot do. The build is signed `Apple Distribution:
Kabir Sharma (35L86WVALV)` and carries `iOS Team Store Provisioning Profile`,
good until 16 September 2027, with `get-task-allow` off and no provisioned
devices — a real App Store build rather than a development one.

You get two distribution certificates per account, so let Xcode manage them
rather than creating more by hand. The old 7-day development profile is still
cached for installs onto your own phone; it has nothing to do with submission.

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
- Name: `Fiken: Fidgeting App` — 20 of the 30 characters allowed
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
| Support URL | `https://github.com/krizer18/fiken` — public, returns 200 |
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
haptic,stress,focus,bubble,wrap,spinner,pop,calm,relax,sensory,stim,tactile,asmr,toy,restless
```

That's 92 characters. `fidget` came out because the name now carries
"Fidgeting" and Apple searches the name and the keywords together — repeating a
word buys nothing. `quiet` and `hands` came out as the weakest earners. The
freed characters went to `tactile`, `asmr` and `toy`, which people actually
search for and which nothing else in the listing covers.

`anxiety` and `adhd` are the obvious additions and both still fit, but keywords
naming a condition invite a closer read of whether the listing implies a
medical benefit (Guideline 1.4.1). The description above claims nothing
therapeutic; keep it that way if you add them.

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

**Already done for 1.0 (1).** The archive is built and sitting in Organizer as
`Fiken 2026-09-16 16.04`, and a distribution-signed `Fiken.ipa` is in the
project folder (gitignored) if you'd rather upload through Transporter. Open
Window → Organizer → Archives and skip to step 3.

Repeat from step 1 after any code change — a build that has been uploaded can
never be reused, and `CURRENT_PROJECT_VERSION` must go up each time.

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

**Expect Guideline 2.1, "Information Needed", on the first submission.** It is
what Apple sends accounts with no review history, and it is a questionnaire
rather than a fault: purpose, audience, how to reach the features, which
external services you use, regional differences, and a screen recording made on
a real device. Answers are written out in `APP-REVIEW-NOTES.md` — paste them
into Resolution Center, and into App Review Information → Notes so they carry
to later submissions. The recording is the only part that takes real effort.

---

## Still open

Both field questions are closed: the massage screen has been judged on a real
hand and passes, and audio provenance is recorded. What remains is optional or
cosmetic.
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
