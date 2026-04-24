import 'bootstrap.dart';
import 'core/config/app_env.dart';

/// Default-entrypoint. Flavor по умолчанию — dev.
/// Для релиза использовать lib/main_staging.dart или lib/main_prod.dart.
Future<void> main() => bootstrap(AppFlavor.dev);
