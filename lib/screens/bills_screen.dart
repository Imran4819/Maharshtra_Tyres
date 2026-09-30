import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maharashtra_tyres/services/bill_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await BillService.fetchBills();
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBills {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _bills;
    return _bills.where((bill) {
      final searchable = <String>[
        bill['store_name']?.toString() ?? '',
        bill['customer_name']?.toString() ?? '',
        bill['owner_details']?.toString() ?? '',
        bill['address']?.toString() ?? '',
        bill['date']?.toString() ?? '',
        bill['id']?.toString() ?? '',
        if (bill['items'] is List)
          ...(bill['items'] as List).map(
            (item) => item is Map ? item['product_name']?.toString() ?? '' : '',
          ),
      ];
      return searchable.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  int _quantity(Map<String, dynamic> bill) {
    final direct = _number(bill['quantity']).round();
    if (direct > 0) return direct;
    final items = bill['items'];
    if (items is! List) return 0;
    return items.fold<int>(
      0,
      (sum, item) =>
          sum + (item is Map ? _number(item['quantity']).round() : 0),
    );
  }

  int get _totalQuantity =>
      _bills.fold<int>(0, (sum, bill) => sum + _quantity(bill));

  int get _photosAddedToday {
    return _bills.where((bill) {
      final date = DateTime.tryParse(bill['date']?.toString() ?? '');
      return date != null && DateUtils.isSameDay(date, DateTime.now());
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getScaffoldBg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBill,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add bill',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryAccent,
                    onRefresh: _loadBills,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSummary(),
                              const SizedBox(height: 22),
                              _buildSearchField(),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Recent bill photos',
                                      style: TextStyle(
                                        color: AppColors.getTextPrimary(
                                          context,
                                        ),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_filteredBills.length} saved',
                                    style: TextStyle(
                                      color: AppColors.getTextMuted(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_loadError != null && _bills.isEmpty)
                                _buildLoadError()
                              else if (_filteredBills.isEmpty)
                                _buildEmptyState()
                              else
                                ..._filteredBills.map(_buildBillCard),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073822), Color(0xFF0F5132), Color(0xFF087F5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const AppSidebarButton(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Purchase bills',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Photos and manually entered bills',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildSummary() {
    final stats = [
      _BillStat(
        'Total bills',
        _bills.length.toString(),
        Icons.receipt_long_outlined,
      ),
      _BillStat(
        'Units billed',
        _formatIndianNumber(_totalQuantity),
        Icons.inventory_2_outlined,
      ),
      _BillStat(
        'Bills today',
        _photosAddedToday.toString(),
        Icons.today_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 2;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map(
                (stat) => SizedBox(width: cardWidth, child: _summaryCard(stat)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(_BillStat stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search store, customer or product',
        hintStyle: TextStyle(
          color: AppColors.getTextMuted(context),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.getTextMuted(context),
        ),
        filled: true,
        fillColor: AppColors.getSurfaceCard(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final quantity = _quantity(bill);
    final storeName = bill['store_name']?.toString().trim() ?? '';
    final customerName = bill['customer_name']?.toString().trim() ?? '';
    final date = bill['date']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showBillPreview(bill),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                if (_billHasImage(bill)) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: SizedBox(
                      width: 70,
                      height: 82,
                      child: _buildBillImage(bill, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 13),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              storeName.isEmpty ? 'Bill photo' : storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Bill options',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: AppColors.getTextMuted(context),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') _openEditBill(bill);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit bill'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (customerName.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          'Customer · $customerName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.getTextMuted(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _detailPill(
                            Icons.calendar_today_outlined,
                            _formatDate(date),
                          ),
                          if (quantity > 0)
                            _detailPill(
                              Icons.inventory_2_outlined,
                              '$quantity units',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchController.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            searching ? 'No bills found' : 'Your bill book starts here',
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            searching
                ? 'Try another store, customer or product name.'
                : 'Add a bill photo or enter a bill manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTextMuted(context),
              fontSize: 12,
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 17),
            OutlinedButton.icon(
              onPressed: _openAddBill,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Add first bill'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            'Could not load bills',
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _loadError ?? 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTextMuted(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadBills,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddBill() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Add a bill',
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to save it.',
                style: TextStyle(
                  color: AppColors.getTextMuted(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.add_a_photo_outlined),
                title: const Text('Add bill photo'),
                subtitle: const Text('Take a photo or choose from gallery'),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Enter bill manually'),
                subtitle: const Text('Store, customer and product details'),
                onTap: () => Navigator.pop(context, 'manual'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (method == null) return;

    bool? saved;
    if (method == 'photo') {
      saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: const _AddBillSheet(),
        ),
      );
    } else {
      saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: const _ManualBillSheet(),
        ),
      );
    }
    if (!mounted) return;
    if (saved == true) await _loadBills();
  }

  Future<void> _openEditBill(Map<String, dynamic> bill) async {
    final id = bill['id']?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This bill cannot be edited.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: _ManualBillSheet(initialBill: bill),
      ),
    );
    if (saved == true) await _loadBills();
  }

  Future<void> _showBillPreview(Map<String, dynamic> bill) async {
    final id = bill['id']?.toString() ?? '';
    final detailFuture = id.isEmpty
        ? Future<Map<String, dynamic>>.value(bill)
        : BillService.fetchBillById(id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
        return FutureBuilder<Map<String, dynamic>>(
          future: detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _billSheetContainer(
                context,
                maxHeight,
                const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _billSheetContainer(
                context,
                maxHeight,
                Center(
                  child: Text(
                    _errorMessage(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _buildBillDetails(context, snapshot.data ?? bill, maxHeight);
          },
        );
      },
    );
  }

  Widget _billSheetContainer(
    BuildContext context,
    double maxHeight,
    Widget child,
  ) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: child,
    );
  }

  Widget _buildBillDetails(
    BuildContext context,
    Map<String, dynamic> bill,
    double maxHeight,
  ) {
    final store = bill['store_name']?.toString().trim() ?? '';
    final items = bill['items'] is List ? bill['items'] as List : const [];
    return _billSheetContainer(
      context,
      maxHeight,
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.isEmpty ? 'Bill details' : store,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (_billHasImage(bill)) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: maxHeight * 0.42,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildBillImage(bill, fit: BoxFit.contain),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                if ((bill['date']?.toString() ?? '').isNotEmpty)
                  _detailPill(
                    Icons.calendar_today_outlined,
                    _formatDate(bill['date'].toString()),
                  ),
                if (_quantity(bill) > 0)
                  _detailPill(
                    Icons.inventory_2_outlined,
                    '${_quantity(bill)} units',
                  ),
              ],
            ),
            if ((bill['customer_name']?.toString() ?? '').isNotEmpty)
              _previewLine('Customer', bill['customer_name'].toString()),
            if ((bill['address']?.toString() ?? '').isNotEmpty)
              _previewLine('Address', bill['address'].toString()),
            if ((bill['owner_details']?.toString() ?? '').isNotEmpty)
              _previewLine('Owner details', bill['owner_details'].toString()),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Items',
                style: TextStyle(
                  color: AppColors.getTextMuted(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...items.whereType<Map>().map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['product_name']?.toString() ?? 'Product',
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '× ${item['quantity'] ?? 0}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.getTextMuted(context),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Uint8List? _photoBytes(Map<String, dynamic> bill) {
    final encoded = bill['photo_base64']?.toString();
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  String? _billImageUrl(Map<String, dynamic> bill) {
    dynamic imageValue = bill['image_url'] ?? bill['image'];
    if (imageValue is Map) {
      imageValue = imageValue['url'] ?? imageValue['path'];
    }
    final imagePath = imageValue?.toString().trim() ?? '';
    if (imagePath.isEmpty) return null;

    final parsed = Uri.tryParse(imagePath);
    return parsed?.hasScheme == true
        ? imagePath
        : Uri.parse(
            'https://business-management-ji66.onrender.com',
          ).resolve(imagePath).toString();
  }

  bool _billHasImage(Map<String, dynamic> bill) =>
      _photoBytes(bill) != null || _billImageUrl(bill) != null;

  Widget _buildBillImage(Map<String, dynamic> bill, {required BoxFit fit}) {
    final bytes = _photoBytes(bill);
    if (bytes != null) return Image.memory(bytes, fit: fit);

    final imageUrl = _billImageUrl(bill);
    if (imageUrl == null) return const SizedBox.shrink();
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

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

  String _formatDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}

class _AddBillSheet extends StatefulWidget {
  const _AddBillSheet();

  @override
  State<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<_AddBillSheet> {
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _photo;
  String _photoFileName = 'bill.jpg';
  bool _isPickingPhoto = false;
  bool _isSaving = false;

  bool get _cameraAvailable =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 11),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add bill photo',
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Take a photo or add one from your device',
                            style: TextStyle(
                              color: AppColors.getTextMuted(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPhotoSection(),
                          const SizedBox(height: 14),
                          Text(
                            "The photo will be saved with today's date.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.getTextMuted(context),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _photo == null || _isSaving
                                  ? null
                                  : _saveBill,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _isSaving
                                    ? 'Saving photo...'
                                    : 'Save bill photo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhoto = _photo != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_photo!, fit: BoxFit.cover),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: IconButton.filledTonal(
                          tooltip: 'Remove photo',
                          onPressed: () => setState(() => _photo = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Bill photo attached',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.55),
                      border: Border.all(color: AppColors.getBorder(context)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceCard(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your bill photo goes here',
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Take a new photo or choose an existing one',
                          style: TextStyle(
                            color: AppColors.getTextMuted(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            if (_cameraAvailable) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPickingPhoto
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 17),
                  label: const Text('Take photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.getBorder(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingPhoto
                    ? null
                    : () => _pickPhoto(ImageSource.gallery),
                icon: _isPickingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 17),
                label: Text(_isPickingPhoto ? 'Opening...' : 'Add photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.getBorder(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isPickingPhoto = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _photo = bytes;
          _photoFileName = image.name;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the camera or photo library.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _saveBill() async {
    final photo = _photo;
    if (photo == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await BillService.uploadBillPhoto(
        photoBytes: photo,
        fileName: _photoFileName,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _BillStat {
  const _BillStat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _ManualBillSheet extends StatefulWidget {
  const _ManualBillSheet({this.initialBill});

  final Map<String, dynamic>? initialBill;

  @override
  State<_ManualBillSheet> createState() => _ManualBillSheetState();
}

class _ManualBillSheetState extends State<_ManualBillSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_BillItemFields> _items = [];
  late final TextEditingController _storeController;
  late final TextEditingController _customerController;
  late final TextEditingController _addressController;
  late final TextEditingController _ownerController;
  late final TextEditingController _quantityController;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.initialBill != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.initialBill;
    final billItems = bill?['items'] is List
        ? bill!['items'] as List
        : const [];
    final itemQuantity = billItems.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item is Map
              ? int.tryParse(item['quantity']?.toString() ?? '') ?? 0
              : 0),
    );
    _storeController = TextEditingController(
      text: bill?['store_name']?.toString() ?? '',
    );
    _customerController = TextEditingController(
      text: bill?['customer_name']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: bill?['address']?.toString() ?? '',
    );
    _ownerController = TextEditingController(
      text: bill?['owner_details']?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: _isEditing
          ? (bill?['quantity']?.toString() ?? itemQuantity.toString())
          : '',
    );
    _date =
        DateTime.tryParse(bill?['date']?.toString() ?? '') ?? DateTime.now();
    if (!_isEditing) _items.add(_BillItemFields());
  }

  @override
  void dispose() {
    _storeController.dispose();
    _customerController.dispose();
    _addressController.dispose();
    _ownerController.dispose();
    _quantityController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 11),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_note_rounded
                              : Icons.receipt_long_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit bill' : 'Enter bill manually',
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Update the bill details'
                                  : 'Add store, customer and product details',
                              style: TextStyle(
                                color: AppColors.getTextMuted(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _field(
                              controller: _storeController,
                              label: 'Store name',
                              icon: Icons.storefront_outlined,
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _customerController,
                              label: 'Customer name',
                              icon: Icons.person_outline_rounded,
                              validator: _required,
                            ),
                            if (!_isEditing) ...[
                              const SizedBox(height: 12),
                              _dateField(),
                              const SizedBox(height: 12),
                              _field(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                maxLines: 2,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _field(
                              controller: _ownerController,
                              label: 'Owner details',
                              icon: Icons.badge_outlined,
                              validator: _required,
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 12),
                              _field(
                                controller: _quantityController,
                                label: 'Total quantity',
                                icon: Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                                validator: _positiveQuantity,
                              ),
                            ] else ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Products',
                                      style: TextStyle(
                                        color: AppColors.getTextPrimary(
                                          context,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Add item'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ..._items.asMap().entries.map(
                                (entry) => _itemFields(entry.key, entry.value),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSaving
                            ? 'Saving bill...'
                            : _isEditing
                            ? 'Update bill'
                            : 'Save bill',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.getScaffoldBg(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    final dateLabel =
        '${_date.year.toString().padLeft(4, '0')}-'
        '${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Bill date',
          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
          filled: true,
          fillColor: AppColors.getScaffoldBg(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.getBorder(context)),
          ),
        ),
        child: Text(
          dateLabel,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _itemFields(int index, _BillItemFields item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _field(
              controller: item.productController,
              label: 'Product name',
              icon: Icons.tire_repair_outlined,
              validator: _required,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _field(
              controller: item.quantityController,
              label: 'Qty',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              validator: _positiveQuantity,
            ),
          ),
          if (_items.length > 1)
            IconButton(
              tooltip: 'Remove item',
              onPressed: () {
                setState(() => _items.removeAt(index).dispose());
              },
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _positiveQuantity(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    return quantity == null || quantity <= 0 ? 'Enter a valid quantity' : null;
  }

  void _addItem() => setState(() => _items.add(_BillItemFields()));

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final id = widget.initialBill?['id']?.toString() ?? '';
        await BillService.updateBill(id, {
          'store_name': _storeController.text.trim(),
          'customer_name': _customerController.text.trim(),
          'quantity': int.parse(_quantityController.text.trim()),
          'owner_details': _ownerController.text.trim(),
        });
      } else {
        final payload = <String, dynamic>{
          'store_name': _storeController.text.trim(),
          'customer_name': _customerController.text.trim(),
          'date':
              '${_date.year.toString().padLeft(4, '0')}-'
              '${_date.month.toString().padLeft(2, '0')}-'
              '${_date.day.toString().padLeft(2, '0')}',
          'address': _addressController.text.trim(),
          'owner_details': _ownerController.text.trim(),
          'items': _items
              .map(
                (item) => {
                  'product_name': item.productController.text.trim(),
                  'quantity': int.parse(item.quantityController.text.trim()),
                },
              )
              .toList(),
        };
        await BillService.createBill(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _BillItemFields {
  final TextEditingController productController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    productController.dispose();
    quantityController.dispose();
  }
}
