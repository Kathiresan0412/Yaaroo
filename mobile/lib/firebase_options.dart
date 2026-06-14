// ============================================================
// IMPORTANT: This is a PLACEHOLDER file.
//
// Run the following command to generate the real configuration:
//   flutterfire configure
//
// This requires the FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//
// After running, this file will be auto-generated with your
// Firebase project credentials.
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not configured for Firebase.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for Firebase.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace with your actual Firebase config from `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyByl92rvbFYFcVCNWGIRhbKRJ3ZeWDGMnQ',
    appId: '1:859294608296:android:5a5158b54afad4aba38b9d',
    messagingSenderId: '859294608296',
    projectId: 'yaaro0',
    storageBucket: 'yaaro0.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase config from `flutterfire configure`
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: 'YOUR-IOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    iosBundleId: 'com.example.mobile',
  );
}
