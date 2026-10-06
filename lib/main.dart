import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/theme_mode_store.dart';
import 'routes/app_pages.dart';
import 'utils/theme/adips_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const AdipsWebApp());
}

class AdipsWebApp extends StatelessWidget {
  const AdipsWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ADIPS',
      debugShowCheckedModeBanner: false,
      theme: AdipsAppTheme.lightTheme,
      darkTheme: AdipsAppTheme.darkTheme,
      themeMode: ThemeModeStore.load(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
