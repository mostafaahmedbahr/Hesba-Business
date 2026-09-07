import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-i2ZUVDajVTsAZuctQRIRYDf7GF0aVqs',
    appId: '1:877017690588:android:60325e8186b7900a545f19',
    messagingSenderId: '877017690588',
    projectId: 'hesba-business',
    storageBucket: 'hesba-business.firebasestorage.app',
  );

  // TODO: Add iOS config from GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '877017690588',
    projectId: 'hesba-business',
    storageBucket: 'hesba-business.firebasestorage.app',
    iosBundleId: 'com.zerobugs.hesba',
  );

  // TODO: Add Web config from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '877017690588',
    projectId: 'hesba-business',
    storageBucket: 'hesba-business.firebasestorage.app',
    authDomain: 'hesba-business.firebaseapp.com',
  );
}
