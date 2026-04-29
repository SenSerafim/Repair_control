import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../domain/support_contacts.dart';

/// Контакты поддержки. Не кэшируется надолго: если админ обновил
/// контакты, при следующем входе на экран помощи / настроек поддержки
/// клиент увидит свежие значения.
final supportContactsProvider = FutureProvider<SupportContacts>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final settings = await repo.getAppSettings();
  return SupportContacts.fromAppSettings(settings);
});
