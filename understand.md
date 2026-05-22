# Understanding the Habibi codebase

A walkthrough of the project for someone reading this code for the first time. Built around the actual files, in the order it makes sense to read them.

---

## 1. The big picture

Habibi is a habit tracker. The whole app is one feature: *for each habit, did the user check in on day D?* Everything you see — the colored squares, the dot grids, the calendar, the streak counters — is a different visualization of that single yes/no per (habit, day).

The code is organized in **layers**, each one only talking to the layer directly below it:

```
UI (screens + widgets)            ← what you tap
   ↓ reads & calls
State (HabitProvider)             ← the only thing that mutates data
   ↓ reads & writes
Storage (Hive box of Habit)       ← saved to disk so it survives restarts
```

Plus a **DSAP benchmark** (`src/habibi/bench/`) that lives outside the app — three different data structures all answering the same "is day D recorded?" question, measured side by side. It's a separate program for the school project rubric.

File map:

```
src/habibi/
├── pubspec.yaml                       # what packages we depend on
├── lib/
│   ├── main.dart                      # app entry point
│   ├── models/habit.dart              # the Habit class + how it's saved
│   ├── providers/habit_provider.dart  # the state layer
│   ├── utils/                         # small pure helpers
│   ├── widgets/                       # reusable UI pieces
│   └── screens/                       # full pages
├── bench/                             # DSAP benchmark (standalone)
└── test/                              # automated tests
```

---

## 2. The data layer — `lib/models/habit.dart`

A `Habit` (lines 3–39) is just a bag of fields:

| Field           | Type           | What it is                                          |
|-----------------|----------------|-----------------------------------------------------|
| `id`            | `String`       | A unique ID (UUID) so we can find this habit later  |
| `name`          | `String`       | What the user typed, e.g. "read 30 minutes"         |
| `description`   | `String`       | Optional longer text                                |
| `colorValue`    | `int`          | The color, stored as a 32-bit ARGB integer          |
| `iconCodePoint` | `int`          | Which Material icon, by its Unicode code point      |
| `dateKeys`      | `Set<String>`  | The check-in history, e.g. `{"2026-05-04", ...}`    |
| `createdAt`     | `DateTime`     | When the habit was created (used for sort order)    |

> **Why `Set<String>` for the history?** A `Set` answers "is this day in the set?" in roughly constant time, and dropping a duplicate is automatic. The string format `"yyyy-MM-dd"` is human-readable and timezone-stable (we always represent days as local calendar dates, never as full timestamps).

`copyWith` (lines 22–38) returns a new `Habit` with some fields swapped. We use this when editing — instead of mutating the existing habit and risking missing a notification, we make a fresh copy with the new values and hand it to the provider.

### `HabitAdapter` (lines 41–81) — saving to disk

Hive (the local database we use) doesn't know what a `Habit` is. We have to teach it: *given a Habit, here are the bytes; given those bytes, here is a Habit*.

That's what a `TypeAdapter` does:
- `write` (lines 69–80) walks down each field and writes it as raw bytes — string, string, string, int, int, then the count of date keys followed by each key string, then the timestamp as milliseconds.
- `read` (lines 46–66) does the same in the same order to rebuild the object.

The order has to match. If you ever add a field to `Habit`, you must update both `read` and `write` together — otherwise data on disk and code expectations drift apart and the app crashes on the next launch.

`typeId = 0` (line 43) is just a number Hive uses internally to route bytes to the right adapter when there are multiple types in the same database.

---

## 3. The state layer — `lib/providers/habit_provider.dart`

This is the **only** place the app changes data. Every screen that wants to add a habit, toggle a check-in, or edit something goes through this class.

`HabitProvider` (line 7) extends `ChangeNotifier`. That base class does one job: it lets things "subscribe" to it, and when we call `notifyListeners()`, every subscriber rebuilds. The screens subscribe via `Consumer<HabitProvider>` or `context.watch<HabitProvider>()`.

The pattern in every mutating method is identical:

```dart
await _box.put(habit.id, habit);   // 1. write to disk
notifyListeners();                  // 2. tell the UI to rebuild
```

The methods:

| Method                                   | What it does                                     |
|------------------------------------------|--------------------------------------------------|
| `habits` (line 13)                       | Returns the list of habits, sorted by createdAt  |
| `byId(id)` (line 19)                     | Look up one habit                                |
| `create({name, ...})` (line 21)          | Make a new Habit with a fresh UUID, save it      |
| `update(habit)` (line 41)                | Save an edited habit                             |
| `delete(id)` (line 46)                   | Remove a habit                                   |
| `toggleDay(habitId, key)` (line 51)      | Add or remove a date key on that habit           |
| `isChecked(habitId, key)` (line 63)      | Read-only check                                  |

> **Why does `toggleDay` mutate `habit.dateKeys` directly instead of using `copyWith`?** Hive returns the *same Dart object* every time you `box.get` the same key. So mutating it in place is fine; the next `put` writes its current state. `copyWith` is for the editing flow where we want a clean before/after.

---

## 4. The utilities — small, pure helpers

### `lib/utils/date_key.dart`

The bridge between `DateTime` (Dart's date type) and our string format `"yyyy-MM-dd"`.
- `dateKey(DateTime)` → `"2026-05-04"`
- `todayKey()` → today as a key
- `epochDay(DateTime)` → the integer "days since 1970-01-01" (used by the bench)

Splitting `dateKey` and `epochDay` keeps the app's storage human-readable while letting the benchmark use compact integers.

### `lib/utils/streak.dart`

Pure functions. Given a `Set<String>` of date keys:
- `currentStreak` (line 3) walks backwards from today (or yesterday, if today isn't done yet) counting consecutive days until it hits a gap.
- `longestStreak` (line 18) sorts all the keys and scans for the longest run where each day is exactly one after the previous.

Both are used only in the detail screen for the streak chips.

### `lib/utils/palette.dart`

Two `const` lists: 14 colors and 30 icons. Both pickers source from these.

---

## 5. The UI layer

Flutter UI is built as a tree of **Widgets**. Two flavors:

- `StatelessWidget` — pure function from inputs to UI. Rebuilds when its inputs change.
- `StatefulWidget` — has internal mutable state (controllers, "which month am I viewing", etc.).

Every widget overrides `build(BuildContext)` which returns *more widgets*. That's how you get the deeply nested code.

### `lib/main.dart` — the entry point

`main()` (lines 11–17):
1. `WidgetsFlutterBinding.ensureInitialized()` — required boilerplate before any `await` in main.
2. `Hive.initFlutter()` — Hive sets up its local-file storage in the app's data dir.
3. `Hive.registerAdapter(HabitAdapter())` — teach Hive about our type.
4. `Hive.openBox<Habit>('habits')` — open (or create) the box named `habits`.
5. `runApp(HabibiApp(box: box))` — hand the box to the app.

`HabibiApp` (line 19):
- Wraps everything in `ChangeNotifierProvider` so `HomeScreen` and its children can reach the `HabitProvider`.
- Sets up a `MaterialApp` with the dark theme (`_buildDarkTheme` at line 38).
- `home: const HomeScreen()` — that's the first screen the user sees.

### `lib/screens/home_screen.dart` — the only top-level screen

`Scaffold` is Flutter's standard page layout (app bar at top, body below).
- App bar: settings icon (top-left) and `+` icon (top-right). Each pushes a new screen via `Navigator.of(context).push(MaterialPageRoute(builder: ...))`.
- Body wraps everything in `Consumer<HabitProvider>` (line 39). Whenever `HabitProvider` calls `notifyListeners()`, this `Consumer` rebuilds and shows the latest list.
- If `habits.isEmpty`, render `_EmptyState` (the "No habits yet" placeholder).
- Otherwise render a `ListView.separated` of `HabitCard`s.

### `lib/widgets/habit_card.dart` — the row in the home screen

A card has two tap regions:

- **The colored square in the top-right** (`_CheckSquare`, line 82) — calls `provider.toggleDay(habit.id, today)` directly. Today's check-in.
- **Everywhere else on the card** (the outer `GestureDetector` at line 21) — pushes the detail screen.

`behavior: HitTestBehavior.opaque` (lines 22 and 97) is what makes empty space inside the widget still register taps — without it, taps would fall through gaps.

The card body lays out an icon box, the habit name, the check-square, then a `DotGrid` underneath (line 74).

### `lib/widgets/dot_grid.dart` — the GitHub-style history grid

Default config (lines 11–13): 24 weeks × 7 days × small dots.

Logic:
1. Find this week's Monday (line 25).
2. Walk back `(weeks - 1) * 7` days to find the leftmost day in the grid (line 27).
3. For each row (Mon–Sun) and column (week), compute the actual date and decide whether to fill the dot:
   - Future dates → transparent (skipped — line 49).
   - Date is in `dateKeys` → full color.
   - Otherwise → dim version of the color.

Same widget is reused on the detail screen with bigger dots and more weeks (`HabitDetailScreen` line 102).

### `lib/screens/habit_detail_screen.dart` — when you tap a card body

Wraps everything in `Consumer<HabitProvider>` (line 18) so streak numbers and the dot grid update live when you toggle dates from the calendar below.

Composed of:
- Header with icon, name, description.
- Big horizontal-scrollable `DotGrid`.
- Three `_StatChip`s: current streak, longest streak, total.
- A `MonthCalendar` whose `onToggleDate` calls `provider.toggleDay(...)`.

### `lib/widgets/month_calendar.dart` — the editable past

This one is `StatefulWidget` because it needs to remember which month the user is currently viewing (`_visibleMonth`, line 23). The prev/next arrows call `_shift(±1)` which calls `setState(...)` to trigger a rebuild.

Layout:
1. Compute how many leading blank cells to render before day 1 (line 46) — depends on which weekday the 1st falls on.
2. Generate a list of `DateTime?` cells: nulls for blanks, real dates for the rest.
3. Pad to a multiple of 7 so the grid is rectangular.
4. Render each cell as a `_DayCell` (line 137). Future dates get `onTap: null` so they're not tappable.

### `lib/screens/edit_habit_screen.dart` — create + edit + delete

This is `StatefulWidget` because of the `TextEditingController`s for the text fields.

`_isNew` (line 24) is the switch: if there's no `habitId`, we're creating; otherwise we're editing an existing one.

`initState` (line 27) seeds the form fields from either an empty default or the existing habit.

`_save` (line 47):
- Validates name not empty.
- Calls `provider.create(...)` or `provider.update(habit.copyWith(...))`.
- Pops back.

`_delete` (line 78) shows a confirm dialog, then calls `provider.delete(...)` and pops *twice* — once for the edit screen, once for the detail screen behind it.

### `lib/widgets/icon_picker.dart` and `color_picker.dart`

Both are very thin: a 7-column grid mapping over the `habitIcons` / `habitColors` lists from the palette. The selected one gets a white border. They report changes upward via `onSelect`.

### `lib/screens/settings_screen.dart`

Just two static `ListTile`s right now: "About" and "Version". Placeholder for future toggles (theme, etc.).

---

## 6. The DSAP benchmark — `src/habibi/bench/`

This is **not part of the app**. It's a separate Dart program (`dart run bench/bench_main.dart`) for the school project's data-structures requirement.

The question being benchmarked is: *given a habit's check-in history, how fast is `contains(day)` and `add(day)`?* The same operation is implemented three different ways behind one shared interface.

### The interface — `bench/check_in_index.dart`

```dart
abstract class CheckInIndex {
  bool contains(int epochDay);
  void add(int epochDay);
  void remove(int epochDay);
  int get size;
  int approxBytes();
  String get label;
}
```

Three implementations, all interchangeable.

### `bench/hash_set_index.dart` — the easy default

Wraps `Set<int>`. Everything is O(1) on average. About 24 bytes per entry due to bucket overhead.

### `bench/sorted_array_index.dart` — the textbook one

Keeps a `List<int>` in sorted order.
- `contains` uses `_lowerBound` (line 14) — classic binary search returning the first index ≥ target. O(log n).
- `add` (line 35) finds the insert point with the same binary search, then `_days.insert(i, ...)` shifts every element after `i` one slot to the right. **That shift is the O(n) cost** — and the reason this implementation looks bad on the `add` column at large N.

### `bench/bitmap_index.dart` — the clever one

Backs the set with a `Uint8List` (a packed array of bytes). Each bit represents one day in a fixed window starting at `origin`.

The bit-twiddling (lines 30–31, 38–39, 50–51):
- `i = epochDay - origin` — index of this day in the window.
- `i >> 3` — which byte (`i / 8`).
- `1 << (i & 7)` — which bit inside that byte (`i % 8`).
- `_bytes[byte] & bit` reads the bit; `|= bit` sets it; `&= ~bit` clears it.

Memory: 1 bit per representable day, fixed regardless of fill rate. 10 years ≈ 458 bytes total. Trade-off: days outside the window are silently dropped (line 36) — fine for habit tracking where the window is your install lifetime, but worth knowing.

### `bench/synthetic_data.dart` — the workload

`buildWorkload` generates a reproducible random scenario seeded by `seed` (default 42):
- `checkIns` — `n` unique random days from a window roughly 3× the size of `n`.
- `queries` — `reps` random query days, half guaranteed hits, half random.
- `addProbes` — `reps` distinct days from random positions inside the window that aren't already check-ins. The "random positions" detail matters: if you only appended at the end, the SortedArray's O(n) shift would never trigger and it'd look as fast as the others. This is what makes the comparison honest.

### `bench/bench_main.dart` — the runner

For each `N ∈ {100, 1K, 10K, 100K}`, for each implementation:
1. **Build** — insert all `n` check-ins from scratch. Time the loop.
2. **Contains** — run 10 000 lookups. Time the loop, count hits.
3. **Add** — rebuild a fresh index, then insert all `addProbes`. Time the loop.

Convert each to nanoseconds-per-op, write a Markdown table to stdout, save copies to `bench/results.md` and `bench/results.csv`.

### The equivalence test — `test/algorithms_test.dart`

Three small tests, but the important one is the first (line 11): drives 5 000 random ops (60% add, 30% contains, 10% remove) through all three implementations *with the same RNG seed* and asserts every `contains` answer agrees. If any implementation diverges from the others, the test fails — that's the safety net behind the "all three are interchangeable" claim.

---

## 7. A concrete trace — what happens when you tap "check in for today"

This is a good way to verify your mental model is right.

1. You tap the colored square on a habit card.
2. `_CheckSquare` (in `habit_card.dart` line 82) fires its `onTap`, which is `() => context.read<HabitProvider>().toggleDay(habit.id, today)`.
3. `HabitProvider.toggleDay` (`habit_provider.dart` line 51):
   - Looks up the habit by id.
   - Adds or removes today's date key from `habit.dateKeys`.
   - `await _box.put(habit.id, habit)` — Hive serializes via `HabitAdapter.write` and saves to disk.
   - `notifyListeners()` fires.
4. Every `Consumer<HabitProvider>` in the widget tree rebuilds:
   - `HomeScreen` — list still the same length, but `HabitCard` rebuilds.
   - Inside `HabitCard`, `isDoneToday` is now true → `_CheckSquare` renders filled with a checkmark.
   - The `DotGrid` rebuilds and today's dot is now full color.
5. If you close the app and reopen, `Hive.openBox(...)` reads the same bytes back via `HabitAdapter.read`, and the state is restored.

That's the whole loop.

---

## 8. Where to start when extending it

Some intentional starting points based on what's already in place:

- **Settings: light theme toggle.** `_buildDarkTheme` in `main.dart` line 38 shows the shape; you'd add a `_buildLightTheme`, store the user's preference (probably another small Hive box or `shared_preferences`), and switch on it.
- **Reordering habits.** `HabitProvider.habits` (line 13) currently sorts by `createdAt`. Add an `int sortOrder` field on `Habit` (remember to update `HabitAdapter.read` and `write`), expose `move(fromIndex, toIndex)` on the provider, and wrap the home `ListView` in a `ReorderableListView`.
- **Reminders.** Out of scope for the prototype; would need a notifications package and platform setup.
- **Different aggregation views.** The "is day D done?" question already has three index implementations in `bench/`. If you ever wanted in-app analytics over many habits, the bitmap is the cheapest to keep in memory.

---

## Cheat-sheet of unfamiliar Flutter/Dart things you'll see in this code

| You'll see                          | What it means                                                                 |
|-------------------------------------|-------------------------------------------------------------------------------|
| `const`                             | Compile-time constant — Flutter reuses these widgets without rebuilding       |
| `final`                             | Set once, never reassigned (like `let` in JS / `val` in Kotlin)               |
| `late`                              | I promise to assign this before reading it (used for state in `initState`)    |
| `async` / `await` / `Future<T>`     | Asynchronous — function returns "an answer eventually", `await` unwraps it    |
| `?` after a type (`Habit?`)         | Nullable — value can be `null`                                                |
| `??`                                | "Use the right side if the left is null"                                      |
| `..` cascade                        | "Do all these on the same object" — `list..add(1)..add(2)`                   |
| `setState(...)` (StatefulWidget)    | Tell Flutter "my state changed, rebuild me"                                   |
| `context.read<T>()` vs `.watch<T>()`| `read` = one-shot, doesn't rebuild on change. `watch` = subscribe.            |
| `Navigator.of(context).push(...)`   | Open a new screen (gets pushed onto the back-stack)                           |
| `Consumer<T>(builder: ...)`         | Rebuild this subtree whenever `T` calls `notifyListeners()`                   |
| `Stopwatch`                         | Used only in the bench — Dart core class for measuring elapsed time           |

---

That's the whole codebase. The app is small on purpose: ~700 lines of `lib/`, ~250 lines of `bench/`, plus tests. If anything in here is unclear, ask about that specific piece — every concept above maps to a few exact lines.
