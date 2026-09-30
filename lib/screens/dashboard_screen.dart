import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';
import 'package:maharashtra_tyres/services/inventory_service.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingData = false;
  String _userName = 'Admin';
  String _userInitials = 'AD';
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _inventory = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        AuthService.getUserDisplayName(),
        AuthService.getUserInitials(),
        InvoiceService.fetchInvoices(),
        CustomerService.fetchCustomers(),
        InventoryService.fetchInventory(),
      ]);
      if (!mounted) return;
      setState(() {
        _userName = results[0] as String;
        _userInitials = results[1] as String;
        _invoices = results[2] as List<Map<String, dynamic>>;
        _customers = results[3] as List<Map<String, dynamic>>;
        _inventory = results[4] as List<Map<String, dynamic>>;
        _isLoadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  List<Map<String, dynamic>> get _todayInvoices => _invoices.where((invoice) {
    final date = _invoiceDate(invoice);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }).toList();

  double get _todaySales => _todayInvoices.fold<double>(
    0,
    (sum, invoice) => sum + _invoiceAmount(invoice),
  );

  double get _monthSales {
    final now = DateTime.now();
    return _invoices
        .where((invoice) {
          final date = _invoiceDate(invoice);
          return date != null &&
              date.year == now.year &&
              date.month == now.month;
        })
        .fold<double>(0, (sum, invoice) => sum + _invoiceAmount(invoice));
  }

  int get _activeProducts => _inventory.where((item) {
    return (item['status']?.toString().toLowerCase() ?? 'active') == 'active';
  }).length;

  int get _lowStockCount => _inventory.where((item) {
    final status = item['status']?.toString().toLowerCase() ?? 'active';
    final quantity = _number(item['quantity']);
    return status == 'active' && quantity >= 0 && quantity <= 5;
  }).length;

  List<Map<String, dynamic>> get _recentInvoices {
    final result = [..._invoices];
    result.sort((a, b) {
      final aDate = _invoiceDate(a) ?? DateTime(1970);
      final bDate = _invoiceDate(b) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _lowStockItems {
    final result = _inventory.where((item) {
      final status = item['status']?.toString().toLowerCase() ?? 'active';
      final quantity = _number(item['quantity']);
      return status == 'active' && quantity >= 0 && quantity <= 5;
    }).toList();
    result.sort(
      (a, b) => _number(a['quantity']).compareTo(_number(b['quantity'])),
    );
    return result.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 768) return _buildMobileLayout();
    return _buildDesktopLayout(
      showLocalSidebar: !AppNavigationShell.hasPersistentSidebar(context),
    );
  }

  Widget _buildDesktopLayout({required bool showLocalSidebar}) {
    return Scaffold(
      backgroundColor: AppColors.getScaffoldBg(context),
      body: Row(
        children: [
          if (showLocalSidebar)
            const SizedBox(
              width: AppNavigationShell.sidebarWidth,
              child: AppSidebarPanel(routeName: '/dashboard'),
            ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(child: _buildRefreshableContent(isMobile: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.getScaffoldBg(context),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(LanguageService.tr('dashboard')),
        actions: [_buildHeaderActions(compact: true)],
      ),
      body: _buildRefreshableContent(isMobile: true),
    );
  }

  Widget _buildDesktopHeader() {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        border: Border(bottom: BorderSide(color: AppColors.getBorder(context))),
      ),
      child: Row(
        children: [
          Text(
            LanguageService.tr('dashboard'),
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Container(
              height: 24,
              width: 1,
              color: AppColors.getBorder(context),
            ),
            const SizedBox(width: 12),
            Text(
              'Business overview',
              style: TextStyle(
                color: AppColors.getTextMuted(context),
                fontSize: 13,
              ),
            ),
          ],
          const Spacer(),
          _buildHeaderActions(compact: compact),
        ],
      ),
    );
  }

  Widget _buildHeaderActions({required bool compact}) {
    return Padding(
      padding: EdgeInsets.only(right: compact ? 8 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Reminders',
            onTap: () => Navigator.pushNamed(context, '/reminders'),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              padding: EdgeInsets.all(compact ? 2 : 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _InitialAvatar(
                    initials: _userInitials,
                    size: compact ? 34 : 36,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            color: AppColors.getTextMuted(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.getTextMuted(context),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.getScaffoldBg(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: AppColors.getTextSecondary(context),
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshableContent({required bool isMobile}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = isMobile ? double.infinity : 1380.0;
        return RefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 30,
              vertical: isMobile ? 18 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomePanel(constraints.maxWidth),
                    const SizedBox(height: 22),
                    _buildSectionHeading(
                      'At a glance',
                      'Live totals from your business data',
                    ),
                    const SizedBox(height: 12),
                    _buildMetricGrid(constraints.maxWidth),
                    const SizedBox(height: 26),
                    _buildLowerContent(constraints.maxWidth),
                    const SizedBox(height: 24),
                    _buildQuickActions(constraints.maxWidth),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomePanel(double availableWidth) {
    final compact = availableWidth < 520;
    final today = DateTime.now();
    final dateLabel = '${_monthName(today.month)} ${today.day}, ${today.year}';
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF073822), Color(0xFF0F5132), Color(0xFF087F5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -45,
            child: Icon(
              Icons.donut_large_rounded,
              size: 190,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeMessage(compact: true, dateLabel: dateLabel),
                const SizedBox(height: 20),
                _todaySalesPanel(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: _welcomeMessage(compact: false, dateLabel: dateLabel),
                ),
                const SizedBox(width: 28),
                Expanded(flex: 4, child: _todaySalesPanel()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _welcomeMessage({required bool compact, required String dateLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 15,
              color: AppColors.primarySoft.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 7),
            Text(
              dateLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back, $_userName',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 25 : 29,
            height: 1.12,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Here is what is happening with your business today.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/add-invoice'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Create invoice',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _todaySalesPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S SALES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currency(_todaySales),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_todayInvoices.length} ${_todayInvoices.length == 1 ? 'invoice' : 'invoices'} today',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.getTextMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingData)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryAccent,
            ),
          ),
      ],
    );
  }

  Widget _buildMetricGrid(double width) {
    final contentWidth = width - (width < 768 ? 32 : 60);
    final columns = contentWidth >= 1000
        ? 4
        : contentWidth >= 330
        ? 2
        : 1;
    final tileWidth = (contentWidth - (columns - 1) * 14) / columns;
    final tileHeight = tileWidth < 200
        ? 145.0
        : tileWidth < 300
        ? 165.0
        : 180.0;
    final metrics = <_DashboardMetric>[
      _DashboardMetric(
        label: 'Sales this month',
        value: _currency(_monthSales),
        detail: '${_monthInvoices.length} invoices',
        icon: Icons.trending_up_rounded,
        tint: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, '/sales'),
      ),
      _DashboardMetric(
        label: 'Customers',
        value: _customers.length.toString(),
        detail: 'Customer directory',
        icon: Icons.people_alt_outlined,
        tint: const Color(0xFF0E9F6E),
        onTap: () => Navigator.pushNamed(context, '/customers'),
      ),
      _DashboardMetric(
        label: 'Products',
        value: _inventory.length.toString(),
        detail: '$_activeProducts active in stock',
        icon: Icons.inventory_2_outlined,
        tint: const Color(0xFF6574CD),
        onTap: () => Navigator.pushNamed(context, '/inventory'),
      ),
      _DashboardMetric(
        label: 'Low stock',
        value: _lowStockCount.toString(),
        detail: _lowStockCount == 0
            ? 'Stock levels look good'
            : 'Products need attention',
        icon: Icons.warning_amber_rounded,
        tint: _lowStockCount == 0 ? AppColors.primaryAccent : AppColors.warning,
        onTap: () => Navigator.pushNamed(context, '/inventory'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: tileWidth / tileHeight,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }

  List<Map<String, dynamic>> get _monthInvoices => _invoices.where((invoice) {
    final date = _invoiceDate(invoice);
    final now = DateTime.now();
    return date != null && date.year == now.year && date.month == now.month;
  }).toList();

  Widget _buildLowerContent(double width) {
    final wide = width >= 940;
    if (wide) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildRevenueCard()),
              const SizedBox(width: 18),
              Expanded(flex: 5, child: _buildRecentInvoicesCard()),
            ],
          ),
          const SizedBox(height: 18),
          _buildStockCard(),
        ],
      );
    }
    return Column(
      children: [
        _buildRevenueCard(),
        const SizedBox(height: 18),
        _buildRecentInvoicesCard(),
        const SizedBox(height: 18),
        _buildStockCard(),
      ],
    );
  }

  Widget _buildRevenueCard() {
    final values = _lastSixMonthsSales;
    final maxValue = values.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardTitle('Revenue overview', 'Monthly invoice totals'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      DateTime.now().year.toString(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency(_monthSales),
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'this month',
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final month in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message:
                                    '${month.label}: ${_currency(month.value)}',
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 24,
                                  height: maxValue == 0
                                      ? 5
                                      : (month.value / maxValue * 105)
                                            .clamp(5, 105)
                                            .toDouble(),
                                  decoration: BoxDecoration(
                                    color: month.isCurrent
                                        ? AppColors.primaryAccent
                                        : AppColors.primaryLight,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            month.label,
                            style: TextStyle(
                              color: AppColors.getTextMuted(context),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Invoice revenue',
                style: TextStyle(
                  color: AppColors.getTextMuted(context),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sales'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('View sales'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_MonthSales> get _lastSixMonthsSales {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final monthDate = DateTime(now.year, now.month - (5 - index), 1);
      final total = _invoices
          .where((invoice) {
            final date = _invoiceDate(invoice);
            return date != null &&
                date.year == monthDate.year &&
                date.month == monthDate.month;
          })
          .fold<double>(0, (sum, invoice) => sum + _invoiceAmount(invoice));
      return _MonthSales(
        label: _monthName(monthDate.month).substring(0, 3),
        value: total,
        isCurrent: monthDate.year == now.year && monthDate.month == now.month,
      );
    });
  }

  Widget _buildRecentInvoicesCard() {
    final invoices = _recentInvoices;
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _cardTitle('Recent invoices', 'Latest activity')),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/invoices'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (invoices.isEmpty)
            _emptyState(
              icon: Icons.receipt_long_outlined,
              title: _isLoadingData ? 'Loading invoices' : 'No invoices yet',
              subtitle: _isLoadingData
                  ? 'Your latest activity will appear here.'
                  : 'Create an invoice to see it here.',
            )
          else
            ...invoices.map(_invoiceRow),
        ],
      ),
    );
  }

  Widget _invoiceRow(Map<String, dynamic> invoice) {
    final invoiceNo = invoice['invoice_number']?.toString().trim();
    final customer = invoice['customer_name']?.toString().trim();
    final status = invoice['status']?.toString() ?? 'Pending';
    final statusLower = status.toLowerCase();
    final paid =
        statusLower == 'paid' ||
        statusLower == 'complete' ||
        statusLower == 'completed';
    final date = _invoiceDate(invoice);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?.isNotEmpty == true ? customer! : 'Unnamed customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${invoiceNo?.isNotEmpty == true ? invoiceNo : 'Invoice'}${date == null ? '' : '  ·  ${_formatDate(date)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency(_invoiceAmount(invoice)),
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              _StatusPill(label: status, positive: paid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard() {
    final items = _lowStockItems;
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardTitle(
                  'Stock watch',
                  'Products with five units or fewer',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/inventory'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Inventory'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            _emptyState(
              icon: Icons.inventory_2_outlined,
              title: _isLoadingData
                  ? 'Loading inventory'
                  : 'Stock is looking good',
              subtitle: _isLoadingData
                  ? 'Inventory details will appear here.'
                  : 'No active products are at the low stock threshold.',
            )
          else
            ...items.map(_stockRow),
        ],
      ),
    );
  }

  Widget _stockRow(Map<String, dynamic> item) {
    final quantity = _number(item['quantity']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: quantity == 0
                  ? AppColors.error.withValues(alpha: 0.09)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: quantity == 0 ? AppColors.error : AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name']?.toString() ?? 'Unnamed product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item['company']?.toString() ?? 'No brand',
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: quantity == 0
                  ? AppColors.error.withValues(alpha: 0.09)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              quantity == 0 ? 'Out of stock' : '$quantity left',
              style: TextStyle(
                color: quantity == 0 ? AppColors.error : AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(double width) {
    final columns = width >= 1000
        ? 4
        : width >= 520
        ? 2
        : 1;
    final actions = <_QuickActionData>[
      _QuickActionData(
        'New invoice',
        'Create a customer bill',
        Icons.add_card_rounded,
        AppColors.primary,
        '/add-invoice',
      ),
      _QuickActionData(
        'Add customer',
        'Grow your directory',
        Icons.person_add_alt_1_rounded,
        const Color(0xFF0E9F6E),
        '/add-customer',
      ),
      _QuickActionData(
        'Manage stock',
        'Review your products',
        Icons.inventory_2_outlined,
        const Color(0xFF6574CD),
        '/inventory',
      ),
      _QuickActionData(
        'View reminders',
        'Follow up on payments',
        Icons.alarm_rounded,
        const Color(0xFFDA8A00),
        '/reminders',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle('Quick actions', 'Common tasks, ready when you are'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 4
                ? 2.55
                : columns == 2
                ? 2.45
                : 3.6,
          ),
          itemBuilder: (context, index) =>
              _QuickActionCard(data: actions[index]),
        ),
      ],
    );
  }

  Widget _cardTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.getTextMuted(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 23),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.getScaffoldBg(context),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.getTextMuted(context), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _invoiceDate(Map<String, dynamic> invoice) {
    for (final key in const [
      'date',
      'invoice_date',
      'created_at',
      'createdAt',
    ]) {
      final value = invoice[key]?.toString().trim();
      if (value == null || value.isEmpty || value == 'N/A') continue;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
      final parts = value.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final first = int.tryParse(parts[0]);
        final second = int.tryParse(parts[1]);
        final third = int.tryParse(parts[2]);
        if (first != null && second != null && third != null) {
          if (first > 31) return DateTime(first, second, third);
          return DateTime(third, second, first);
        }
      }
    }
    return null;
  }

  double _invoiceAmount(Map<String, dynamic> invoice) {
    for (final key in const [
      'total',
      'grand_total',
      'total_amount',
      'amount',
    ]) {
      final value = invoice[key];
      if (value == null) continue;
      return _number(value);
    }
    return 0;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    final cleaned =
        value?.toString().replaceAll(',', '').replaceAll('₹', '').trim() ?? '';
    return double.tryParse(cleaned) ?? 0;
  }

  String _currency(double amount) => '₹${_formatIndianNumber(amount.round())}';

  String _formatIndianNumber(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return '${value < 0 ? '-' : ''}$digits';
    final lastThree = digits.substring(digits.length - 3);
    var leading = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (leading.length > 2) {
      groups.insert(0, leading.substring(leading.length - 2));
      leading = leading.substring(0, leading.length - 2);
    }
    groups.insert(0, leading);
    return '${value < 0 ? '-' : ''}${groups.join(',')},$lastThree';
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month).substring(0, 3)}';
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
}

class _MonthSales {
  const _MonthSales({
    required this.label,
    required this.value,
    required this.isCurrent,
  });
  final String label;
  final double value;
  final bool isCurrent;
}

class _QuickActionData {
  const _QuickActionData(
    this.title,
    this.subtitle,
    this.icon,
    this.tint,
    this.route,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final String route;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: metric.onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: metric.tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(metric.icon, color: metric.tint, size: 19),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.getTextMuted(context),
                size: 15,
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.getTextMuted(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getSurfaceCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});
  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: () => Navigator.pushNamed(context, data.route),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: data.tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 19, color: data.tint),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.getTextMuted(context),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials, this.size = 36});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials.isEmpty ? 'AD' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.positive});
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final foreground = positive ? AppColors.primary : AppColors.warning;
    final background = foreground.withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label.isEmpty ? 'Pending' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
