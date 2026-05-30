import 'app_config.dart';
import 'bootstrap.dart';

/// Default entry point, used by a plain `flutter run` (no `-t`). It mirrors
/// `main_dev.dart` so the bare run command gives you the safe developer build.
///
/// The two real entry points are:
///   * lib/main_dev.dart  — developer build (mock auth + mock purchases)
///   * lib/main_prod.dart — real-users build (ships to the store)
void main() => bootstrap(const AppConfig(flavor: Flavor.dev));
