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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqAY0-nkc-oqlxqIkvMLsRB3CX3IxxAO8',
    appId: '1:103420871732:web:4fd3d919c6441a94a77661',
    messagingSenderId: '103420871732',
    projectId: 'sameva-project',
    authDomain: 'sameva-project.firebaseapp.com',
    storageBucket: 'sameva-project.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQwa-Khm_TRI2u-3_TkteybFEVic1kW-E',
    appId: '1:103420871732:android:2b7a1abc218c5693a77661',
    messagingSenderId: '103420871732',
    projectId: 'sameva-project',
    storageBucket: 'sameva-project.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuO4Clu5_cJ2488QvzW5F6GK9n7qCY2JM',
    appId: '1:103420871732:ios:2f96facda2b102b4a77661',
    messagingSenderId: '103420871732',
    projectId: 'sameva-project',
    storageBucket: 'sameva-project.firebasestorage.app',
    iosBundleId: 'com.sameva.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAqAY0-nkc-oqlxqIkvMLsRB3CX3IxxAO8',
    appId: '1:103420871732:web:8b6410634b2a609fa77661',
    messagingSenderId: '103420871732',
    projectId: 'sameva-project',
    authDomain: 'sameva-project.firebaseapp.com',
    storageBucket: 'sameva-project.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCuO4Clu5_cJ2488QvzW5F6GK9n7qCY2JM',
    appId: '1:103420871732:ios:2f96facda2b102b4a77661',
    messagingSenderId: '103420871732',
    projectId: 'sameva-project',
    storageBucket: 'sameva-project.firebasestorage.app',
    iosBundleId: 'com.sameva.app',
  );
} 