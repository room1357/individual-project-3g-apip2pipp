// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/expense_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';

// screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/category_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/looping_demo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        // ⬇️ PROVIDER UNTUK AUTH (wajib ada agar context.read<AuthService>() tidak error)
        ChangeNotifierProvider(create: (_) => AuthService()..loadSession()),
        // ⬇️ PROVIDER LAMA UNTUK EXPENSE
        ChangeNotifierProvider(
          create:
              (_) =>
                  ExpenseService(StorageService())
                    ..init(fallbackUser: 'user-1'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SakuRapi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // pakai named routes
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/expenses': (_) => const ExpenseListScreen(),
        '/categories': (_) => const CategoryScreen(),
        '/stats': (_) => const StatisticsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/about': (_) => const AboutScreen(),
        '/loops': (_) => const LoopingDemoScreen(), // <- tanpa spasi
      },
    );
  }
}
