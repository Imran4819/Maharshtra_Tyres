import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';
import 'package:maharashtra_tyres/widgets/custom_snackbar.dart';

class EditInvoiceScreen extends StatefulWidget {
  const EditInvoiceScreen({super.key, this.invoice});

  final Map<String, dynamic>? invoice;

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  String _customerName = '';
  String _customerPhone = '';
  String _status = 'pending';
  String _dueDate = '';
  double _taxPercent = 18.0;
  double _discountAmount = 0.0;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _availableCustomers = [];

  bool _isLoadingData = false;
  bool _isSaving = false;

  bool get _isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    final customers = await CustomerService.fetchCustomers();
    if (widget.invoice != null) {
      _selectedCustomerId = widget.invoice!['customer_id']?.toString();
      _customerName = widget.invoice!['customer_name']?.toString() ?? '';
      _customerPhone = widget.invoice!['customer_phone']?.toString() ?? '';
      _status = widget.invoice!['status']?.toString().toLowerCase() ?? 'pending';
      _dueDate = widget.invoice!['due_date']?.toString() ?? '';
      _taxPercent = double.tryParse(widget.invoice!['tax']?.toString() ?? '18.0') ?? 18.0;
      _discountAmount = double.tryParse(widget.invoice!['discount']?.toString() ?? '0.0') ?? 0.0;

      if (widget.invoice!['items'] is List) {
        _items = List<Map<String, dynamic>>.from(
          (widget.invoice!['items'] as List).map((x) => Map<String, dynamic>.from(x)),
        );
      }
    }

    if (_items.isEmpty) {
      _items = [
        {'description': '175/65 R14 Tyre', 'quantity': 2, 'price': 3500.0, 'amount': 7000.0}
      ];
    }

    if (mounted) {
      setState(() {
        _availableCustomers = customers;
        _isLoadingData = false;
      });
    }
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      sum += qty * price;
    }
    return sum;
  }

  double get _taxAmount => (_subtotal * _taxPercent) / 100;
  double get _grandTotal => (_subtotal + _taxAmount) - _discountAmount;

  void _addItem() {
    setState(() {
      _items.add({'description': '', 'quantity': 1, 'price': 0.0, 'amount': 0.0});
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index));
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    final payload = {
      if (_isEdit) 'id': widget.invoice!['id'],
      'customer_id': _selectedCustomerId,
      'customer_name': _customerName,
      'customer_phone': _customerPhone,
      'status': _status,
      'due_date': _dueDate.isNotEmpty ? _dueDate : DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10),
      'items': _items,
      'subtotal': _subtotal,
      'tax': _taxPercent,
      'discount': _discountAmount,
      'total': _grandTotal,
    };

    final result = _isEdit
        ? await InvoiceService.updateInvoice(widget.invoice!['id'], payload)
        : await InvoiceService.createInvoice(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      showAppSnackBar(
        context,
        _isEdit ? 'Invoice updated successfully!' : 'New invoice created successfully!',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } else {
      showAppSnackBar(
        context,
        result['message'] ?? 'Failed to save invoice.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      drawer: const AppSidebarDrawer(),
      body: Column(
        children: [
          // Header Banner
          Container(
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const AppSidebarButton(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? LanguageService.tr('update_invoice') : LanguageService.tr('create_invoice'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        _isEdit ? 'Modify billing items, tax, or payment status' : 'Generate new customer bill & receipt',
                        style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: size.width < 700 ? double.infinity : 680),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Customer & Status Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LanguageService.tr('customer_details'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCustomerId,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.tr('customer_name'),
                                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                      ),
                                      items: _availableCustomers.map((c) {
                                        return DropdownMenuItem<String>(
                                          value: c['id']?.toString(),
                                          child: Text('${c['name']} (${c['phone']})'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        final matched = _availableCustomers.firstWhere(
                                          (c) => c['id']?.toString() == val,
                                          orElse: () => {},
                                        );
                                        setState(() {
                                          _selectedCustomerId = val;
                                          _customerName = matched['name']?.toString() ?? '';
                                          _customerPhone = matched['phone']?.toString() ?? '';
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                LanguageService.tr('status'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              SegmentedButton<String>(
                                                segments: const [
                                                  ButtonSegment(value: 'paid', label: Text('Paid')),
                                                  ButtonSegment(value: 'pending', label: Text('Pending')),
                                                ],
                                                selected: {_status},
                                                onSelectionChanged: (set) => setState(() => _status = set.first),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Items Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          LanguageService.tr('invoice_items'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: _addItem,
                                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                          label: const Text('Add Item'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...List.generate(_items.length, (index) {
                                      final item = _items[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.bgDark : AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: TextFormField(
                                                  initialValue: item['description']?.toString() ?? '',
                                                  decoration: const InputDecoration(hintText: 'Item / Tyre Model'),
                                                  onChanged: (v) => item['description'] = v,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  initialValue: item['quantity']?.toString() ?? '1',
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(hintText: 'Qty'),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      item['quantity'] = double.tryParse(v) ?? 1;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 3,
                                                child: TextFormField(
                                                  initialValue: item['price']?.toString() ?? '0',
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(hintText: 'Price (₹)'),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      item['price'] = double.tryParse(v) ?? 0;
                                                    });
                                                  },
                                                ),
                                              ),
                                              if (_items.length > 1)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                                  onPressed: () => _removeItem(index),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Calculation Summary Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                                child: Column(
                                  children: [
                                    _summaryRow(LanguageService.tr('subtotal'), '₹${_subtotal.toStringAsFixed(2)}'),
                                    const SizedBox(height: 10),
                                    _summaryRow('GST Tax (18%)', '₹${_taxAmount.toStringAsFixed(2)}'),
                                    const SizedBox(height: 10),
                                    _summaryRow(LanguageService.tr('discount'), '- ₹${_discountAmount.toStringAsFixed(2)}'),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          LanguageService.tr('total'),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          '₹${_grandTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Action Buttons
                              SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveInvoice,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                        )
                                      : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  label: Text(_isEdit ? LanguageService.tr('update_invoice') : LanguageService.tr('generate_invoice')),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(LanguageService.tr('cancel')),
                                ),
                              ),
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

  Widget _summaryRow(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ],
    );
  }
}
