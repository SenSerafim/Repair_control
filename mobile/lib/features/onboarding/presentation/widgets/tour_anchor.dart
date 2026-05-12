import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tour_anchor_registry.dart';

/// Обёртка вокруг подсвечиваемых элементов экранов в демо-туре.
///
/// При маунте регистрирует свой `GlobalKey` в [TourAnchorRegistry] под
/// `id`, при unmount — снимает регистрацию. `TourOverlay` использует
/// этот ключ, чтобы посчитать `Rect` для cutout-эффекта.
///
/// За пределами `/tour` route — это no-op обёртка, child рендерится как
/// есть, регистрация уходит в default-реестр (никто не читает).
class TourAnchor extends ConsumerStatefulWidget {
  const TourAnchor({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  ConsumerState<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends ConsumerState<TourAnchor> {
  // Свой ключ на инстанс. Делим со списком/реестром только маппинг id→key,
  // но НЕ сам GlobalKey — иначе два транзитно сосуществующих TourAnchor
  // (route transition, hot reload) кладут один и тот же ключ в дерево и
  // ловят duplicate-GlobalKey assertion.
  late final GlobalKey _key = GlobalKey(debugLabel: 'tour_anchor:${widget.id}');
  // Кэшируем registry, чтобы вызывать unregister в dispose без `ref.read`
  // (на disposed-элементе ref недоступен — будет StateError).
  TourAnchorRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = ref.read(tourAnchorRegistryProvider);
    if (!identical(registry, _registry)) {
      _registry?.unregister(widget.id, _key);
      _registry = registry;
      _registry!.registerKey(widget.id, _key);
    }
  }

  @override
  void dispose() {
    _registry?.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
