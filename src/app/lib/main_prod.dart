import 'app_config.dart';
import 'bootstrap.dart';

/// Real-users build: the one that ships to the store.
///
/// Run with:  flutter run -t lib/main_prod.dart
void main() => bootstrap(const AppConfig(flavor: Flavor.prod));
