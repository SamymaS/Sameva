import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'env_config.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: EnvConfig.firebaseApiKey,
          authDomain: EnvConfig.firebaseAuthDomain,
          projectId: EnvConfig.firebaseProjectId,
          storageBucket: EnvConfig.firebaseStorageBucket,
          messagingSenderId: EnvConfig.firebaseMessagingSenderId,
          appId: EnvConfig.firebaseAppId,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur d\'initialisation Firebase: $e');
      }
    }
  }
} 