import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Реестр `GlobalKey`-ей подсвечиваемых элементов на экранах тура.
///
/// `TourAnchor`-обёртка вокруг кнопки регистрирует свой `GlobalKey` под
/// заданным `anchorId` при `initState`/при первом билде, и снимает с
/// регистрации при `dispose`. `TourOverlay` берёт `GlobalKey` по id из
/// текущего шага, считает `Rect` через `RenderBox`, рисует cutout.
///
/// Расширяет `ChangeNotifier`, чтобы `TourOverlay` мог подписаться и
/// перерисоваться, когда anchor смонтировался после навигации (а не
/// поллить таймером).
///
/// Реестр живёт в скоупе `/tour` `ProviderScope`. Когда пользователь
/// выходит из тура, ProviderScope убивается, регистрация — тоже.
class TourAnchorRegistry extends ChangeNotifier {
  TourAnchorRegistry();

  final Map<String, GlobalKey> _anchors = {};

  /// Зарегистрировать anchor. Возвращает уже существующий GlobalKey, если
  /// он есть (так wrapper может пере-render-нуться без потери ключа), либо
  /// создаёт новый.
  GlobalKey register(String id) {
    final existing = _anchors[id];
    if (existing != null) return existing;
    final key = GlobalKey(debugLabel: 'tour_anchor:$id');
    _anchors[id] = key;
    // Сообщаем подписчикам, что появился новый anchor — TourOverlay
    // перерисуется и пересчитает rect.
    notifyListeners();
    return key;
  }

  /// Снять регистрацию. Вызывается из `dispose` `TourAnchor`-а.
  void unregister(String id) {
    if (_anchors.remove(id) != null) notifyListeners();
  }

  /// Получить ключ по id (или `null`, если anchor не смонтирован).
  GlobalKey? keyOf(String id) => _anchors[id];

  /// Прочитать `Rect` подсвечиваемого виджета в глобальных координатах.
  /// Возвращает `null`, если виджет не смонтирован или ещё не отрисован.
  Rect? rectOf(String id, {RenderObject? ancestor}) {
    final key = _anchors[id];
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: ancestor);
    return topLeft & box.size;
  }
}

/// Провайдер реестра. Override-ится внутри `/tour` `ProviderScope`.
/// Дефолтный — пустой реестр (нужен только для тестов / no-op за пределами тура).
final tourAnchorRegistryProvider = Provider<TourAnchorRegistry>((ref) {
  return TourAnchorRegistry();
});
