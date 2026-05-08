import 'bootstrap.dart';
import 'core/config/app_env.dart';

/// Default-entrypoint. Flavor по умолчанию — dev (бьёт в staging-сервер
/// http://193.181.209.219). Для релизной сборки использовать
/// lib/main_staging.dart. Prod-таргет удалён до момента, когда домен
/// api.repair-control.app будет реально развёрнут.
Future<void> main() => bootstrap(AppFlavor.dev);
