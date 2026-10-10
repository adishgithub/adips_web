import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/theme_mode_store.dart';
import 'data/services/auth_session.dart';
import 'utils/http/http_client.dart';
import 'routes/app_pages.dart';
import 'utils/theme/adips_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // /dashboard instead of /#/dashboard. The host must rewrite unknown paths
  // to index.html (`flutter run -d chrome` already does).
  usePathUrlStrategy();

  await GetStorage.init();

  // Any 401 on a token-carrying request ends the session (-> /login).
  AdipsHttpHelper.onUnauthorized = () => AuthSession.expire();

  runApp(const AdipsWebApp());

  // Confirm the saved token with the server without blocking startup.
  AuthSession.validateInBackground();
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
      unknownRoute: AppPages.unknown,
    );
  }
}
