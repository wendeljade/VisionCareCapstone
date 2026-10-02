import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/custom_material_localizations.dart';
import 'Pages/Dashboard.dart';
import 'Pages/Scan.dart';
import 'Pages/History.dart';
import 'Pages/AboutPage.dart';
import 'Pages/LoginPage.dart';
import 'Pages/RegisterPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String currentRoute = '/register';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    if (kDebugMode) {
      print("EasyLocalization initialization error: $e");
    }
  }
  
  try {
    await initializeDateFormatting('en', null);
  } catch (e) {
    if (kDebugMode) {
      print("Date formatting initialization error: $e");
    }
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
      ],
      path: 'Assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        const CustomMaterialLocalizations(),
        const CustomCupertinoLocalizations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...context.localizationDelegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'VisionCare',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        primaryColor: const Color(0xFF12343B),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF12343B),
          secondary: Color(0xFF63C7B2),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFC95757),
          onPrimary: Colors.white,
          onSecondary: Color(0xFF12343B),
          onSurface: Color(0xFF203238),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF9),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF12343B)),
          titleTextStyle: TextStyle(
            color: Color(0xFF12343B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        dividerColor: const Color(0xFFDCE8E5),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RegisterPage(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const Dashboard(),
        '/history': (context) => const History(),
        '/scan': (context) => const Scan(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}
