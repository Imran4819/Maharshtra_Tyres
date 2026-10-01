import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/services/pdf_helper.dart';
import 'package:maharashtra_tyres/screens/add_invoice_screen.dart';
import 'package:maharashtra_tyres/widgets/custom_snackbar.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;

  final List<String> _filters = ['All', 'Paid', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final list = await InvoiceService.fetchInvoices();
    if (mounted) {
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _invoices.where((inv) {
      final status = inv['status']?.toString().toLowerCase() ?? 'pending';
      final customerName = inv['customer_name']?.toString().toLowerCase() ?? '';
      final invoiceNum = inv['invoice_number']?.toString().toLowerCase() ?? '';

      final matchFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Paid' && status == 'paid') ||
          (_selectedFilter == 'Pending' && status == 'pending') ||
          (_selectedFilter == 'Cancelled' && status == 'cancelled');

      final matchSearch = _searchQuery.isEmpty ||
          invoiceNum.contains(_searchQuery.toLowerCase()) ||
          customerName.contains(_searchQuery.toLowerCase());

      return matchFilter && matchSearch;
    }).toList();
  }

  double get _totalRevenue {
    double sum = 0.0;
    for (final inv in _invoices) {
      if (inv['status']?.toString().toLowerCase() == 'paid') {
        sum += double.tryParse(inv['total']?.toString() ?? '0.0') ?? 0.0;
      }
    }
    return sum;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                _loadInvoices();
              }
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(LanguageService.tr('create_invoice'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStats(),
                              const SizedBox(height: 20),
                              _buildSearchFilter(),
                              const SizedBox(height: 16),
                              _buildList(),
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

  Widget _buildTopBar(BuildContext context) => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 14,
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
                  Text(LanguageService.tr('invoices'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(LanguageService.tr('all_invoices'), style: const TextStyle(color: Color(0xFFE6F4EA), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStats() {
    final paidCount = _invoices.where((i) => i['status']?.toString().toLowerCase() == 'paid').length;
    final pendingCount = _invoices.where((i) => i['status']?.toString().toLowerCase() == 'pending').length;

    final stats = [
      _Stat('Total Invoices', '${_invoices.length}', Icons.receipt_long_rounded, AppColors.primary, AppColors.primaryLight),
      _Stat('Paid', '$paidCount', Icons.check_circle_outline_rounded, const Color(0xFF10B981), const Color(0xFF10B981).withValues(alpha: 0.15)),
      _Stat('Pending', '$pendingCount', Icons.hourglass_top_rounded, const Color(0xFFF59E0B), const Color(0xFFF59E0B).withValues(alpha: 0.15)),
      _Stat('Revenue', '₹${(_totalRevenue / 1000).toStringAsFixed(1)}K', Icons.currency_rupee_rounded, AppColors.accent, AppColors.accent.withValues(alpha: 0.15)),
    ];

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 500 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Keep enough vertical room for the icon, value, and label on narrow screens.
        childAspectRatio: 1.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: stats.map((s) => _statCard(s)).toList(),
      );
    });
  }

  Widget _statCard(_Stat s) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: s.bgColor, borderRadius: BorderRadius.circular(9)),
              child: Icon(s.icon, color: s.iconColor, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: s.iconColor)),
                Text(s.label, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );

  Widget _buildSearchFilter() => Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.getSurfaceCard(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by invoice no. or customer...',
                hintStyle: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.7), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(context), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context), size: 18),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) {
                final sel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? const LinearGradient(colors: [Color(0xFF0F5132), Color(0xFF10B981)]) : null,
                        color: sel ? null : AppColors.getSurfaceCard(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? Colors.transparent : AppColors.getBorder(context)),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) return _emptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${list.length} invoice${list.length == 1 ? '' : 's'} found',
            style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context), fontWeight: FontWeight.w500),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _invoiceCard(list[i]),
        ),
      ],
    );
  }

  Widget _invoiceCard(Map<String, dynamic> inv) {
    final status = inv['status']?.toString().toLowerCase() ?? 'pending';
    final Color statusColor = status == 'paid'
        ? const Color(0xFF059669)
        : status == 'pending'
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    final Color statusBg = status == 'paid'
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : status == 'pending'
            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
            : const Color(0xFFEF4444).withValues(alpha: 0.15);

    final String initials = inv['customer_name'] != null && inv['customer_name'].toString().isNotEmpty
        ? inv['customer_name'].toString().substring(0, 1).toUpperCase()
        : 'C';

    final double totalAmount = double.tryParse(inv['total']?.toString() ?? '0.0') ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetail(context, inv),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF073822), Color(0xFF0F5132)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              inv['invoice_number'] ?? 'INV',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inv['customer_name'] ?? 'Unnamed Customer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(context)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.getTextSecondary(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (inv['due_date'] != null && inv['due_date'].toString().trim().isNotEmpty)
                                  ? inv['due_date'].toString().split('T').first
                                  : 'No Due Date',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(context))),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.getTextSecondary(context), size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text('No invoices found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(context))),
              const SizedBox(height: 6),
              Text('Try adjusting your search or filters', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context))),
            ],
          ),
        ),
      );

  void _showDetail(BuildContext context, Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InvoiceDetailSheet(
        invoice: inv,
        onRefreshNeeded: _loadInvoices,
      ),
    );
  }
}

class _InvoiceDetailSheet extends StatefulWidget {
  const _InvoiceDetailSheet({required this.invoice, required this.onRefreshNeeded});

  final Map<String, dynamic> invoice;
  final VoidCallback onRefreshNeeded;

  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  bool _isMarkingPaid = false;
  bool _isDeleting = false;
  bool _isPdfDownloading = false;
  bool _isPdfSharing = false;

  Future<void> _sharePdfFile(BuildContext context) async {
    setState(() => _isPdfSharing = true);

    final lang = LanguageService.currentLanguage.value;
    final bytes = await InvoiceService.fetchInvoicePdfBytes(widget.invoice['id'], lang: lang);

    if (!mounted) return;
    setState(() => _isPdfSharing = false);

    if (bytes != null && bytes.isNotEmpty) {
      final filename = '${widget.invoice['invoice_number'] ?? 'invoice'}.pdf';
      final customerName = widget.invoice['customer_name'] ?? 'Customer';
      final invoiceNum = widget.invoice['invoice_number'] ?? 'Invoice';
      final phone = widget.invoice['customer_phone']?.toString() ?? '';
      
      if (phone.trim().isNotEmpty) {
        final cleanPhone = _formatPhoneNumber(phone);
        await Clipboard.setData(ClipboardData(text: cleanPhone));
      }

      await sharePdf(
        bytes,
        filename,
        text: 'Invoice $invoiceNum for $customerName${phone.trim().isNotEmpty ? ' (${_formatPhoneNumber(phone)})' : ''}',
      );
    } else {
      showAppSnackBar(
        context,
        'Failed to fetch invoice PDF for sharing.',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final phone = widget.invoice['customer_phone']?.toString() ?? '';
    
    if (phone.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Customer phone number is required to share via WhatsApp.',
        type: SnackBarType.error,
      );
      return;
    }

    final cleanPhone = _formatPhoneNumber(phone);
    await Clipboard.setData(ClipboardData(text: cleanPhone));

    final customerName = widget.invoice['customer_name'] ?? 'Customer';
    final invoiceNum = widget.invoice['invoice_number'] ?? 'Invoice';
    final total = widget.invoice['total'] ?? '0.00';
    final rawDueDate = widget.invoice['due_date']?.toString().trim();
    final hasDueDate = rawDueDate != null && rawDueDate.isNotEmpty && rawDueDate != 'N/A';

    final message = 'Hello $customerName,\n\n'
        'Your invoice *$invoiceNum* is ready.\n'
        'Total Amount: *₹$total*\n'
        '${hasDueDate ? 'Due Date: *$rawDueDate*\n' : ''}\n'
        'Thank you for your business!\n'
        'Maharashtra Tyres';

    setState(() => _isPdfSharing = true);
    final lang = LanguageService.currentLanguage.value;
    final bytes = await InvoiceService.fetchInvoicePdfBytes(widget.invoice['id'], lang: lang);
    if (!mounted) return;
    setState(() => _isPdfSharing = false);

    if (bytes != null && bytes.isNotEmpty) {
      final filename = '${widget.invoice['invoice_number'] ?? 'invoice'}.pdf';
      showAppSnackBar(
        context,
        'Sharing PDF for $cleanPhone (Phone copied to clipboard)',
        type: SnackBarType.success,
      );
      await sharePdf(bytes, filename, text: message);
    } else {
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          showAppSnackBar(
            context,
            'Could not launch WhatsApp.',
            type: SnackBarType.error,
          );
        }
      } catch (e) {
        showAppSnackBar(
          context,
          'Error launching WhatsApp: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (clean.length == 10) {
      clean = '91$clean';
    }
    return clean;
  }

  Future<void> _markAsPaid(BuildContext context) async {
    final navigator = Navigator.of(context);
    setState(() => _isMarkingPaid = true);

    final payload = Map<String, dynamic>.from(widget.invoice);
    payload['status'] = 'paid';

    final result = await InvoiceService.updateInvoice(widget.invoice['id'], payload);

    if (!mounted) return;
    setState(() => _isMarkingPaid = false);

    if (result['success'] == true) {
      showAppSnackBar(
        context,
        'Invoice marked as paid successfully!',
        type: SnackBarType.success,
      );
      widget.onRefreshNeeded();
      navigator.pop();
    } else {
      showAppSnackBar(
        context,
        result['message'] ?? 'Failed to update invoice status.',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceCard(context),
        title: Text('Delete Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context))),
        content: Text('Are you sure you want to delete ${widget.invoice['invoice_number']}? This action cannot be undone.', style: TextStyle(color: AppColors.getTextSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.getTextSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final success = await InvoiceService.deleteInvoice(widget.invoice['id']);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      showAppSnackBar(
        context,
        'Invoice deleted successfully.',
        type: SnackBarType.success,
      );
      widget.onRefreshNeeded();
      navigator.pop();
    } else {
      showAppSnackBar(
        context,
        'Failed to delete invoice. Please try again.',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    setState(() => _isPdfDownloading = true);
    try {
      final lang = LanguageService.currentLanguage.value;
      final bytes = await InvoiceService.fetchInvoicePdfBytes(
        widget.invoice['id'],
        lang: lang,
      );

      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        showAppSnackBar(
          context,
          'The server did not return a valid invoice PDF.',
          type: SnackBarType.error,
        );
        return;
      }

      final filename = '${widget.invoice['invoice_number'] ?? 'invoice'}.pdf';
      final saved = await saveAndOpenPdf(bytes, filename);
      if (!mounted) return;
      showAppSnackBar(
        context,
        saved
            ? 'PDF saved to Downloads or opened in a PDF app.'
            : 'Could not save or open the PDF on this device.',
        type: saved ? SnackBarType.success : SnackBarType.error,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Failed to generate PDF. Please try again.',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.invoice['status']?.toString().toLowerCase() ?? 'pending';
    final bool isPending = status == 'pending';
    final String initials = widget.invoice['customer_name'] != null && widget.invoice['customer_name'].toString().isNotEmpty
        ? widget.invoice['customer_name'].toString().substring(0, 1).toUpperCase()
        : 'C';

    final double totalAmount = double.tryParse(widget.invoice['total']?.toString() ?? '0.0') ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.getBorder(context), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          
          // Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF073822), Color(0xFF0F5132), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.invoice['invoice_number'] ?? 'INV',
                          style: const TextStyle(color: Color(0xFFE6F4EA), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(widget.invoice['customer_name'] ?? 'Unnamed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _sheetRow(Icons.phone_outlined, 'Customer Phone', widget.invoice['customer_phone'] ?? 'N/A'),
                _sheetRow(Icons.email_outlined, 'Customer Email', widget.invoice['customer_email'] ?? 'N/A'),
                if (widget.invoice['due_date'] != null &&
                    widget.invoice['due_date'].toString().trim().isNotEmpty &&
                    widget.invoice['due_date'].toString().trim() != 'N/A')
                  _sheetRow(
                    Icons.calendar_today_outlined,
                    'Due Date',
                    widget.invoice['due_date'].toString(),
                  ),
                if (double.tryParse(widget.invoice['labour_charge']?.toString() ?? widget.invoice['labor_charge']?.toString() ?? '0') != null &&
                    (double.tryParse(widget.invoice['labour_charge']?.toString() ?? widget.invoice['labor_charge']?.toString() ?? '0') ?? 0) > 0)
                  _sheetRow(
                    Icons.engineering_outlined,
                    'Labour Charge',
                    '₹${(double.tryParse(widget.invoice['labour_charge']?.toString() ?? widget.invoice['labor_charge']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                  ),
                _sheetRow(Icons.info_outline_rounded, 'Status', status.toUpperCase()),
                _sheetRow(Icons.notes_rounded, 'Notes', widget.invoice['notes'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close bottom sheet
                          final result = await Navigator.pushNamed(
                            context,
                            '/edit-invoice',
                            arguments: widget.invoice,
                          );
                          if (result == true) {
                            widget.onRefreshNeeded();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPdfDownloading ? null : () => _downloadPdf(context),
                        icon: _isPdfDownloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
                        label: const Text('Create PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (isPending) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isMarkingPaid ? null : () => _markAsPaid(context),
                          icon: _isMarkingPaid
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                          label: const Text('Mark Paid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : () => _deleteInvoice(context),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPdfSharing ? null : () => _sharePdfFile(context),
                        icon: _isPdfSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                        label: const Text('Share PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareOnWhatsApp(context),
                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13)),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.iconColor, this.bgColor);
  final String label, value;
  final IconData icon;
  final Color iconColor, bgColor;
}
