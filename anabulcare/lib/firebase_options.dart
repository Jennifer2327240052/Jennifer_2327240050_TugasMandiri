import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhnY1HS5tu7Idq3uBxwvRumzbKexV5O3E',
    appId: '1:142662986467:web:5c43219f205d14cc1cb3d6',
    messagingSenderId: '142662986467',
    projectId: 'tugasmandiri-9f470',
    authDomain: 'tugasmandiri-9f470.firebaseapp.com',
    storageBucket: 'tugasmandiri-9f470.firebasestorage.app',
    measurementId: 'G-7P8742897B',
  );
  /// Returns true when the file has been populated with real Firebase
  /// configuration values instead of the placeholder constants created
  /// by `flutterfire configure` when not yet run.
  static bool get isConfigured {
    final opts = currentPlatform;
    if (opts.apiKey.contains('YOUR_API_KEY')) return false;
    if (opts.projectId.contains('YOUR_PROJECT_ID')) return false;
    if (opts.appId.contains('YOUR_ANDROID_APP_ID') ||
        opts.appId.contains('YOUR_WEB_APP_ID') ||
        opts.appId.contains('YOUR_IOS_APP_ID'))
      return false;
    return true;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1pbXwvF1KnpVtddZ33XeMQkTafGjDhps',
    appId: '1:142662986467:android:bf6551ff423ebd361cb3d6',
    messagingSenderId: '142662986467',
    projectId: 'tugasmandiri-9f470',
    storageBucket: 'tugasmandiri-9f470.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.anabulcare',
  );
}
