# Nokapp Habits

A habit tracker that can build habits with friends.

## Running the app

```bash
cd src/app
flutter pub get
flutter run -t lib/main_dev.dart    # developer build — mock auth + purchases, "DEV" ribbon
flutter run -t lib/main_prod.dart   # real-users build — what ships to the store
```

Add `-d chrome` (or any device id) to pick a target. A plain `flutter run` uses
`lib/main.dart`, which mirrors the developer build.

## Repository layout

```
habit-tracker/
├── README.md                              # this file
└── src/app/
    ├── pubspec.yaml
    ├── firebase.json                      # FlutterFire project link (generated)
    ├── firestore.rules                    # Firestore security rules (source of truth; deploy: firebase deploy --only firestore:rules)
    ├── lib/
    │   ├── main.dart                      # default entry → developer build
    │   ├── main_dev.dart                  # developer build (mock auth + purchases)
    │   ├── main_prod.dart                 # real-users build (ships to the store)
    │   ├── bootstrap.dart                 # shared startup: Firebase, Hive, providers, themes, dev/prod seam
    │   ├── app_config.dart                # Flavor enum + AppConfig
    │   ├── firebase_options.dart          # generated Firebase config (flutterfire configure)
    │   ├── models/
    │   │   ├── habit.dart                 # hand-written HabitAdapter (typeId 0)
    │   │   ├── friend.dart
    │   │   ├── challenge.dart             # ChallengeAdapter (typeId 3)
    │   │   └── user_profile.dart
    │   ├── data/                          # swappable repository interfaces + impls
    │   │   ├── auth_repository.dart       # interface + LocalAuthRepository (Hive demo)
    │   │   ├── firebase_auth_repository.dart   # Google sign-in (prod)
    │   │   ├── social_repository.dart     # interface + LocalSocialRepository (Hive demo)
    │   │   ├── firebase_social_repository.dart # Firestore friends/challenges (prod)
    │   │   ├── habit_repository.dart       # interface + LocalHabitRepository (Hive demo)
    │   │   ├── firebase_habit_repository.dart  # Firestore per-user habits + first-sign-in migration (prod)
    │   │   └── billing_repository.dart
    │   ├── providers/                     # ChangeNotifier state
    │   │   ├── habit_provider.dart
    │   │   ├── challenge_provider.dart
    │   │   ├── auth_provider.dart
    │   │   └── entitlement_provider.dart
    │   ├── utils/
    │   │   ├── date_key.dart
    │   │   ├── streak.dart                # currentStreak + mutualStreak (set intersection)
    │   │   ├── challenge_lifecycle.dart   # 7-day drop / end rules
    │   │   ├── palette.dart
    │   │   ├── icon_catalog.dart
    │   │   └── emoji_catalog.dart
    │   ├── widgets/
    │   │   ├── habit_card.dart
    │   │   ├── challenge_card.dart
    │   │   ├── dot_grid.dart
    │   │   ├── month_calendar.dart
    │   │   ├── icon_picker.dart
    │   │   ├── color_picker.dart
    │   │   └── glyph.dart
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
    │       ├── icon_emoji_picker_screen.dart
    │       ├── paywall_screen.dart
    │       └── settings_screen.dart
    └── test/
        ├── widget_test.dart               # boots the app, renders empty state
        ├── challenge_lifecycle_test.dart
        └── mutual_grid_repro_test.dart
```
