import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/screens/splash_screen.dart';
import 'package:app_geriatrico/screens/login_screen.dart';

// Permite certificados SSL con cadena incompleta en Windows y otros dispositivos
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Aplicar override global de SSL
  HttpOverrides.global = MyHttpOverrides();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E0619),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ResidenciaCarlotaApp());
}

class ResidenciaCarlotaApp extends StatefulWidget {
  const ResidenciaCarlotaApp({super.key});

  @override
  State<ResidenciaCarlotaApp> createState() => _ResidenciaCarlotaAppState();
}

class _ResidenciaCarlotaAppState extends State<ResidenciaCarlotaApp> {
  final AppLinks appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<Uri>? sub;

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Residencia Carlota',

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1E0619),
        fontFamily: 'Roboto',
        useMaterial3: true,

        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF3A0B32),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),

        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primaryLight,
          onSecondary: Colors.white,
          surface: const Color(0xFF2A0825),
          error: AppColors.error,
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}