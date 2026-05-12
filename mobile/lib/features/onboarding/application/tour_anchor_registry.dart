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

  /// Зарегистрировать anchor. Сохраняет (id → key)-маппинг, перезаписывая
  /// любой существующий — «победитель — последний». Каждый `TourAnchor`
  /// владеет собственным `GlobalKey`, поэтому когда два инстанса с одним id
  /// транзитно живут одновременно (route transition, hot reload, rebuild
  /// в одном кадре), Flutter не получает duplicate GlobalKey assertion.
  void registerKey(String id, GlobalKey key) {
    _anchors[id] = key;
    // Сообщаем подписчикам, что появился новый anchor — TourOverlay
    // перерисуется и пересчитает rect.
    notifyListeners();
  }

  /// Снять регистрацию. Удаляет запись только если в реестре всё ещё
  /// записан именно наш ключ — иначе игнор (более новый `TourAnchor`
  /// уже перерегистрировал id).
  void unregister(String id, GlobalKey ownKey) {
    if (identical(_anchors[id], ownKey)) {
      _anchors.remove(id);
      notifyListeners();
    }
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
