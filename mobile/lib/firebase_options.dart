// File generated manually (не через flutterfire_cli) — при добавлении
// платформ или смене Firebase-проекта обновляйте здесь вручную или перезапускайте
// `flutterfire configure --out=lib/firebase_options.dart`.
//
// Источники:
// - Android: mobile/android/app/google-services.json
// - Web: скопировано из Firebase Console → Project Settings → Web app config
// - iOS: будет добавлено позже (GoogleService-Info.plist)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase-конфиги приложения. Используется в `Firebase.initializeApp(options: ...)`.
///
/// Один Firebase-проект `repaircontrol-22bd3` обслуживает все платформы.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase options не настроены. Добавьте GoogleService-Info.plist '
          'и обновите DefaultFirebaseOptions.ios.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase для ${defaultTargetPlatform.name} не настроен.',
        );
    }
  }

  /// Android — из google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBILtlZxscKsxLKGcRSCoUGzVc40-qeWS4',
    appId: '1:912221133495:android:7f2dbfef22d1e6b03acb32',
    messagingSenderId: '912221133495',
    projectId: 'repaircontrol-22bd3',
    storageBucket: 'repaircontrol-22bd3.firebasestorage.app',
  );

  /// Web — из Firebase Console.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkAJgTu5jFG5LZPySBPpx-Z731r1dXUKY',
    appId: '1:912221133495:web:6cae452e2aed689c3acb32',
    messagingSenderId: '912221133495',
    projectId: 'repaircontrol-22bd3',
    authDomain: 'repaircontrol-22bd3.firebaseapp.com',
    storageBucket: 'repaircontrol-22bd3.firebasestorage.app',
    measurementId: 'G-CCMJGS94NM',
  );

  /// iOS — TODO: добавить после регистрации iOS app в Firebase.
  /// См. `GoogleService-Info.plist`:
  ///   GOOGLE_APP_ID → appId
  ///   API_KEY → apiKey
  ///   GCM_SENDER_ID → messagingSenderId
  ///   BUNDLE_ID → iosBundleId
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '912221133495',
    projectId: 'repaircontrol-22bd3',
    storageBucket: 'repaircontrol-22bd3.firebasestorage.app',
    iosBundleId: 'com.repaircontrol.app',
  );
}
