# Future Quest Types

Ideas for quest types beyond the current Journal/Gestral pair, captured for later planning. **Quiz** is the near-term focus and scoped in detail below; everything else is unvalidated brainstorm, not scoped.

## Quiz quests

A third quest type: instead of (or in addition to) scanning, the player answers a set of questions to collect it.

### Data model

Extend `events/{eventId}/journals/{journalId}`:

- Introduce a proper `type: 'journal' | 'gestral' | 'quiz'` enum field rather than bolting on another boolean flag (`has3D` was fine for two types; a third makes the enum the cleaner shape). This needs a small migration for existing seeded/created quests, but it's a one-time backfill (`has3D ? 'gestral' : 'journal'`).

New subcollection `events/{eventId}/journals/{journalId}/questions/{questionId}`:

- `prompt: string` — the question text.
- `imageUrl: string | null` — optional image shown above the prompt. **Reuse the existing `assetLibrary` picker** (same `AssetType.image` bucket already built for Journal/Gestral art) rather than a separate image system — the asset library is already general-purpose, so this is just wiring the existing `showAssetPickerDialog`/upload flow into the question editor. Worth deciding whether **answer options** can also carry an image each (changes the option shape below) — you raised this; no strong opinion yet, flagged as an open question.
- `answerType: 'single' | 'multiple'`
- `options: array<{ id: string, text: string, imageUrl: string | null, correct: bool }>`

New participant-side subcollection `events/{eventId}/participants/{uid}/quizAnswers/{journalId}` — same immutable, create-only shape as the existing `scans/{journalId}` (doc ID = journalId, so a duplicate submit is a no-op), storing the submitted answer(s) and pass/fail, gating "collected" the same way a scan does today.

### The one real open problem: correct-answer exposure

Firestore rules can't hide `correct: true/false` from a client that's allowed to *read* the question doc (needed to render the quiz at all) — a technically-inclined player could open devtools and read the answer directly off the network response. Cloud Functions could validate server-side and keep answers hidden, but that reopens the "no Cloud Functions" decision made earlier for this project.

**Recommendation**: accept this as a documented phase-1 limitation, same posture as the existing `qrToken`-exposure note already in `firestore.rules` — low stakes for a fun festival game, not a proctored exam. Revisit with a callable Cloud Function if it ever actually matters.

### Admin console additions

- Quest form's Journal/Gestral `SegmentedButton` becomes 3-way (add Quiz).
- A questions sub-editor: list of questions, "+ Add question," each expandable to edit prompt / image / single-vs-multiple / options, with a correct-answer toggle per option (radio for single, checkboxes for multiple).

### Player app additions

- A quiz-taking screen, reached the same way Reveal is reached today (scan or manual code), rendering question(s), image-above-prompt, single/multi-select inputs, and a submit action.
- Manual-code fallback works exactly as it already does for other quest types — no new deep-link work needed.

### Open questions to resolve before building this

1. Does scanning a Quiz quest collect it immediately, or only after passing? (Leaning: only after passing — otherwise "quiz" is cosmetic.)
2. Pass/fail threshold: all-correct, a minimum score, partial credit, retries allowed?
3. Do answer options get their own optional image, or just the question?
4. Accept the correct-answer-exposure limitation (recommended) or invest in a Cloud Function now?

## More quest type ideas (brainstorm — unvalidated, not scoped)

Beyond Quiz. The user's own idea is first; the rest are Claude's suggestions, offered for consideration, not decided on:

- **Memory / pairing-cards** (user's idea) — uncover cards, match symbol pairs for points. Simpler than a full game-engine build: could be done as plain Flutter widgets (a grid of flip animations) rather than needing Flame, if kept 2D and simple — worth scoping as its own thing rather than lumping with the heavier mini-games idea below.
- **Riddle / single-answer text quest** — Quiz's simpler sibling: one text prompt, one typed answer checked against a match (normalized like `manualCode` already is), no multi-choice UI needed. Much smaller scope than full Quiz, could ship first as a proof of concept for the "answer instead of scan" mechanic.
- **Photo / selfie proof-of-visit** — player takes a photo in-app at a location as the "collect" action, uploaded via the same Cloudinary pipe already built for the admin console. Fun/social for a festival, no new backend concept (just another upload).
- **GPS-proximity unlock** — collect by being physically near a coordinate, no QR sticker needed at all. Needs location permission handling (same shape of work as the camera permission flow already built) and a distance check.
- **Multi-player "N scans required" social unlock** — a quest only unlocks once N different participants have scanned it, encouraging attendees to find each other. No new engineering concept, just a threshold check on an existing counter.

## Mini-games (parking lot — not scoped, heavier lift)

Flagged by the user as "probably too complex/heavy," and agreed — a real game engine (Flame: physics/collision, sprite animation, a game loop) plus original character-art production, disconnected from the Cubit+Firestore architecture everywhere else in this app. If pursued, treat as an isolated prototype spike first — prove the game feel and art pipeline — before wiring anything into the treasure-hunt data model.

- A Flappy-Bird-style runner, Clair Obscur–themed: a sword obstacle instead of pipes, choice of 1 of 5 characters.
