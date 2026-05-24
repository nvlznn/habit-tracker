import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/auth_repository.dart';
import 'data/billing_repository.dart';
import 'data/social_repository.dart';
import 'models/challenge.dart';
import 'models/friend.dart';
import 'models/habit.dart';
import 'models/user_profile.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/entitlement_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/root_screen.dart';

const String _habitsBoxName = 'habits';
const String _profileBoxName = 'profile';
const String _friendsBoxName = 'friends';
const String _challengesBoxName = 'challenges';
const String _settingsBoxName = 'settings';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(FriendAdapter());
  Hive.registerAdapter(ChallengeAdapter());

  final habitsBox = await Hive.openBox<Habit>(_habitsBoxName);
  final profileBox = await Hive.openBox<UserProfile>(_profileBoxName);
  final friendsBox = await Hive.openBox<Friend>(_friendsBoxName);
  final challengesBox = await Hive.openBox<Challenge>(_challengesBoxName);
  final settingsBox = await Hive.openBox(_settingsBoxName);

  // To go from demo to real Firebase later, swap these lines for the
  // Firebase implementations — nothing else in the app changes.
  final authRepository = LocalAuthRepository(profileBox);
  final socialRepository = LocalSocialRepository(friendsBox, challengesBox);
  // Demo billing (mock purchases). Swap for a StoreBillingRepository to charge
  // through the App Store / Google Play.
  final billingRepository = LocalBillingRepository(settingsBox);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(settingsBox)),
      ChangeNotifierProvider(create: (_) => HabitProvider(habitsBox)),
      ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
      ChangeNotifierProvider(create: (_) => ChallengeProvider(socialRepository)),
      ChangeNotifierProvider(
          create: (_) => EntitlementProvider(billingRepository)),
    ],
    child: const HabibiApp(),
  ));
}

class HabibiApp extends StatelessWidget {
  const HabibiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watching the ThemeProvider rebuilds the whole app when the user toggles
    // light/dark, so every screen repaints with the new colors.
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: 'Nokapp - Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      home: const RootScreen(),
    );
  }
}

ThemeData _buildDarkTheme() {
  const bg = Color(0xFF0E0E0E);
  const surface = Color(0xFF1A1A1A);
  const surfaceHigh = Color(0xFF252525);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      primary: Color(0xFFB388FF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}

ThemeData _buildLightTheme() {
  const bg = Color(0xFFF4F4F6);
  const surface = Color(0xFFFFFFFF);
  const surfaceHigh = Color(0xFFE9E9EE);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      surface: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      primary: Color(0xFF6D28D9),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}
