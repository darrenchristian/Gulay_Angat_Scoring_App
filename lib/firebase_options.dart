import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated from google-services.json for project scoring-app-8bae2.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return android; // Fallback for testing environments
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqwsTPxPvDAiCiieHNBfFbRUoFbwKpGTY',
    appId: '1:1074945046255:android:fffc978563278cb1bd8d1a',
    messagingSenderId: '1074945046255',
    projectId: 'scoring-app-8bae2',
    storageBucket: 'scoring-app-8bae2.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDqwsTPxPvDAiCiieHNBfFbRUoFbwKpGTY',
    appId: '1:1074945046255:android:fffc978563278cb1bd8d1a',
    messagingSenderId: '1074945046255',
    projectId: 'scoring-app-8bae2',
    authDomain: 'scoring-app-8bae2.firebaseapp.com',
    storageBucket: 'scoring-app-8bae2.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqwsTPxPvDAiCiieHNBfFbRUoFbwKpGTY',
    appId: '1:1074945046255:android:fffc978563278cb1bd8d1a',
    messagingSenderId: '1074945046255',
    projectId: 'scoring-app-8bae2',
    authDomain: 'scoring-app-8bae2.firebaseapp.com',
    storageBucket: 'scoring-app-8bae2.firebasestorage.app',
  );
}
