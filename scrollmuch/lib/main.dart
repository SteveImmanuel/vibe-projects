import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/scroll_platform_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ScrollPlatformService>(create: (_) => ScrollPlatformService()),
      ],
      child: const ScrollMuchApp(),
    ),
  );
}

class ScrollMuchApp extends StatelessWidget {
  const ScrollMuchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final hasCompletedOnboarding = storage.hasCompletedOnboarding;

    return MaterialApp(
      title: 'ScrollMuch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        fontFamily: 'sans-serif',
      ),
      home: hasCompletedOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
