import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // case TargetPlatform.iOS:
      //   return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Preencha com os valores do novo google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1uFceFF6hyQUBRkd7e2hc1C0HMVxAuok', // client[0].api_key[0].current_key
    appId: '1:732610599730:android:c472b87553ac6daa33552b', // client[0].client_info.mobilesdk_app_id
    messagingSenderId: '732610599730', // project_info.project_number
    projectId: 'sggm-102e2', // project_info.project_id
    storageBucket: 'sggm-102e2.firebasestorage.app', // project_info.storage_bucket
  );

  // static const FirebaseOptions ios = FirebaseOptions(
  //   apiKey: 'AIzaSy...',
  //   appId: '1:123456789:ios:abcdef',
  //   messagingSenderId: '123456789',
  //   projectId: 'seu-projeto-id',
  //   storageBucket: 'seu-projeto.appspot.com',
  //   iosBundleId: 'com.ericksondutra.sggm',
  // );
}
