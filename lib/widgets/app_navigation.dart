import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/language_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String?> appCurrentRoute = ValueNotifier<String?>(null);

class AppNavigationObserver extends NavigatorObserver {
  String? _pendingRouteName;
  bool _routeUpdateScheduled = false;

  void _setCurrentRoute(Route<dynamic>? route) {
    final routeName = route?.settings.name;
    if (routeName == null) return;

    _pendingRouteName = routeName;
    if (_routeUpdateScheduled) return;

    _routeUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeUpdateScheduled = false;
      final currentRouteName = _pendingRouteName;
      _pendingRouteName = null;
      if (currentRouteName != null &&
          appCurrentRoute.value != currentRouteName) {
        appCurrentRoute.value = currentRouteName;
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrentRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrentRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _setCurrentRoute(newRoute);
  }
}

class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    super.key,
    required this.routeName,
    required this.child,
  });

  final String? routeName;
  final Widget child;

  static const double sidebarWidth = 230;
  static const double desktopBreakpoint = 1024;

  static bool hasPersistentSidebar(BuildContext context) =>
      _NavigationSidebarScope.hasPersistentSidebarInTree(context);

  static const Set<String> _authenticatedRoutes = {
    '/dashboard',
    '/customers',
    '/add-customer',
    '/edit-customer',
    '/inventory',
    '/add-inventory',
    '/edit-inventory',
    '/bills',
    '/sales',
    '/invoices',
    '/add-invoice',
    '/edit-invoice',
    '/reminders',
    '/settings',
  };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!_authenticatedRoutes.contains(routeName)) {
      return child;
    }
    if (media.size.width < desktopBreakpoint || routeName != '/dashboard') {
      return _NavigationSidebarScope(hasPersistentSidebar: false, child: child);
    }

    return Row(
      children: [
        SizedBox(
          width: sidebarWidth,
          child: AppSidebarPanel(routeName: routeName),
        ),
        Expanded(
          child: MediaQuery(
            data: media.copyWith(
              size: Size(media.size.width - sidebarWidth, media.size.height),
            ),
            child: _NavigationSidebarScope(
              hasPersistentSidebar: true,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class AppSidebarDrawer extends StatelessWidget {
  const AppSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: AppSidebarPanel(
        routeName:
            ModalRoute.of(context)?.settings.name ?? appCurrentRoute.value,
        isDrawer: true,
      ),
    );
  }
}

class AppSidebarButton extends StatelessWidget {
  const AppSidebarButton({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    if (_NavigationSidebarScope.hasPersistentSidebarInTree(context)) {
      return const SizedBox.shrink();
    }
    final routeName =
        ModalRoute.of(context)?.settings.name ?? appCurrentRoute.value;
    final isDashboard = routeName == '/dashboard';
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Builder(
        builder: (scaffoldContext) => IconButton(
          tooltip: isDashboard ? 'Open navigation menu' : 'Go back',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          icon: Icon(
            isDashboard ? Icons.menu_rounded : Icons.arrow_back_rounded,
            color: color,
            size: 23,
          ),
          onPressed: () {
            if (isDashboard) {
              Scaffold.of(scaffoldContext).openDrawer();
              return;
            }
            final navigator = appNavigatorKey.currentState;
            if (navigator == null) return;
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              navigator.pushNamedAndRemoveUntil('/dashboard', (_) => false);
            }
          },
        ),
      ),
    );
  }
}

class _NavigationSidebarScope extends InheritedWidget {
  const _NavigationSidebarScope({
    required this.hasPersistentSidebar,
    required super.child,
  });

  final bool hasPersistentSidebar;

  static bool hasPersistentSidebarInTree(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_NavigationSidebarScope>()
          ?.hasPersistentSidebar ??
      false;

  @override
  bool updateShouldNotify(_NavigationSidebarScope oldWidget) =>
      hasPersistentSidebar != oldWidget.hasPersistentSidebar;
}

class AppSidebarPanel extends StatelessWidget {
  const AppSidebarPanel({super.key, this.routeName, this.isDrawer = false});

  final String? routeName;
  final bool isDrawer;

  static const List<_SidebarDestination> _destinations = [
    _SidebarDestination(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    _SidebarDestination(Icons.people_alt_outlined, 'Customers', '/customers'),
    _SidebarDestination(Icons.inventory_2_outlined, 'Inventory', '/inventory'),
    _SidebarDestination(Icons.shopping_cart_outlined, 'Sales', '/sales'),
    _SidebarDestination(Icons.receipt_long_outlined, 'Invoices', '/invoices'),
    _SidebarDestination(Icons.receipt_outlined, 'Bills', '/bills'),
    _SidebarDestination(Icons.alarm_outlined, 'Reminders', '/reminders'),
    _SidebarDestination(Icons.bar_chart_outlined, 'Reports', '/sales'),
    _SidebarDestination(
      Icons.account_balance_wallet_outlined,
      'Revenue',
      '/sales',
    ),
    _SidebarDestination(Icons.local_shipping_outlined, 'Suppliers', null),
    _SidebarDestination(
      Icons.notifications_outlined,
      'Notifications',
      '/reminders',
    ),
    _SidebarDestination(Icons.settings_outlined, 'Settings', '/settings'),
  ];

  String _sectionForRoute(String? route) {
    switch (route) {
      case '/add-customer':
      case '/edit-customer':
        return '/customers';
      case '/add-inventory':
      case '/edit-inventory':
        return '/inventory';
      case '/add-invoice':
      case '/edit-invoice':
        return '/invoices';
      default:
        return route ?? '/dashboard';
    }
  }

  void _navigate(BuildContext context, String route) {
    if (isDrawer) Navigator.of(context).pop();
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    if (route == '/dashboard') {
      navigator.popUntil(
        (existingRoute) => existingRoute.settings.name == '/dashboard',
      );
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      route,
      (existingRoute) => existingRoute.settings.name == '/dashboard',
    );
  }

  Future<void> _logout(BuildContext context) async {
    if (isDrawer) Navigator.of(context).pop();
    await AuthService.logout();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (existingRoute) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = _sectionForRoute(routeName ?? appCurrentRoute.value);
    return Container(
      width: isDrawer ? double.infinity : AppNavigationShell.sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073822), Color(0xFF0F5132)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'lib/widgets/maha_tyre_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.tr('app_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        const Text(
                          'Inventory & Billing',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  final selected = destination.route == selectedRoute;
                  final enabled = destination.route != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: enabled
                          ? () => _navigate(context, destination.route!)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              destination.icon,
                              color: enabled
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(
                                      0xFFA7F3D0,
                                    ).withValues(alpha: 0.45),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              LanguageService.tr(
                                destination.label.toLowerCase(),
                              ),
                              style: TextStyle(
                                color: enabled
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(
                                        0xFFA7F3D0,
                                      ).withValues(alpha: 0.45),
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _logout(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFA7F3D0),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        LanguageService.tr('logout'),
                        style: const TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarDestination {
  const _SidebarDestination(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String? route;
}
