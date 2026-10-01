import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/reminder_notification_service.dart';
import 'package:maharashtra_tyres/services/push_notification_service.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/screens/add_customer_screen.dart';
import 'package:maharashtra_tyres/screens/edit_customer_screen.dart';
import 'package:maharashtra_tyres/screens/add_inventory_screen.dart';
import 'package:maharashtra_tyres/screens/edit_inventory_screen.dart';
import 'package:maharashtra_tyres/screens/add_invoice_screen.dart';
import 'package:maharashtra_tyres/screens/edit_invoice_screen.dart';
import 'package:maharashtra_tyres/screens/customers_screen.dart';
import 'package:maharashtra_tyres/screens/dashboard_screen.dart';
import 'package:maharashtra_tyres/screens/bills_screen.dart';
import 'package:maharashtra_tyres/screens/inventory_screen.dart';
import 'package:maharashtra_tyres/screens/invoices_screen.dart';
import 'package:maharashtra_tyres/screens/login_screen.dart';
import 'package:maharashtra_tyres/screens/otp_login_screen.dart';
import 'package:maharashtra_tyres/screens/otp_verify_screen.dart';
import 'package:maharashtra_tyres/screens/reminders_screen.dart';
import 'package:maharashtra_tyres/screens/sales_screen.dart';
import 'package:maharashtra_tyres/screens/settings_screen.dart';
import 'package:maharashtra_tyres/screens/signup_screen.dart';
import 'package:maharashtra_tyres/screens/splash_screen.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

final AppNavigationObserver appNavigationObserver = AppNavigationObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.initLanguage();
  await AppTheme.initTheme();
  await ReminderNotificationService.instance.initialize(
    navigatorKey: appNavigatorKey,
  );
  await PushNotificationService.instance.initialize();
  runApp(const MaharashtraTyresApp());
}

class MaharashtraTyresApp extends StatelessWidget {
  const MaharashtraTyresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageService.currentLanguage,
          builder: (context, currentLang, child) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              navigatorObservers: [appNavigationObserver],
              builder: (context, child) => ValueListenableBuilder<String?>(
                valueListenable: appCurrentRoute,
                builder: (context, routeName, navigatorChild) =>
                    AppNavigationShell(
                      routeName: routeName,
                      child: navigatorChild ?? const SizedBox.shrink(),
                    ),
                child: child,
              ),
              debugShowCheckedModeBanner: false,
              title: LanguageService.tr('app_title'),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              initialRoute: '/',
              routes: {
                '/': (_) => const SplashScreen(),
                '/login': (_) => const LoginScreen(),
                '/signup': (_) => const SignUpScreen(),
                '/otp-login': (_) => const OtpLoginScreen(),
                '/otp-verify': (_) => const OtpVerifyScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                '/bills': (_) => const BillsScreen(),
                '/customers': (_) => const CustomersScreen(),
                '/add-customer': (_) => const AddCustomerScreen(),
                '/edit-customer': (_) => const EditCustomerScreen(),
                '/inventory': (_) => const InventoryScreen(),
                '/add-inventory': (_) => const AddInventoryScreen(),
                '/edit-inventory': (_) => const EditInventoryScreen(),
                '/sales': (_) => const SalesScreen(),
                '/invoices': (_) => const InvoicesScreen(),
                '/add-invoice': (_) => const AddInvoiceScreen(),
                '/edit-invoice': (_) => const EditInvoiceScreen(),
                '/reminders': (_) => const RemindersScreen(),
                '/settings': (_) => const SettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
