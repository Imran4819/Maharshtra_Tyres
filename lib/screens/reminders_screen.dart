import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'dart:convert';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _reminders = [];
  final Set<String> _sendingReminderIds = {};
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Payment Due',
    'Stock Reorder',
    'Customer Service',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);

    // 1. Load saved local reminders
    List<Map<String, dynamic>> localReminders = [];
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_reminders_list');

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonStr);
        localReminders = List<Map<String, dynamic>>.from(decoded);
      } catch (_) {
        localReminders = _getDefaultReminders();
      }
    } else {
      localReminders = _getDefaultReminders();
    }

    // 2. Fetch real-time overdue bill reminders (>10 days) from API
    List<Map<String, dynamic>> apiReminders = [];
    try {
      final fetchedApi = await InvoiceService.fetchOverdueReminders(days: 10);
      apiReminders = fetchedApi.map((item) {
        final rawDate = item['due_date']?.toString() ?? '';
        final datePart = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;
        return {
          'id': item['id']?.toString() ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
          'invoice_id': item['id'],
          'title': item['title'] ?? 'Collect payment for ${item['invoice_number']} from ${item['customer_name']}',
          'category': 'Payment Due',
          'priority': item['priority'] != null
              ? (item['priority'].toString().contains('High') ? 'High' : 'Medium')
              : 'High',
          'due_date': datePart.isNotEmpty ? datePart : 'Overdue',
          'time': '05:00 PM',
          'completed': false,
          'notes': item['notes'] ?? 'Bill due > 10 days',
          'customer_phone': item['customer_phone'],
          'customer_email': item['customer_email'],
          'is_api': true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching API reminders: $e');
    }

    // 3. Merge API reminders with local reminders without duplication
    final existingIds = localReminders.map((r) => r['id']).toSet();
    final uniqueApiReminders = apiReminders.where((r) => !existingIds.contains(r['id'])).toList();

    _reminders = [...uniqueApiReminders, ...localReminders];
    await _saveReminders();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDefaultReminders() {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    return [
      {
        'id': 'rem_1',
        'title': 'Collect payment of ₹6,500 for INV-1003 from Amit Shinde',
        'category': 'Payment Due',
        'priority': 'High',
        'due_date': todayStr,
        'time': '05:00 PM',
        'completed': false,
        'notes': 'Call customer on +91 98765 43210',
      },
      {
        'id': 'rem_2',
        'title': 'Reorder MRF ZLX 165/80 R14 (Only 2 left in stock)',
        'category': 'Stock Reorder',
        'priority': 'High',
        'due_date': todayStr,
        'time': '06:30 PM',
        'completed': false,
        'notes': 'Contact MRF wholesaler manager',
      },
      {
        'id': 'rem_3',
        'title': 'Follow up for tyre alignment service with Rohan Patil',
        'category': 'Customer Service',
        'priority': 'Medium',
        'due_date': tomorrowStr,
        'time': '11:00 AM',
        'completed': false,
        'notes': 'Scheduled 1st free alignment check',
      },
      {
        'id': 'rem_4',
        'title': 'Send monthly GST sales report to accountant',
        'category': 'General',
        'priority': 'Normal',
        'due_date': tomorrowStr,
        'time': '02:00 PM',
        'completed': true,
        'notes': 'Export invoices PDF from dashboard',
      },
    ];
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_reminders_list', jsonEncode(_reminders));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReminders {
    return _reminders.where((rem) {
      final category = rem['category']?.toString() ?? 'General';
      final title = rem['title']?.toString().toLowerCase() ?? '';
      final notes = rem['notes']?.toString().toLowerCase() ?? '';

      final matchCategory = _selectedCategory == 'All' || category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          notes.contains(_searchQuery.toLowerCase());

      return matchCategory && matchSearch;
    }).toList();
  }

  int get _dueTodayCount {
    final todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    return _reminders.where((r) => r['due_date'] == todayStr && r['completed'] != true).length;
  }

  int get _pendingTotalCount => _reminders.where((r) => r['completed'] != true).length;
  int get _completedTotalCount => _reminders.where((r) => r['completed'] == true).length;

  Future<void> _toggleComplete(String id) async {
    setState(() {
      final idx = _reminders.indexWhere((r) => r['id'] == id);
      if (idx != -1) {
        _reminders[idx]['completed'] = !(_reminders[idx]['completed'] == true);
      }
    });
    await _saveReminders();
  }

  Future<void> _deleteReminder(String id) async {
    setState(() {
      _reminders.removeWhere((r) => r['id'] == id);
    });
    await _saveReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showAddReminderModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Payment Due';
    String priority = 'High';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateStr =
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Reminder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Title *',
                        hintText: 'e.g. Call customer for payment due',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _categories
                                .where((c) => c != 'All')
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => category = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            items: ['High', 'Medium', 'Normal']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => priority = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(dateStr, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setModalState(() => selectedTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Time',
                                prefixIcon: Icon(Icons.access_time_rounded),
                              ),
                              child: Text(selectedTime.format(context),
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Contact Info',
                        hintText: 'e.g. Contact phone number or specific instructions',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final newRem = {
                            'id': 'rem_${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleCtrl.text.trim(),
                            'category': category,
                            'priority': priority,
                            'due_date': dateStr,
                            'time': selectedTime.format(context),
                            'completed': false,
                            'notes': notesCtrl.text.trim(),
                          };
                          setState(() {
                            _reminders.insert(0, newRem);
                          });
                          await _saveReminders();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                        label: const Text(
                          'Save Reminder',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddReminderModal(context),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text(
          'Add Reminder',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    onRefresh: _loadReminders,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricsGrid(),
                          const SizedBox(height: 20),
                          _buildSearchAndFilters(),
                          const SizedBox(height: 16),
                          _buildRemindersList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
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
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Payment due dates, stock alerts & follow-ups',
                  style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadReminders,
          ),
        ],
      ),
    );
  }

  // ─── METRICS GRID ──────────────────────────────────────────────────────────
  Widget _buildMetricsGrid() {
    final stats = [
      _RemStat('Due Today', '$_dueTodayCount', Icons.today_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
      _RemStat('Total Pending', '$_pendingTotalCount', Icons.pending_actions_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
      _RemStat('Completed', '$_completedTotalCount', Icons.task_alt_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _RemStat('All Tasks', '${_reminders.length}', Icons.format_list_bulleted_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 560 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: cols == 4 ? 1.6 : 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: stats.map((s) => _buildStatCard(s)).toList(),
      );
    });
  }

  Widget _buildStatCard(_RemStat s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: s.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search reminders by title or notes...',
              hintStyle:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 18),
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
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSel ? Colors.transparent : AppColors.border,
                    ),
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── REMINDERS LIST ────────────────────────────────────────────────────────
  Widget _buildRemindersList() {
    final list = _filteredReminders;

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
                child: const Icon(Icons.alarm_on_rounded,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                'No reminders found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a new reminder to stay organized.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
          child: Text(
            'Reminders (${list.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _buildReminderCard(list[i]),
        ),
      ],
    );
  }

  Future<void> _sendReminder(String remId, String? invoiceId, String? phone, String title) async {
    final targetId = invoiceId ?? remId;
    if (_sendingReminderIds.contains(targetId)) return;

    setState(() {
      _sendingReminderIds.add(targetId);
    });

    final res = await InvoiceService.sendPaymentReminder(targetId);

    if (mounted) {
      setState(() {
        _sendingReminderIds.remove(targetId);
      });

      final isSuccess = res['success'] == true;
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Reminder sent successfully.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        // SMS Fallback if API returns 500 or is unhandled
        final rawPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
        bool launched = false;
        if (rawPhone.isNotEmpty) {
          final bodyText = Uri.encodeComponent('Payment Reminder: $title. Kindly settle the bill at Maharashtra Tyres.');
          final smsUri = Uri.parse('sms:$rawPhone?body=$bodyText');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
            launched = true;
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(launched
                ? 'Opening SMS app to send payment reminder...'
                : (res['message']?.toString() ?? 'Reminder notification sent.')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showReminderDetail(BuildContext context, Map<String, dynamic> rem) {
    final isDone = rem['completed'] == true;
    final priority = rem['priority']?.toString() ?? 'Normal';
    final category = rem['category']?.toString() ?? 'General';
    final remId = rem['id']?.toString() ?? '';
    final invoiceId = rem['invoice_id']?.toString();
    final phone = rem['customer_phone']?.toString();
    final email = rem['customer_email']?.toString();
    final targetId = invoiceId ?? remId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isSending = _sendingReminderIds.contains(targetId);

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: category == 'Payment Due'
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: category == 'Payment Due'
                                ? const Color(0xFFDC2626)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$priority Priority',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    rem['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (rem['notes'] != null && rem['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      rem['notes'].toString(),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            const Text('Due Date: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('${rem['due_date']} ${rem['time'] ?? ''}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Text('Phone: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                        if (email != null && email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Text('Email: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (category == 'Payment Due' || (phone != null && phone.isNotEmpty)) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSending
                                ? null
                                : () async {
                                    setSheetState(() {});
                                    await _sendReminder(remId, invoiceId, phone, rem['title'] ?? '');
                                    if (ctx.mounted) setSheetState(() {});
                                  },
                            icon: isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              isSending ? 'Sending...' : 'Send Reminder',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDone ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _toggleComplete(remId);
                          Navigator.pop(ctx);
                        },
                        icon: Icon(
                          isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                          color: isDone ? const Color(0xFFD97706) : const Color(0xFF059669),
                        ),
                        tooltip: isDone ? 'Mark Pending' : 'Mark Completed',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _deleteReminder(remId);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        tooltip: 'Delete Reminder',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> rem) {
    final isDone = rem['completed'] == true;
    final priority = rem['priority']?.toString() ?? 'Normal';
    final category = rem['category']?.toString() ?? 'General';

    final Color priorityColor = priority == 'High'
        ? const Color(0xFFDC2626)
        : priority == 'Medium'
            ? const Color(0xFFD97706)
            : const Color(0xFF2563EB);

    final Color categoryBg = category == 'Payment Due'
        ? const Color(0xFFFEF2F2)
        : category == 'Stock Reorder'
            ? const Color(0xFFFEF3C7)
            : category == 'Customer Service'
                ? const Color(0xFFECFDF5)
                : const Color(0xFFEFF6FF);

    final Color categoryColor = category == 'Payment Due'
        ? const Color(0xFFDC2626)
        : category == 'Stock Reorder'
            ? const Color(0xFFD97706)
            : category == 'Customer Service'
                ? const Color(0xFF059669)
                : const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.border.withValues(alpha: 0.6) : AppColors.border,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showReminderDetail(context, rem),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isDone,
                  activeColor: AppColors.success,
                  onChanged: (_) => _toggleComplete(rem['id']),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$priority Priority',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rem['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (rem['notes'] != null && rem['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rem['notes'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${rem['due_date']} ${rem['time'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemStat {
  const _RemStat(this.title, this.value, this.icon, this.color, this.bgColor);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
}
