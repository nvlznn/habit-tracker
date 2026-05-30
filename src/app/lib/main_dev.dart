import 'app_config.dart';
import 'bootstrap.dart';

/// Developer build: mock sign-in + mock purchases, all on-device.
///
/// Run with:  flutter run -t lib/main_dev.dart
void main() => bootstrap(const AppConfig(flavor: Flavor.dev));
