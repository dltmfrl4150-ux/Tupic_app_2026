import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/locale_controller.dart';
import 'app/theme/tupic_colors.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: TupicColors.mainBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final firebaseReady = await _initializeFirebaseSafely();

  final localeController = LocaleController();
  await localeController.load();

  runApp(
    TupicApp(
      localeController: localeController,
      firebaseReady: firebaseReady,
    ),
  );
}

/// Initializes Firebase for Android and Web (same tupic-project).
/// Never falls back to an arbitrary Firebase project on failure.
Future<bool> _initializeFirebaseSafely() async {
  final supported =
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;
  if (!supported) {
    debugPrint(
      'Firebase: skipping init on $defaultTargetPlatform '
      '(Android/Web configured).',
    );
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase.initializeApp failed: $e');
    return false;
  }
}
