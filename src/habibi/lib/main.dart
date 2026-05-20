import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/auth_repository.dart';
import 'data/social_repository.dart';
import 'models/challenge.dart';
import 'models/friend.dart';
import 'models/habit.dart';
import 'models/user_profile.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/habit_provider.dart';
import 'screens/root_screen.dart';

const String _habitsBoxName = 'habits';
const String _profileBoxName = 'profile';
const String _friendsBoxName = 'friends';
const String _challengesBoxName = 'challenges';

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

  runApp(HabibiApp(
    habitsBox: habitsBox,
    // To go from demo to real Firebase later, swap these two lines for the
    // Firebase implementations — nothing else in the app changes.
    authRepository: LocalAuthRepository(profileBox),
    socialRepository: LocalSocialRepository(friendsBox, challengesBox),
  ));
}

class HabibiApp extends StatelessWidget {
  const HabibiApp({
    super.key,
    required this.habitsBox,
    required this.authRepository,
    required this.socialRepository,
  });

  final Box<Habit> habitsBox;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider(habitsBox)),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(
            create: (_) => ChallengeProvider(socialRepository)),
      ],
      child: MaterialApp(
        title: 'habibi',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        home: const RootScreen(),
      ),
    );
  }
}

ThemeData _buildDarkTheme() {
  const bg = Color(0xFF0E0E0E);
  const surface = Color(0xFF1A1A1A);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
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
