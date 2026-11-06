import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/locale_controller.dart';
import 'app/theme/tupic_colors.dart';

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

  final localeController = LocaleController();
  await localeController.load();

  runApp(TupicApp(localeController: localeController));
}
