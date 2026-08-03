import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';
import 'package:maharashtra_tyres/services/inventory_service.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  bool _isLoadingData = false;
  String _userName = 'Admin';
  String _userInitials = 'AD';
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _inventory = [];

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard'),
    _NavItem(Icons.people_alt_outlined, 'Customers'),
    _NavItem(Icons.inventory_2_outlined, 'Inventory'),
    _NavItem(Icons.shopping_cart_outlined, 'Sales'),
    _NavItem(Icons.receipt_long_outlined, 'Invoices'),
    _NavItem(Icons.alarm_outlined, 'Reminders'),
    _NavItem(Icons.bar_chart_outlined, 'Reports'),
    _NavItem(Icons.account_balance_wallet_outlined, 'Revenue'),
    _NavItem(Icons.local_shipping_outlined, 'Suppliers'),
    _NavItem(Icons.notifications_outlined, 'Notifications'),
    _NavItem(Icons.settings_outlined, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingData = true);
    try {
      final name = await AuthService.getUserDisplayName();
      final initials = await AuthService.getUserInitials();
      final results = await Future.wait([
        InvoiceService.fetchInvoices(),
        CustomerService.fetchCustomers(),
        InventoryService.fetchInventory(),
      ]);

      if (mounted) {
        setState(() {
          _userName = name;
          _userInitials = initials;
          _invoices = results[0];
          _customers = results[1];
          _inventory = results[2];
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  double get _todaySalesAmount {
    if (_invoices.isEmpty) return 24500.0;
    double sum = 0;
    for (final inv in _invoices) {
      sum += double.tryParse(inv['total']?.toString() ?? '0') ?? 0;
    }
    return sum;
  }

  int get _todayOrdersCount {
    if (_invoices.isEmpty) return 15;
    return _invoices.length;
  }

  int get _customersCount {
    if (_customers.isEmpty) return 265;
    return _customers.length;
  }

  int get _productsCount {
    if (_inventory.isEmpty) return 430;
    return _inventory.length;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileLayout();
    }
    return _buildDesktopLayout();
  }

  // ─── DESKTOP LAYOUT ────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // ── Left Sidebar ──
          _buildSidebar(),
          // ── Main Content ──
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE LAYOUT ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: Drawer(child: _buildSidebar(isDrawer: true)),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          _buildTopBarActions(),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  // ─── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: 220,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.donut_large_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maharashtra\nTyres',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.25),
                        ),
                        Text(
                          'Tyre Shop Management',
                          style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final bool selected = i == _selectedNavIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedNavIndex = i);
                          if (isDrawer) Navigator.pop(context);
                          String? routeName;
                          if (item.label == 'Customers') routeName = '/customers';
                          if (item.label == 'Inventory') routeName = '/inventory';
                          if (item.label == 'Sales' || item.label == 'Reports' || item.label == 'Revenue') routeName = '/sales';
                          if (item.label == 'Invoices') routeName = '/invoices';
                          if (item.label == 'Reminders' || item.label == 'Notifications') routeName = '/reminders';
                          if (item.label == 'Settings') routeName = '/settings';

                          if (routeName != null) {
                            Navigator.pushNamed(context, routeName).then((_) {
                              if (!mounted) return;
                              setState(() => _selectedNavIndex = 0);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon, color: selected ? Colors.white : const Color(0xFFBFDBFE), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                LanguageService.tr(item.label.toLowerCase()),
                                style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFFBFDBFE),
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('is_logged_in');
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFBFDBFE), size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
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

  // ─── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Text(
            LanguageService.tr('dashboard'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Spacer(),
          _buildTopBarActions(),
        ],
      ),
    );
  }

  Widget _buildTopBarActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: _isLoadingData
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: _isLoadingData ? null : _loadDashboardData,
        ),
        const SizedBox(width: 8),
        // Notification bell
        Stack(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Profile
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(_userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  const Text('Super Admin', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  // ─── MAIN CONTENT ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth > 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingBar(wide),
            const SizedBox(height: 24),
            _buildStatsRow(wide),
            const SizedBox(height: 24),
            wide ? _buildWideBottom() : _buildNarrowBottom(),
          ],
        );
      },
    );
  }

  // ─── GREETING ──────────────────────────────────────────────────────────────
  Widget _buildGreetingBar(bool wide) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${LanguageService.tr('good_morning')}, $_userName ',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your business today.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        if (wide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('15 May 2025', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
      ],
    );
  }

  // ─── STATS ROW ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool wide) {
    return LayoutBuilder(builder: (context, c) {
      final int cols = c.maxWidth > 600 ? 4 : 2;

      final cardSales = StatCard(
        title: LanguageService.tr('todays_sales'),
        value: '₹${_todaySalesAmount.toStringAsFixed(0)}',
        icon: Icons.shopping_cart_outlined,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primaryLight,
        trendText: '+18.6% from yesterday',
        trendIcon: Icons.arrow_upward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.pushNamed(context, '/sales'),
      );

      final cardOrders = StatCard(
        title: LanguageService.tr('todays_orders'),
        value: '$_todayOrdersCount',
        icon: Icons.shopping_bag_outlined,
        iconColor: const Color(0xFF10B981),
        iconBackgroundColor: const Color(0xFFECFDF5),
        trendText: '+12% from yesterday',
        trendIcon: Icons.arrow_upward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.pushNamed(context, '/sales'),
      );

      final cardCustomers = StatCard(
        title: LanguageService.tr('customers'),
        value: '$_customersCount',
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFFF59E0B),
        iconBackgroundColor: const Color(0xFFFEF3C7),
        trendText: '+8.4% from last month',
        trendIcon: Icons.arrow_upward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.pushNamed(context, '/customers'),
      );

      final cardProducts = StatCard(
        title: LanguageService.tr('inventory'),
        value: '$_productsCount',
        icon: Icons.donut_large_rounded,
        iconColor: const Color(0xFF8B5CF6),
        iconBackgroundColor: const Color(0xFFF5F3FF),
        trendText: '+5.2% from last month',
        trendIcon: Icons.arrow_upward_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.pushNamed(context, '/inventory'),
      );

      if (cols == 4) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cardSales),
              const SizedBox(width: 16),
              Expanded(child: cardOrders),
              const SizedBox(width: 16),
              Expanded(child: cardCustomers),
              const SizedBox(width: 16),
              Expanded(child: cardProducts),
            ],
          ),
        );
      } else {
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cardSales),
                  const SizedBox(width: 16),
                  Expanded(child: cardOrders),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cardCustomers),
                  const SizedBox(width: 16),
                  Expanded(child: cardProducts),
                ],
              ),
            ),
          ],
        );
      }
    });
  }

  // ─── WIDE BOTTOM (2 COLUMNS) ────────────────────────────────────────────────
  Widget _buildWideBottom() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column – Revenue + Recent Sales
        Expanded(
          flex: 60,
          child: Column(
            children: [
              _buildRevenueCard(),
              const SizedBox(height: 20),
              _buildRecentSalesTable(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column – Quick Actions + Low Stock + Notifications
        Expanded(
          flex: 40,
          child: Column(
            children: [
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildLowStockAlert(),
              const SizedBox(height: 20),
              _buildRecentNotifications(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── NARROW BOTTOM (STACKED) ────────────────────────────────────────────────
  Widget _buildNarrowBottom() {
    return Column(
      children: [
        _buildRevenueCard(),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildRecentSalesTable(),
        const SizedBox(height: 16),
        _buildLowStockAlert(),
        const SizedBox(height: 16),
        _buildRecentNotifications(),
      ],
    );
  }

  // ─── REVENUE CARD ──────────────────────────────────────────────────────────
  Widget _buildRevenueCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('This Year', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple bar chart representation
          SizedBox(
            height: 160,
            child: _buildBarChart(),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRevStat(Icons.bar_chart_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'Total Revenue', '₹5,45,000'),
              const SizedBox(width: 16),
              _buildRevStat(Icons.trending_up_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5), 'Growth', '+18%\nvs last year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevStat(IconData icon, Color iconColor, Color iconBg, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final List<_BarData> bars = [
      _BarData('Jan', 0.35), _BarData('Feb', 0.4), _BarData('Mar', 0.52),
      _BarData('Apr', 0.58), _BarData('May', 0.85, highlight: true), _BarData('Jun', 0.5),
      _BarData('Jul', 0.42), _BarData('Aug', 0.6), _BarData('Sep', 0.55),
      _BarData('Oct', 0.65), _BarData('Nov', 0.7), _BarData('Dec', 0.75),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((b) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (b.highlight)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('May\n₹65,400', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                  ),
                Container(
                  height: 90 * b.value,
                  decoration: BoxDecoration(
                    gradient: b.highlight
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFBFDBFE), Color(0xFFBFDBFE)],
                          ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(b.label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── RECENT SALES TABLE ────────────────────────────────────────────────────
  Widget _buildRecentSalesTable() {
    final List<List<String>> rows = _invoices.isNotEmpty
        ? _invoices.take(5).map((inv) {
            final num = inv['invoice_number']?.toString() ?? 'INV';
            final name = inv['customer_name']?.toString() ?? 'Customer';
            final amt = '₹${inv['total'] ?? '0'}';
            final rawStatus = inv['status']?.toString() ?? 'Paid';
            final status = rawStatus.isNotEmpty
                ? rawStatus[0].toUpperCase() + rawStatus.substring(1)
                : 'Paid';
            final date = inv['due_date']?.toString() ?? 'Recent';
            return [num, name, amt, status, date];
          }).toList()
        : [
            ['INV-1005', 'Rohan Patil', '₹4,250', 'Paid', '15 May 2025'],
            ['INV-1004', 'Sagar More', '₹2,800', 'Paid', '15 May 2025'],
            ['INV-1003', 'Amit Shinde', '₹6,500', 'Pending', '14 May 2025'],
            ['INV-1002', 'Swapnil Jadhav', '₹3,200', 'Paid', '14 May 2025'],
            ['INV-1001', 'Vikas Kale', '₹1,750', 'Pending', '13 May 2025'],
          ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LanguageService.tr('recent_sales'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Invoice No.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('Customer Name', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          ...rows.map((r) {
            final bool isPaid = r[3].toLowerCase() == 'paid';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(r[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                  Expanded(flex: 3, child: Text(r[1], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                  Expanded(flex: 2, child: Text(r[2], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r[3],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 3, child: Text(r[4], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/sales'),
              icon: Text(LanguageService.tr('view_all_sales'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              label: const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(Icons.person_add_alt_1_outlined, 'Add Customer', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      _QuickAction(Icons.point_of_sale_outlined, 'New Sale', const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _QuickAction(Icons.inventory_2_outlined, 'Inventory', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
      _QuickAction(Icons.receipt_outlined, 'Generate Invoice', const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _QuickAction(Icons.pie_chart_outline, 'Revenue', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
      _QuickAction(Icons.bar_chart_outlined, 'Reports', const Color(0xFF059669), const Color(0xFFECFDF5)),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LanguageService.tr('quick_actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: actions.map((a) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (a.label == 'Add Customer') {
                    Navigator.pushNamed(context, '/add-customer');
                  } else if (a.label == 'New Sale' || a.label == 'Revenue' || a.label == 'Reports') {
                    Navigator.pushNamed(context, '/sales');
                  } else if (a.label == 'Inventory') {
                    Navigator.pushNamed(context, '/inventory');
                  } else if (a.label == 'Generate Invoice') {
                    Navigator.pushNamed(context, '/invoices');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: a.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: a.iconColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: a.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a.icon, color: a.iconColor, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── LOW STOCK ALERT ───────────────────────────────────────────────────────
  Widget _buildLowStockAlert() {
    final List<List<String>> items = _inventory.isNotEmpty
        ? _inventory
            .where((item) {
              final qty = int.tryParse(item['quantity']?.toString() ?? '99') ?? 99;
              final status = item['status']?.toString().toLowerCase() ?? '';
              return qty <= 10 || status == 'low_stock' || status == 'out_of_stock';
            })
            .take(5)
            .map((item) => [
                  item['product_name']?.toString() ?? 'Tyre Item',
                  '${item['quantity'] ?? '0'} Left'
                ])
            .toList()
        : [
            ['MRF ZLX', '2 Left'],
            ['Apollo Amazer', '3 Left'],
            ['CEAT Milaze', '1 Left'],
          ];

    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(LanguageService.tr('low_stock_alert'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/inventory'),
                child: Text(LanguageService.tr('view_inventory'), style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('All stock levels normal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.donut_large_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item[0], style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item[1], style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ─── RECENT NOTIFICATIONS ──────────────────────────────────────────────────
  Widget _buildRecentNotifications() {
    final notifs = [
      _Notif(Icons.person_add_alt_1, const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'New customer Rohan Patil added', '10 min ago'),
      _Notif(Icons.receipt_long, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), 'Invoice INV-1005 generated', '20 min ago'),
      _Notif(Icons.inventory_2, const Color(0xFFF59E0B), const Color(0xFFFEF3C7), 'Stock updated for MRF ZLX', '1 hour ago'),
      _Notif(Icons.check_circle_outline, const Color(0xFF10B981), const Color(0xFFECFDF5), 'Payment received from Amit Shinde', '2 hours ago'),
    ];

    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 16),
          ...notifs.map((n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: n.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(n.icon, color: n.iconColor, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(n.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── SHARED CARD WRAPPER ───────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── DATA MODELS ───────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _BarData {
  const _BarData(this.label, this.value, {this.highlight = false});
  final String label;
  final double value;
  final bool highlight;
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.iconColor, this.bgColor);
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
}

class _Notif {
  const _Notif(this.icon, this.iconColor, this.bgColor, this.message, this.time);
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String message;
  final String time;
}
