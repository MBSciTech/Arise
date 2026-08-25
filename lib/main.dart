import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/database/database.dart';
import 'features/onboarding/onboarding_screen.dart';

import 'features/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AriseApp(),
    ),
  );
}

class AriseApp extends ConsumerWidget {
  const AriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Arise',
      theme: AppTheme.darkTheme,
      home: const InitialLoaderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialLoaderScreen extends ConsumerStatefulWidget {
  const InitialLoaderScreen({super.key});

  @override
  ConsumerState<InitialLoaderScreen> createState() => _InitialLoaderScreenState();
}

class _InitialLoaderScreenState extends ConsumerState<InitialLoaderScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final db = ref.read(appDatabaseProvider);
    final profiles = await db.select(db.userProfiles).get();
    
    if (mounted) {
      if (profiles.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Assuming dark theme is preferred for splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150, // Adjust size as necessary
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, size: 64, color: Colors.greenAccent),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
