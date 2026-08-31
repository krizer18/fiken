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

**Record where the audio came from.** `THIRD-PARTY-NOTICES.md` has a placeholder
for it. You've confirmed the two clips are free for commercial use, but the
rename erased the original filenames, which were the only trace of the source.
A link is the only thing you can produce later if it is ever questioned.

**Check the name is free.** Search the App Store for "Fiken". App names are
unique — if it's taken you'll find out at the worst possible moment, when you
create the app record. There is no reserving it in advance without an account.

**Publish the privacy policy.** `PRIVACY.md` is written and accurate. The
listing needs it at a public URL:

- GitHub → `krizer18/fiken` → Settings → Pages → Source: `main`, folder `/ (root)`
- For a clean URL, move it to `docs/index.md` first so it lands at
  `https://krizer18.github.io/fiken/` rather than a `/PRIVACY` path

---

## 2. Apple Developer Program — $99/year

developer.apple.com/programs — enrol as an individual. Approval is usually
quick but can take a day or two, and occasionally asks for ID.

Nothing past this point is possible without it. Your free Apple ID can sideload
to your own phone and nothing else.

Once it's active, two things improve immediately: builds stop expiring after
seven days, and TestFlight becomes available if you want people testing it
before it's public.

---

## 3. Create the app record

appstoreconnect.apple.com → **My Apps → + → New App**

- Platform: iOS
- Name: Fiken
- Primary language: English
- Bundle ID: `com.krizer18.Fiken` — Xcode registers this for you once the paid
  account is attached
- SKU: anything unique and private, e.g. `fiken-001`

---

## 4. Fill in the listing

**App Information** (applies to every version)

| Field | Value |
|---|---|
| Subtitle | 30 characters, e.g. "Seven fidgets for restless hands" (trim to fit) |
| Category | Entertainment, or Health & Fitness if you lean on the de-stress angle |
| Privacy Policy URL | from step 1 |
| Age rating | answer the questionnaire — Fiken should come out 4+ |

**The version page**

| Field | Notes |
|---|---|
| Screenshots | `design/appstore/` — drag all six in, in order |
| Description | see below |
| Keywords | 100 characters, comma-separated, no spaces after commas |
| Support URL | the GitHub repo is fine |
| Copyright | `2026 Kabir Sharma` |

The six screenshots are 1320×2868, the 6.9" iPhone size. One set covers every
iPhone size — App Store Connect will say so if it ever wants another.

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

The build takes a few minutes to finish processing before it can be selected on
the version page.

Release configuration has been built and verified — 2.6 MB, with all eleven
localizations, both fonts, both licence texts and both audio files confirmed
present in the bundle.

---

## 6. Submit

Attach the processed build to the version, then **Add for Review → Submit**.

Review is typically a day or two. Rejections are normal and usually specific —
they tell you the guideline number and what to fix. The most likely one for an
app like this is metadata rather than code.

---

## Still open

- **The massage screen** has never been judged on a real hand (step 1)
- **Audio provenance** is unrecorded (step 1)
- **App name availability** is unchecked (step 1)

## Not needed

- No account system, no server, no backend — Fiken has no network code at all
- No third-party SDKs or packages; Apple frameworks only
- No App Store Connect API keys, no CI, no fastlane. Archive and upload by hand
  is the right amount of process for a one-person app
