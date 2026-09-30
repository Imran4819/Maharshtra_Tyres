import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/screens/add_invoice_screen.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedPeriod = 'This Month';

  final List<String> _statusFilters = ['All', 'Paid', 'Pending', 'Cancelled'];
  final List<String> _periodFilters = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final list = await InvoiceService.fetchInvoices();
    if (mounted) {
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate stats based on fetched invoices
  double get _totalRevenue {
    double sum = 0.0;
    for (final inv in _invoices) {
      if (inv['status']?.toString().toLowerCase() == 'paid') {
        sum += double.tryParse(inv['total']?.toString() ?? '0.0') ?? 0.0;
      }
    }
    return sum;
  }

  double get _pendingRevenue {
    double sum = 0.0;
    for (final inv in _invoices) {
      if (inv['status']?.toString().toLowerCase() == 'pending') {
        sum += double.tryParse(inv['total']?.toString() ?? '0.0') ?? 0.0;
      }
    }
    return sum;
  }

  int get _paidCount =>
      _invoices.where((i) => i['status']?.toString().toLowerCase() == 'paid').length;

  int get _pendingCount =>
      _invoices.where((i) => i['status']?.toString().toLowerCase() == 'pending').length;

  double get _avgOrderValue =>
      _invoices.isNotEmpty ? _totalRevenue / (_paidCount > 0 ? _paidCount : 1) : 0.0;

  List<Map<String, dynamic>> get _filteredSales {
    return _invoices.where((inv) {
      final status = inv['status']?.toString().toLowerCase() ?? 'pending';
      final customerName = inv['customer_name']?.toString().toLowerCase() ?? '';
      final invoiceNum = inv['invoice_number']?.toString().toLowerCase() ?? '';

      final matchStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Paid' && status == 'paid') ||
          (_selectedStatus == 'Pending' && status == 'pending') ||
          (_selectedStatus == 'Cancelled' && status == 'cancelled');

      final matchSearch = _searchQuery.isEmpty ||
          invoiceNum.contains(_searchQuery.toLowerCase()) ||
          customerName.contains(_searchQuery.toLowerCase());

      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, currentLang, child) {
        return Scaffold(
          backgroundColor: AppColors.getScaffoldBg(context),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddInvoiceScreen()),
              );
              if (result == true) {
                _loadSales();
              }
            },
            icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
            label: Text(
              LanguageService.tr('new_sale'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSales,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPeriodSelector(),
                              const SizedBox(height: 16),
                              _buildSalesMetricsGrid(),
                              const SizedBox(height: 20),
                              _buildCategoryDistributionCard(),
                              const SizedBox(height: 20),
                              _buildSearchAndFilters(),
                              const SizedBox(height: 16),
                              _buildRecentSalesList(),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TOP HEADER ────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 8,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073822), Color(0xFF0F5132)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const AppSidebarButton(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr('sales_dashboard'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  LanguageService.tr('sales'),
                  style: const TextStyle(color: Color(0xFFE6F4EA), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PERIOD SELECTOR ────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _periodFilters.map((p) {
          final isSelected = _selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0F5132), Color(0xFF10B981)],
                        )
                      : null,
                  color: isSelected ? null : AppColors.getSurfaceCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.getBorder(context),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── METRICS GRID ──────────────────────────────────────────────────────────
  Widget _buildSalesMetricsGrid() {
    final metrics = [
      _MetricData(
        title: 'Total Revenue',
        value: '₹${_totalRevenue.toStringAsFixed(0)}',
        icon: Icons.currency_rupee_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFF10B981).withValues(alpha: 0.15),
        trend: '+14.2% vs last month',
      ),
      _MetricData(
        title: 'Total Sales',
        value: '${_invoices.length}',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.primary,
        bgColor: AppColors.primaryLight,
        trend: '$_paidCount Paid / $_pendingCount Pending',
      ),
      _MetricData(
        title: 'Avg Order Value',
        value: '₹${_avgOrderValue.toStringAsFixed(0)}',
        icon: Icons.analytics_outlined,
        iconColor: AppColors.accent,
        bgColor: AppColors.accent.withValues(alpha: 0.15),
        trend: 'Per transaction',
      ),
      _MetricData(
        title: 'Pending Amount',
        value: '₹${_pendingRevenue.toStringAsFixed(0)}',
        icon: Icons.pending_actions_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        trend: '$_pendingCount Unpaid Invoices',
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 720 ? 4 : 2;
      const crossAxisSpacing = 12.0;
      const cardHeight = 148.0;
      final cardWidth =
          (constraints.maxWidth - crossAxisSpacing * (cols - 1)) / cols;
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: crossAxisSpacing,
        // Derive the ratio from a fixed height so wrapped labels fit on phones.
        childAspectRatio: cardWidth / cardHeight,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: metrics.map((m) => _buildMetricCard(m)).toList(),
      );
    });
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: m.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.iconColor, size: 20),
              ),
              Icon(Icons.arrow_upward_rounded,
                  size: 14, color: m.iconColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.trend,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: m.iconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY DISTRIBUTION CARD ──────────────────────────────────────────
  Widget _buildCategoryDistributionCard() {
    final categories = [
      _CategoryProgress('Truck & Bus Tyres', 0.45, '₹82,500', const Color(0xFF0F5132)),
      _CategoryProgress('Car & SUV Tyres', 0.30, '₹55,200', const Color(0xFF10B981)),
      _CategoryProgress('Two-Wheeler Tyres', 0.15, '₹27,600', const Color(0xFFF59E0B)),
      _CategoryProgress('Tubes & Accessories', 0.10, '₹19,200', AppColors.accent),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Sales Distribution',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              Icon(Icons.pie_chart_outline_rounded,
                  size: 18, color: AppColors.getTextSecondary(context)),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          cat.amount,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cat.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cat.percent,
                        minHeight: 6,
                        backgroundColor: AppColors.getBorder(context).withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── SEARCH & FILTERS ──────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceCard(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search sales by invoice or customer...',
              hintStyle:
                  TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.7), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.getTextSecondary(context), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppColors.getTextSecondary(context), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _statusFilters.map((st) {
              final isSel = _selectedStatus == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    st,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : AppColors.getTextSecondary(context),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.getSurfaceCard(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSel ? Colors.transparent : AppColors.getBorder(context),
                    ),
                  ),
                  onSelected: (_) => setState(() => _selectedStatus = st),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── RECENT SALES LIST ─────────────────────────────────────────────────────
  Widget _buildRecentSalesList() {
    final list = _filteredSales;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'No sales transactions found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try creating a new sale or adjusting your filters.',
                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Transactions (${list.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              Text(
                'Filter: $_selectedStatus',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _buildSaleItemCard(list[i]),
        ),
      ],
    );
  }

  Widget _buildSaleItemCard(Map<String, dynamic> sale) {
    final status = sale['status']?.toString().toLowerCase() ?? 'pending';
    final isPaid = status == 'paid';
    final isPending = status == 'pending';

    final statusColor = isPaid
        ? const Color(0xFF059669)
        : isPending
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    final statusBg = isPaid
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : isPending
            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
            : const Color(0xFFEF4444).withValues(alpha: 0.15);

    final customerName = sale['customer_name']?.toString() ?? 'Walk-in Customer';
    final invoiceNo = sale['invoice_number']?.toString() ?? 'INV';
    final totalAmount =
        double.tryParse(sale['total']?.toString() ?? '0.0') ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPaid
                ? Icons.check_circle_rounded
                : isPending
                    ? Icons.schedule_rounded
                    : Icons.cancel_rounded,
            color: statusColor,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              invoiceNo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$customerName • ${sale['created_at'] ?? sale['due_date'] ?? 'Recent'}',
            style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(context)),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.getTextSecondary(context)),
          ],
        ),
        onTap: () {
          _showSaleQuickDetail(sale);
        },
      ),
    );
  }

  void _showSaleQuickDetail(Map<String, dynamic> sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurfaceCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale['invoice_number'] ?? 'Sale Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Divider(color: AppColors.getBorder(context)),
            const SizedBox(height: 8),
            _detailRow('Customer', sale['customer_name'] ?? 'N/A'),
            _detailRow('Phone', sale['customer_phone'] ?? 'N/A'),
            _detailRow('Total Amount', '₹${sale['total'] ?? '0.00'}'),
            _detailRow('Status', (sale['status'] ?? 'PENDING').toString().toUpperCase()),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final phone = sale['customer_phone']?.toString() ?? '';
                      if (phone.isNotEmpty) {
                        final clean = phone.replaceAll(RegExp(r'\D'), '');
                        final msg = Uri.encodeComponent(
                          'Invoice ${sale['invoice_number']} of ₹${sale['total']} is ${sale['status']}. Thank you!',
                        );
                        launchUrl(Uri.parse('https://wa.me/$clean?text=$msg'),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/invoices');
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('All Invoices'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                  fontSize: 13)),
        ],
      ),
    );
  }
}


class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.trend,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String trend;
}

class _CategoryProgress {
  const _CategoryProgress(this.name, this.percent, this.amount, this.color);
  final String name;
  final double percent;
  final String amount;
  final Color color;
}
