# Nokapp Habits

A habit tracker that can build habits with friends.

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
    └── test/
        └── widget_test.dart              # boots the app, renders empty state
```
