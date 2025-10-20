// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/expense_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/shared_expense_service.dart';

// screens
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/category_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/looping_demo_screen.dart';
import 'screens/shared_expense_screen.dart';
import 'screens/add_shared_expense_screen.dart';
import 'screens/user_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        // ⬇️ PROVIDER UNTUK AUTH (wajib ada agar context.read<AuthService>() tidak error)
        ChangeNotifierProvider(create: (_) => AuthService()..loadSession()),
        // ⬇️ PROVIDER UNTUK EXPENSE (terintegrasi dengan AuthService)
        ChangeNotifierProxyProvider<AuthService, ExpenseService>(
          create: (context) {
            final expenseService = ExpenseService(StorageService());
            // Inisialisasi dengan fallback user
            expenseService.init(fallbackUser: 'user-1');
            return expenseService;
          },
          update: (context, authService, previous) {
            final expenseService = previous ?? ExpenseService(StorageService());

            // Switch user saat ada perubahan di AuthService
            if (authService.isLoggedIn &&
                authService.currentUserEmail != null) {
              expenseService.switchUser(authService.currentUserEmail!);
            }

            return expenseService;
          },
        ),
        // ⬇️ PROVIDER UNTUK SHARED EXPENSE
        ChangeNotifierProxyProvider2<
          AuthService,
          ExpenseService,
          SharedExpenseService
        >(
          create:
              (context) => SharedExpenseService(
                context.read<AuthService>(),
                context.read<ExpenseService>(),
              ),
          update:
              (context, authService, expenseService, previous) =>
                  previous ?? SharedExpenseService(authService, expenseService),
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
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/expenses': (_) => const ExpenseListScreen(),
        '/categories': (_) => const CategoryScreen(),
        '/stats': (_) => const StatisticsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/about': (_) => const AboutScreen(),
        '/loops': (_) => const LoopingDemoScreen(), // <- tanpa spasi
        '/shared-expenses': (_) => const SharedExpenseScreen(),
        '/add-shared-expense': (_) => const AddSharedExpenseScreen(),
        '/user-selection': (_) => const UserSelectionScreen(),
      },
    );
  }
}
