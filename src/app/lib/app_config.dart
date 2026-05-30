/// Which build of the app this is.
///
/// * [Flavor.dev]  — for the developer: mock sign-in and mock purchases, runs
///   fully on-device, and exposes demo-only tools (e.g. the simulated clock).
///   Safe to test anything; no real accounts or money.
/// * [Flavor.prod] — for real users: the build that ships to the store. Demo
///   tools are hidden, and this is where the real Google sign-in and App Store /
///   Google Play purchases get wired in.
enum Flavor { dev, prod }

/// Per-flavor settings shared with the UI (read it anywhere with
/// `context.watch<AppConfig>()`). Extend this as dev and prod need to differ
/// (e.g. a backend URL, analytics on/off).
class AppConfig {
  const AppConfig({required this.flavor});

  final Flavor flavor;

  bool get isDev => flavor == Flavor.dev;

  /// App/window title. Differs so two installed builds are easy to tell apart.
  String get appTitle => isDev ? 'Nokapp (DEV)' : 'Nokapp - Habit Tracker';
}
