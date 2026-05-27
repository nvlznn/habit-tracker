# Nokapp Habits - Build Habits with Friends

The app is **already deployed!**, try it 👉 **https://nvlznn.github.io/habit-tracker/**

(you should open the link with phone, if you are on computer, press F12 then adjust to the phone view)



A habit tracker you keep *with your friends*, built with Flutter. Track your
own habits, then start a shared challenge where the streak only moves forward
on the days everyone checks in.

> ⚠️ **This is a demo build.** It runs fully on-device with a **mock sign-in**
> and **mock purchases**, so anyone can try it instantly with no account and no
> payment. The plan is to publish Nokapp to the **App Store** as a paid product;
> the demo's mock layers are deliberately written so that **Google Login** and
> **App Store In-App Purchase** can be dropped into the pipeline without
> rewriting the app. See [Roadmap to production](#roadmap-to-production).

---

## Proposal Report

### Motivation & Goals

Habits are hard to keep alone. The thing that actually keeps me going isn't a
badge or a bigger number — it's knowing a friend is doing the same thing and
would notice if I quietly dropped off. Yet most habit apps are built for one
person staring at their own streak. I wanted one built around doing it
**together**: I add a friend, we share a habit, and we grow a *shared streak
that only advances on the days we both check in*. If either of us skips, the
shared streak stalls — so there's a real, mutual reason to show up.

The goals:

- A quiet personal tracker — add habits, tap to record today, see your history.
- **Friend challenges** — share a habit with one or more friends and build a
  shared streak between you.
- An *honest* shared streak — it counts only the days **every** participant did
  the habit, not just your own.

The DSAP angle: nearly every interaction boils down to the same read —
*"is habit H recorded on day D?"*. That single query backs every filled dot in
the home grid, every cell in the month calendar, and every streak calculation.
It's a perfect target for the rubric's **"compare different data structures /
algorithms on a real feature flow"** requirement, because the same
`contains(day)` operation can be implemented at least three different ways with
very different tradeoffs. The benchmark module (`src/habibi/bench/`) implements
all three behind a shared interface and measures them on identical workloads.
The friends feature then adds a *second*, naturally algorithmic operation: the
shared streak is a **set intersection** across each participant's set of
done-days — another place where the data-structure choice directly drives a
real feature.

### Competitive Analysis

The gap I kept hitting is that "social" in these apps means a public feed, a
global leaderboard, or a screenshot you can post. None of them let me say
*"you and me, this habit, together"* and reward us only when we both follow
through. Nokapp's defining feature is exactly that.

| App                | Platform        | Social model                       | Where Nokapp differs                                                     |
|--------------------|-----------------|------------------------------------|--------------------------------------------------------------------------|
| Habitica           | Web/iOS/Android | Public parties/guilds, gamified    | A *shared streak* with a chosen friend that only advances when both check in — not a public leaderboard |
| Streaks            | iOS             | Solo only                          | Built around doing a habit *with* someone; mutual accountability, not a private number |
| HabitKit           | iOS/Android     | Solo (shareable dot-grid images)   | Friends are first-class — real shared challenges, not just an exportable grid |
| Loop Habit Tracker | Android         | Solo, open source                  | Adds friend challenges and a shared-streak rule on top of solo tracking  |

Nokapp takes its minimal dark dot-grid look from HabitKit, but its reason to
exist is the social mechanic the others don't have: a **shared streak across a
small group (2–10 people) that advances only on the days every active
participant checked in**, with a 7-day rule that drops anyone who goes quiet
and ends the challenge when too few remain.

### Planned Features

- **Personal habits** — add / edit / delete (name, description, color, icon);
  tap the colored square on a card to check in for today; dot-grid history (one
  column = one week); a detail screen with a monthly calendar where past dates
  can be tapped to back-fill or remove a record, plus streak stats.
- **Friend challenges** — add friends by name, share a habit with one or more
  of them, and track a **shared streak** that counts only days everyone checked
  in.
- **Challenge lifecycle** — each participant must check in within 7 days;
  whoever lapses is dropped; the challenge ends when too few remain. Ended
  challenges (and ones you were dropped from) are kept in a *graveyard* so you
  can see how long you — and the challenge — lasted.
- **Local persistence with Hive** (no cloud, no account), behind swappable
  repositories so a real backend (e.g. Firebase) can be dropped in later.
- A standalone **benchmark** comparing three data-structure implementations of
  the date-key lookup operation.

### Technology Stack

- **Language:** Dart 3.11
- **Framework:** Flutter 3.41 (target platform: iOS; verified on Chrome /
  Windows and deployed as a Flutter web build because no Mac is currently on
  hand)
- **Local storage:** Hive 2.2 with hand-written `TypeAdapter`s (no code
  generation)
- **State management:** Provider (`ChangeNotifier`)
- **Architecture:** swappable repository interfaces (auth / social / billing)
  so the local mock can be replaced with a real backend without touching the UI
- **Deployment:** Flutter web → GitHub Pages, built and published automatically
  by GitHub Actions
- **Other:** `intl` for date formatting, `uuid` for ids
- **Version control:** Git / GitHub

### Prototype Verifiable Content

1. The app launches on Chrome / Windows and supports the core flow:
   - Add a habit (icon, name, description, color)
   - Tap the colored square on a card to check in for today
   - View the dot-grid history on the home screen
   - Tap a card to open the detail screen, then tap any past date in
     the monthly calendar to toggle that day's record
   - Edit or delete an existing habit
2. Data persists across restarts (Hive local storage in `box('habits')`).
3. Running `dart run bench/bench_main.dart` produces a comparison table
   for the three index implementations across N ∈ {100, 1K, 10K, 100K}
   with 10 000 reps per (impl, N) and a fixed seed (42). Initial run
   on this machine:

   | N      | Impl        | Build (μs) | contains (ns/op) | add (ns/op) | mem (B)  |
   |-------:|-------------|-----------:|-----------------:|------------:|---------:|
   | 1000   | HashSet     | 322        | 23.4             | 36.3        | 24,000   |
   | 1000   | SortedArray | 1,159      | 82.5             | 432.1       | 8 000    |
   | 1000   | Bitmap      | 66         | 44.0             | 35.4        | 375      |
   |        |             |            |                  |             |          |
   | 10000  | HashSet     | 624        | 15.5             | 1,007.5     | 240,000  |
   | 10000  | SortedArray | 67,182     | 78.3             | 14,620.5    | 80,000   |
   | 10000  | Bitmap      | 26         | 4.6              | 6.9         | 3,750    |
   |        |             |            |                  |             |          |
   | 100000 | HashSet     | 4,388      | 17.1             | 11.6        | 2,400,000|
   | 100000 | SortedArray | 8,240,113  | 528.2            | 150,255.1   | 800,000  |
   | 100000 | Bitmap      | 426        | 4.3              | 4.2         | 37,500   |

   Reading the table:
   - **HashSet**: contains stays roughly flat as N grows (O(1)), but
     memory grows linearly — 2.4 MB at N = 100K.
   - **SortedArray**: contains scales as O(log n), still cheap; but
     `add` does an O(n) shift, so build time at N = 100K balloons to
     **~8 seconds** and per-insert cost rises from ~100 ns at N = 100
     to ~150 μs at N = 100K — three orders of magnitude.
   - **Bitmap**: O(1) for everything, fixed memory of ⌈window / 8⌉
     bytes. At N = 100K it uses 37.5 KB — about 64× less than the
     HashSet — and is the fastest per op at every scale beyond JIT
     warmup.

   Conclusion for Nokapp's actual data scale (≤ a few hundred check-ins
   per habit): all three are fast enough, but the comparison shows
   *why* the choice would matter at scale, and the bitmap would be the
   right pick if a habit ever held tens of thousands of records.

5. All three implementations pass a shared correctness test
   (`test/algorithms_test.dart`) — given the same sequence of `add` /
   `remove` / `contains` operations against a seeded RNG, they return
   identical `contains` results at every step.

---

## Prototype Report

### Current Progress

- Project scaffolded under `src/habibi/` with Hive, Provider, intl, uuid.
- Data layer: `Habit` model with a hand-written `HabitAdapter`
  (typeId 0); `HabitProvider` exposes `create / update / delete /
  toggleDay` as the only mutation paths and emits `notifyListeners`
  after every `box.put`.
- UI: dark Material 3 theme, four screens (home, detail, edit,
  settings) and five reusable widgets (`HabitCard`, `DotGrid`,
  `MonthCalendar`, `IconPicker`, `ColorPicker`).
- DSAP module under `src/habibi/bench/`: three implementations of
  `CheckInIndex` (HashSet, SortedArray, Bitmap), a seeded synthetic
  workload generator, and a CLI runner that prints a Markdown table
  and writes `results.md` + `results.csv`.
- Tests: smoke test boots the app and renders the empty state;
  `algorithms_test.dart` asserts the three indexes agree on identical
  operation sequences.
- `flutter analyze` reports no issues. `flutter test` is green.

### Challenges Encountered

- **No Mac available.** The course's final demo is on iOS, but I only
  have a Windows machine on hand. Verified the prototype on Chrome and
  Windows; will need to arrange Mac access before the final to produce a real iOS build.
- **Hand-written Hive adapter.** I deliberately avoided code generation
  to keep the build pipeline simple, which means every change to the
  `Habit` schema has to update both `read()` and `write()` in lockstep.
  Manageable while the model is small, but worth flagging.
- **Designing the bench so SortedArray's cost is visible.** My first
  pass appended new days at the end of the array, which is O(1) for a
  sorted list and made the SortedArray look unfairly competitive on
  the `add` column. Reworked the synthetic workload to insert at random
  positions inside the existing window, after which the O(n) shift
  cost shows up cleanly (~100 ns at N = 100 → ~150 μs at N = 100K).
- **Scope discipline.** Dropped reminders, categories, and
  custom-value goals from the prototype to fit the timeline; they're
  noted as candidates for the final.

### Next Steps

- Borrow / arrange Mac access; build an iOS release; deploy to TestFlight
  for the final demo.
- Record a short demo video walking through the core flow.
- Write the Final Report sections (project description, usage
  instructions, architecture diagram).
- Optional polish: light theme toggle in settings, habit reordering,
  CSV export of check-in history.
- Re-run the benchmark on the actual demo device (iPhone) to see how
  the three implementations compare on ARM vs. Dart-on-VM.

---

## Final Report

### Project Description

Nokapp Habit Tracker is a Flutter habit tracker built around keeping habits
*with friends*. It opens into three tabs:

1. **Habits** — your personal habits. Add a habit (name, description, color,
   icon), tap the colored square to check in for today, and see a dot-grid of
   recent history. Each habit shows its current streak inline; tapping a habit
   opens a detail screen with a monthly calendar (tap any past day to back-fill
   or remove a record) and longer history.
2. **Challenges** — habits you share with friends. A challenge has 2–10
   participants (you + friends) and tracks a **shared streak**: a day only
   counts when *every active participant* checked in. That shared streak is
   computed as the **set intersection** of each participant's done-days. Each
   participant must check in within 7 days; whoever goes quiet is dropped, and
   when too few remain the challenge ends. Ended challenges — and ones you were
   dropped from — live in a **graveyard** that records how many days you
   persisted and how long the challenge lasted.
3. **Friends** — add friends by name so you can start challenges with them.

Under the hood:

- **Local-first storage** with Hive and hand-written `TypeAdapter`s (no code
  generation).
- **Swappable data layer** — auth, social, and billing each sit behind a
  repository interface, backed in this demo by on-device mocks
  (`LocalAuthRepository`, `LocalSocialRepository`, `LocalBillingRepository`).
  Going to production means swapping these few lines in `main.dart` —
  `AuthRepository` → **Google Login**, `BillingRepository` → **App Store
  In-App Purchase**, `SocialRepository` → a real backend (e.g. Firebase) —
  with nothing else in the app changing.
- **Sign-in (demo)** — the current build uses a mock local profile so it opens
  straight into the app; the real release will sign users in with **Google
  Login** behind the same `AuthRepository`.
- **State management** with Provider (`ChangeNotifier`), so toggling a check-in
  or the theme repaints exactly the screens that depend on it.
- **Pro tier (demo)** — a freemium gate (free users keep their 3 oldest habits
  active; extras are locked until they upgrade) with a paywall and **mock
  billing**. No real money changes hands in the demo; for the App Store release
  the same `BillingRepository` will be backed by **App Store In-App Purchase**.
- **DSAP benchmark** — the date-key lookup that backs every dot and streak is
  implemented three ways (HashSet, SortedArray, Bitmap) and benchmarked in
  `src/habibi/bench/`. The friends feature's shared streak adds a second
  algorithmic operation: a set intersection over participants' done-day sets.

### Roadmap to production

The current build is a demo. The intent is to ship Nokapp on the **App Store**
as a paid product, so the next steps add the real account and payment pieces to
the pipeline:

- **Google Login** — replace the mock `LocalAuthRepository` with real Google
  Sign-In (Firebase Auth / `google_sign_in`) so each user has a real identity.
- **App Store In-App Purchase** — replace the mock `LocalBillingRepository` with
  StoreKit purchases via `in_app_purchase`, so the Pro tier is a real, charged
  upgrade through Apple. (Google Play billing on Android can follow the same
  interface.)
- **Real backend** — move friends and challenges off-device (e.g. Firebase /
  Firestore) so a challenge actually syncs between two phones, behind the
  existing `SocialRepository`.
- **iOS release build** — produce a signed iOS build and ship to TestFlight,
  then the App Store. (Needs Mac access — see the Prototype Report.)

Because auth, billing, and social each sit behind a repository interface, these
are swaps at the edges of the app, not rewrites of it.

---

## How to run

The app is **already deployed** — you don't need to build anything to try it:

👉 **https://nvlznn.github.io/habit-tracker/**

Open that link in any modern browser. It works on a phone too — on iPhone, open
it in Safari, and (optionally) tap **Share → Add to Home Screen** to launch it
like a native app.

To run it locally instead, from `src/habibi/`:

```sh
flutter pub get
flutter run -d chrome           # run the app
flutter test                    # widget + algorithm tests
flutter analyze                 # static analysis
dart run bench/bench_main.dart  # DSAP benchmark
```

## Repository layout

```
habit-tracker/
├── README.md                              # this file
├── .github/workflows/deploy.yml           # builds web + publishes to GitHub Pages
└── src/habibi/
    ├── pubspec.yaml
    ├── web/                               # web shell, icons, manifest
    ├── lib/
    │   ├── main.dart                      # wires repositories + providers
    │   ├── models/
    │   │   ├── habit.dart                 # hand-written HabitAdapter (typeId 0)
    │   │   ├── friend.dart
    │   │   ├── challenge.dart             # ChallengeAdapter (typeId 3)
    │   │   └── user_profile.dart
    │   ├── data/                          # swappable repository interfaces
    │   │   ├── auth_repository.dart
    │   │   ├── social_repository.dart
    │   │   └── billing_repository.dart
    │   ├── providers/                     # ChangeNotifier state
    │   │   ├── habit_provider.dart
    │   │   ├── challenge_provider.dart
    │   │   ├── auth_provider.dart
    │   │   ├── entitlement_provider.dart
    │   │   └── theme_provider.dart
    │   ├── utils/
    │   │   ├── date_key.dart
    │   │   ├── streak.dart                # currentStreak + mutualStreak (set intersection)
    │   │   ├── challenge_lifecycle.dart   # 7-day drop / end rules
    │   │   └── palette.dart
    │   ├── widgets/
    │   │   ├── habit_card.dart
    │   │   ├── challenge_card.dart
    │   │   ├── dot_grid.dart
    │   │   ├── month_calendar.dart
    │   │   ├── icon_picker.dart
    │   │   └── color_picker.dart
    │   └── screens/
    │       ├── root_screen.dart           # 3-tab shell
    │       ├── home_screen.dart           # Habits tab
    │       ├── habit_detail_screen.dart
    │       ├── edit_habit_screen.dart
    │       ├── challenges_screen.dart     # Challenges tab
    │       ├── challenge_detail_screen.dart
    │       ├── edit_challenge_screen.dart
    │       ├── graveyard_screen.dart      # ended / dropped challenges
    │       ├── friends_screen.dart        # Friends tab
    │       ├── paywall_screen.dart
    │       └── settings_screen.dart
    ├── bench/                             # DSAP module — outside lib/
    │   ├── check_in_index.dart            # shared interface
    │   ├── hash_set_index.dart
    │   ├── sorted_array_index.dart
    │   ├── bitmap_index.dart
    │   ├── synthetic_data.dart            # seeded workload generator
    │   ├── bench_main.dart                # CLI runner
    │   ├── results.md                     # generated
    │   └── results.csv                    # generated
    └── test/
        ├── widget_test.dart
        └── algorithms_test.dart           # three indexes must agree
```
