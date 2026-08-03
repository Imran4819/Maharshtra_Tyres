import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/screens/add_customer_screen.dart';
import 'package:maharashtra_tyres/screens/customers_screen.dart';
import 'package:maharashtra_tyres/screens/dashboard_screen.dart';
import 'package:maharashtra_tyres/screens/inventory_screen.dart';
import 'package:maharashtra_tyres/screens/invoices_screen.dart';
import 'package:maharashtra_tyres/screens/login_screen.dart';
import 'package:maharashtra_tyres/screens/otp_login_screen.dart';
import 'package:maharashtra_tyres/screens/otp_verify_screen.dart';
import 'package:maharashtra_tyres/screens/reminders_screen.dart';
import 'package:maharashtra_tyres/screens/sales_screen.dart';
import 'package:maharashtra_tyres/screens/settings_screen.dart';
import 'package:maharashtra_tyres/screens/splash_screen.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.initLanguage();
  runApp(const MaharashtraTyresApp());
}

class MaharashtraTyresApp extends StatelessWidget {
  const MaharashtraTyresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, currentLang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: LanguageService.tr('app_title'),
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/otp-login': (_) => const OtpLoginScreen(),
            '/otp-verify': (_) => const OtpVerifyScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/customers': (_) => const CustomersScreen(),
            '/inventory': (_) => const InventoryScreen(),
            '/sales': (_) => const SalesScreen(),
            '/invoices': (_) => const InvoicesScreen(),
            '/reminders': (_) => const RemindersScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/add-customer': (_) => const AddCustomerScreen(),
          },
        );
      },
    );
  }
}
