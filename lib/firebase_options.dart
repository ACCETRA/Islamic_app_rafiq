import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApI8EPT1RKHtiNBI2KIToBZ3puhC0ISZ4',
    appId: '1:978444733436:web:0a53a5806fda6ad0bd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    authDomain: 'alrafq-2025.firebaseapp.com',
    storageBucket: 'alrafq-2025.firebasestorage.app',
    measurementId: null, // Add if you have Google Analytics
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAR5rn70vX5VzPTtjhnQsvl1h03KKpQ4sk',
    appId: '1:978444733436:android:fa174d845a285d6fbd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    storageBucket: 'alrafq-2025.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXh5lPXKYgPlD674EAb2JKFRS34lIEX3E',
    appId: '1:978444733436:ios:25e860ea8d343aa8bd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    storageBucket: 'alrafq-2025.firebasestorage.app',
    iosBundleId: 'com.example.rafiq',
    androidClientId: null, // Add if using Google Sign-In
    iosClientId: null, // Add if using Google Sign-In
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCXh5lPXKYgPlD674EAb2JKFRS34lIEX3E',
    appId: '1:978444733436:ios:25e860ea8d343aa8bd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    storageBucket: 'alrafq-2025.firebasestorage.app',
    iosBundleId: 'com.example.rafiq',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApI8EPT1RKHtiNBI2KIToBZ3puhC0ISZ4',
    appId: '1:978444733436:web:b8a91f4f88786a2bbd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    authDomain: 'alrafq-2025.firebaseapp.com',
    storageBucket: 'alrafq-2025.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyApI8EPT1RKHtiNBI2KIToBZ3puhC0ISZ4',
    appId: '1:978444733436:web:b8a91f4f88786a2bbd4079',
    messagingSenderId: '978444733436',
    projectId: 'alrafq-2025',
    authDomain: 'alrafq-2025.firebaseapp.com',
    storageBucket: 'alrafq-2025.firebasestorage.app',
  );
}
