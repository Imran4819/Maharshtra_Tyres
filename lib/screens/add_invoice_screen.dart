import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/invoice_service.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';
import 'package:maharashtra_tyres/services/inventory_service.dart';
import 'package:maharashtra_tyres/screens/add_inventory_screen.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key, this.invoice});

  final Map<String, dynamic>? invoice;

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerEmailController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _vehicleNoController;
  late final TextEditingController _dateController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _taxController;
  late final TextEditingController _discountController;
  late final TextEditingController _notesController;

  String _status = 'pending';
  bool _isSaving = false;
  bool _isManualCustomer = false;

  // Customers lookup state
  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = false;
  String _customerSearchQuery = '';

  // Inventory lookup state
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoadingInventory = false;
  String _inventorySearchQuery = '';

  // Invoice Items List
  final List<Map<String, dynamic>> _items = [];

  // Parallel list controllers for dynamically editing items in ListView
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _brandControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];

  bool get _isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final defaultInvoiceNum = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    
    _invoiceNumberController = TextEditingController(text: widget.invoice?['invoice_number'] ?? defaultInvoiceNum);
    _customerNameController = TextEditingController(text: widget.invoice?['customer_name'] ?? '');
    _customerEmailController = TextEditingController(text: widget.invoice?['customer_email'] ?? '');
    _customerPhoneController = TextEditingController(text: widget.invoice?['customer_phone'] ?? '');
    _customerAddressController = TextEditingController(text: widget.invoice?['customer_address'] ?? '');
    _vehicleNoController = TextEditingController(text: widget.invoice?['vehicle_no'] ?? '');
    
    final today = DateTime.now();
    final todayStr = "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    _dateController = TextEditingController(text: widget.invoice?['date'] ?? todayStr);

    // Default due date to 30 days from now if not editing
    final defaultDueDate = DateTime.now().add(const Duration(days: 30));
    final defaultDueDateStr = "${defaultDueDate.year.toString().padLeft(4, '0')}-${defaultDueDate.month.toString().padLeft(2, '0')}-${defaultDueDate.day.toString().padLeft(2, '0')}";
    _dueDateController = TextEditingController(text: widget.invoice?['due_date'] ?? defaultDueDateStr);
    
    _taxController = TextEditingController(text: widget.invoice?['tax']?.toString() ?? '0.0');
    _discountController = TextEditingController(text: widget.invoice?['discount']?.toString() ?? '0.0');
    _notesController = TextEditingController(text: widget.invoice?['notes'] ?? 'Thank you for your business!');
    _status = widget.invoice?['status'] ?? 'pending';

    // Load items if editing
    if (widget.invoice?['items'] != null) {
      final List parsedItems = widget.invoice?['items'] is String 
          ? List.from(jsonDecode(widget.invoice?['items']))
          : List.from(widget.invoice?['items']);
      for (final item in parsedItems) {
        final desc = item['description'] ?? '';
        final brand = item['brand'] ?? '-';
        final qty = item['quantity'] ?? 1;
        final price = item['price'] ?? 0.0;
        _items.add({
          'description': desc,
          'brand': brand,
          'quantity': qty,
          'price': price,
        });
        _descriptionControllers.add(TextEditingController(text: desc));
        _brandControllers.add(TextEditingController(text: brand));
        _quantityControllers.add(TextEditingController(text: qty.toString()));
        _priceControllers.add(TextEditingController(text: price.toString()));
      }
    } else {
      // Add one default item to start with
      _items.add({'description': 'MRF ZLX 165/80 R14', 'brand': 'MRF', 'quantity': 1, 'price': 4500.0});
      _descriptionControllers.add(TextEditingController(text: 'MRF ZLX 165/80 R14'));
      _brandControllers.add(TextEditingController(text: 'MRF'));
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '4500.0'));
    }

    _loadCustomers();
    _loadInventory();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    final list = await CustomerService.fetchCustomers();
    if (mounted) {
      setState(() {
        _customers = list;
        _isLoadingCustomers = false;
      });
    }
  }

  void _matchInvoiceItemsWithInventory() {
    if (_inventoryItems.isEmpty || _items.isEmpty) return;
    setState(() {
      for (var item in _items) {
        final desc = (item['description'] ?? '').toString().trim().toLowerCase();
        final brand = (item['brand'] ?? '').toString().trim().toLowerCase();
        
        for (final inv in _inventoryItems) {
          final pName = (inv['product_name'] ?? '').toString().trim().toLowerCase();
          final size = (inv['size'] ?? '').toString().trim().toLowerCase();
          final company = (inv['company'] ?? '').toString().trim().toLowerCase();
          
          final expectedDesc = size.isNotEmpty ? '$pName ($size)' : pName;
          
          if (desc == expectedDesc && brand == company) {
            item['inventory_id'] = inv['id'];
            item['available_stock'] = double.tryParse(inv['quantity'].toString()) ?? 0.0;
            item['original_quantity'] = double.tryParse(item['quantity'].toString()) ?? 0.0;
            break;
          }
        }
      }
    });
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoadingInventory = true);
    final list = await InventoryService.fetchInventory();
    if (mounted) {
      setState(() {
        _inventoryItems = list;
        _isLoadingInventory = false;
      });
      _matchInvoiceItemsWithInventory();
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _customerNameController.text = customer['name'] ?? '';
      _customerPhoneController.text = customer['phone'] ?? '';
      _customerEmailController.text = customer['email'] ?? '';
      _customerAddressController.text = customer['address'] ?? '';
      // Support vehicle_no if it exists on customer object, otherwise empty string
      _vehicleNoController.text = customer['vehicle_no'] ?? customer['vehicle'] ?? '';
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _vehicleNoController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    for (final c in _brandControllers) {
      c.dispose();
    }
    for (final c in _quantityControllers) {
      c.dispose();
    }
    for (final c in _priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _subtotal {
    double sum = 0.0;
    for (final item in _items) {
      final qty = double.tryParse(item['quantity'].toString()) ?? 0.0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      sum += qty * price;
    }
    return sum;
  }

  double get _tax => double.tryParse(_taxController.text) ?? 0.0;
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _total => _subtotal + _tax - _discount;

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDateController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _customers.where((c) {
              final name = c['name']?.toString().toLowerCase() ?? '';
              final phone = c['phone']?.toString().toLowerCase() ?? '';
              final query = _customerSearchQuery.toLowerCase();
              return name.contains(query) || phone.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Customer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        setModalState(() {
                          _customerSearchQuery = v;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingCustomers
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No customers found.'),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.pushNamed(
                                          context,
                                          '/add-customer',
                                        );
                                        if (result == true) {
                                          await _loadCustomers();
                                          setModalState(() {});
                                        }
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add Customer'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(color: AppColors.border),
                                itemBuilder: (context, idx) {
                                  final customer = filtered[idx];
                                  return ListTile(
                                    title: Text(
                                      customer['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    subtitle: Text(customer['phone'] ?? 'No phone'),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        _selectCustomer(customer);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    onTap: () {
                                      _selectCustomer(customer);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectInventoryItem(int itemIndex, Map<String, dynamic> inventoryItem) {
    setState(() {
      final name = inventoryItem['product_name'] ?? '';
      final brand = inventoryItem['company'] ?? '-';
      final size = inventoryItem['size'] ?? '';
      final description = size.isNotEmpty ? '$name ($size)' : name;

      double price = 0.0;
      if (inventoryItem.containsKey('price') && inventoryItem['price'] != null) {
        price = double.tryParse(inventoryItem['price'].toString()) ?? 0.0;
      }

      final stock = double.tryParse(inventoryItem['quantity']?.toString() ?? '0') ?? 0.0;
      final invId = inventoryItem['id'];

      if (itemIndex == -1) {
        // Append a new item row to the invoice
        _items.add({
          'description': description,
          'brand': brand,
          'quantity': 1.0,
          'price': price,
          'inventory_id': invId,
          'available_stock': stock,
          'original_quantity': 0.0,
        });
        _descriptionControllers.add(TextEditingController(text: description));
        _brandControllers.add(TextEditingController(text: brand));
        _quantityControllers.add(TextEditingController(text: '1'));
        _priceControllers.add(TextEditingController(text: price.toString()));
      } else {
        // Update the existing item row
        _descriptionControllers[itemIndex].text = description;
        _brandControllers[itemIndex].text = brand;
        
        _items[itemIndex]['description'] = description;
        _items[itemIndex]['brand'] = brand;

        _priceControllers[itemIndex].text = price.toString();
        _items[itemIndex]['price'] = price;
        _items[itemIndex]['inventory_id'] = invId;
        _items[itemIndex]['available_stock'] = stock;
      }
    });
  }

  void _showInventorySelector(BuildContext context, int itemIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _inventoryItems.where((item) {
              final name = item['product_name']?.toString().toLowerCase() ?? '';
              final brand = item['company']?.toString().toLowerCase() ?? '';
              final query = _inventorySearchQuery.toLowerCase();
              return name.contains(query) || brand.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Product',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
                        label: const Text('Custom Item'),
                        onPressed: () {
                          Navigator.pop(context);
                          _addBlankItem();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        setModalState(() {
                          _inventorySearchQuery = v;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by product name or brand...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingInventory
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No products found in inventory.'),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _addBlankItem();
                                          },
                                          icon: const Icon(Icons.edit_note_rounded),
                                          label: const Text('Add Custom Item'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.textSecondary,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
                                            );
                                            if (result == true) {
                                              await _loadInventory();
                                              setModalState(() {});
                                            }
                                          },
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Add Product to Inventory'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(color: AppColors.border),
                                itemBuilder: (context, idx) {
                                  final product = filtered[idx];
                                  final sizeStr = product['size']?.toString() ?? '';
                                  final qtyStr = product['quantity']?.toString() ?? '0';
                                  return ListTile(
                                    title: Text(
                                      product['product_name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    subtitle: Text(
                                      'Brand: ${product['company'] ?? 'N/A'} | Size: ${sizeStr.isNotEmpty ? sizeStr : 'N/A'}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Stock: $qtyStr',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            _selectInventoryItem(itemIndex, product);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _selectInventoryItem(itemIndex, product);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addBlankItem() {
    setState(() {
      _items.add({'description': '', 'brand': '-', 'quantity': 1, 'price': 0.0});
      _descriptionControllers.add(TextEditingController(text: ''));
      _brandControllers.add(TextEditingController(text: '-'));
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0.0'));
    });
  }

  void _addItem() {
    _showInventorySelector(context, -1);
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _descriptionControllers[index].dispose();
        _brandControllers[index].dispose();
        _quantityControllers[index].dispose();
        _priceControllers[index].dispose();
        
        _descriptionControllers.removeAt(index);
        _brandControllers.removeAt(index);
        _quantityControllers.removeAt(index);
        _priceControllers.removeAt(index);
        
        _items.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required in the invoice.')),
      );
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Auto-create a new customer if manually entered and not already existing
    if (_isManualCustomer) {
      final nameText = _customerNameController.text.trim();
      final phoneText = _customerPhoneController.text.trim();
      final emailText = _customerEmailController.text.trim();
      final addressText = _customerAddressController.text.trim();

      if (nameText.isNotEmpty) {
        final nameLower = nameText.toLowerCase();
        final exists = _customers.any((c) {
          final cName = (c['name'] ?? '').toString().toLowerCase().trim();
          final cPhone = (c['phone'] ?? '').toString().trim();
          return cName == nameLower || (phoneText.isNotEmpty && cPhone == phoneText);
        });

        if (!exists) {
          try {
            await CustomerService.createCustomer(
              name: nameText,
              phone: phoneText.isEmpty ? null : phoneText,
              email: emailText.isEmpty ? null : emailText,
              address: addressText.isEmpty ? null : addressText,
              status: 'active',
            );
          } catch (_) {
            // Non-blocking catch to allow invoice creation even if customer API fails
          }
        }
      }
    }

    final payload = {
      'invoice_number': _invoiceNumberController.text.trim(),
      'customer_name': _customerNameController.text.trim(),
      'customer_phone': _customerPhoneController.text.trim(),
      'customer_email': _customerEmailController.text.trim().isEmpty ? null : _customerEmailController.text.trim(),
      'customer_address': _customerAddressController.text.trim(),
      'vehicle_no': _vehicleNoController.text.trim(),
      'date': _dateController.text.trim(),
      'due_date': _dueDateController.text.trim(),
      'status': _status,
      'items': _items.map((item) => {
        'description': item['description']?.toString().trim() ?? '',
        'brand': item['brand']?.toString().trim() ?? '-',
        'quantity': double.tryParse(item['quantity'].toString()) ?? 1.0,
        'price': double.tryParse(item['price'].toString()) ?? 0.0,
        if (item['inventory_id'] != null) 'inventory_id': item['inventory_id'],
      }).toList(),
      'subtotal': _subtotal,
      'tax': _tax,
      'discount': _discount,
      'total': _total,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    Map<String, dynamic> result;
    if (_isEdit) {
      result = await InvoiceService.updateInvoice(widget.invoice!['id'], payload);
    } else {
      result = await InvoiceService.createInvoice(payload);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Invoice ${_isEdit ? 'updated' : 'generated'} successfully!'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(result['message'] ?? 'Failed to ${_isEdit ? 'update' : 'create'} invoice.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width < 600 ? double.infinity : 600,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusToggle(),
                        const SizedBox(height: 20),
                        
                        // Basic Details Card
                        _buildSectionCard(
                          title: 'Invoice Details',
                          icon: Icons.receipt_long_outlined,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryLight,
                          children: [
                            _buildField(
                              controller: _invoiceNumberController,
                              label: 'Invoice Number',
                              hint: 'e.g. INV-00125',
                              icon: Icons.tag,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Invoice number is required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildInvoiceDateField(),
                            const SizedBox(height: 16),
                            _buildDateField(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.person_add_rounded, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'New Customer / Enter Manually',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _isManualCustomer,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) {
                                    setState(() {
                                      _isManualCustomer = v;
                                      _customerNameController.clear();
                                      _customerPhoneController.clear();
                                      _customerEmailController.clear();
                                      _customerAddressController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _customerNameController,
                              label: 'Customer Name',
                              hint: _isManualCustomer ? 'Enter customer name...' : 'Select Customer...',
                              icon: Icons.person_outline_rounded,
                              readOnly: !_isManualCustomer,
                              onTap: _isManualCustomer ? null : () => _showCustomerSelector(context),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Customer name is required' : null,
                              suffixIcon: _isManualCustomer 
                                  ? null 
                                  : const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _customerPhoneController,
                              label: 'Customer Phone',
                              hint: 'e.g. 9898787987',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _customerEmailController,
                              label: 'Customer Email',
                              hint: 'e.g. billing@acme.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _customerAddressController,
                              label: 'Customer Address',
                              hint: 'e.g. Ahmedabad, Gujarat',
                              icon: Icons.location_on_outlined,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _vehicleNoController,
                              label: 'Vehicle Number',
                              hint: 'e.g. GJ01AB1234',
                              icon: Icons.directions_car_filled_rounded,
                              isOptional: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Items Card
                        _buildSectionCard(
                          title: 'Invoice Items',
                          icon: Icons.shopping_bag_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBg: const Color(0xFFF5F3FF),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: AppColors.border),
                              ),
                              itemBuilder: (context, index) => _buildItemRow(index),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Item'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Financial Summary Card
                        _buildSectionCard(
                          title: 'Financial Summary',
                          icon: Icons.currency_rupee_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFECFDF5),
                          children: [
                            _buildSummaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _taxController,
                              label: 'Tax (₹)',
                              hint: '0.00',
                              icon: Icons.receipt_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _discountController,
                              label: 'Discount (₹)',
                              hint: '0.00',
                              icon: Icons.money_off_csred_rounded,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const Divider(height: 32, thickness: 1.5, color: AppColors.border),
                            _buildSummaryRow(
                              'Grand Total',
                              '₹${_total.toStringAsFixed(2)}',
                              isBold: true,
                              textColor: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Additional Notes Card
                        _buildSectionCard(
                          title: 'Notes',
                          icon: Icons.note_alt_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFEF3C7),
                          children: [
                            _buildField(
                              controller: _notesController,
                              label: 'Invoice Notes',
                              hint: 'Thank you for your business!',
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Save Actions
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _isSaving ? _buildLoadingButton() : _buildSaveButton(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Invoice' : 'Create Invoice',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  _isEdit ? 'Update details of this invoice' : 'Generate a new invoice for client',
                  style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _statusOption('pending', const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])),
          _statusOption('paid', const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])),
          _statusOption('cancelled', const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])),
        ],
      ),
    );
  }

  Widget _statusOption(String value, Gradient selGradient) {
    final bool selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? selGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Column(
      key: ObjectKey(item),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _descriptionControllers[index],
          readOnly: true,
          onTap: () => _showInventorySelector(context, index),
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Select Product...',
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
            suffixIconConstraints: BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _brandControllers[index],
                onTap: () {
                  _brandControllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _brandControllers[index].text.length,
                  );
                },
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g. MRF',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) => item['brand'] = v,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _quantityControllers[index],
                onTap: () {
                  _quantityControllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _quantityControllers[index].text.length,
                  );
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Req';
                  final qty = double.tryParse(v);
                  if (qty == null || qty <= 0) return 'Invalid';
                  final invId = item['inventory_id'];
                  if (invId != null) {
                    final availableStock = double.tryParse(item['available_stock']?.toString() ?? '0') ?? 0.0;
                    final originalQty = double.tryParse(item['original_quantity']?.toString() ?? '0') ?? 0.0;
                    final maxAllowed = availableStock + originalQty;
                    if (qty > maxAllowed) {
                      return 'Max ${maxAllowed.toStringAsFixed(0)}';
                    }
                  }
                  return null;
                },
                onChanged: (v) {
                  setState(() {
                    item['quantity'] = double.tryParse(v) ?? 1.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceControllers[index],
                onTap: () {
                  _priceControllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _priceControllers[index].text.length,
                  );
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) {
                  setState(() {
                    item['price'] = double.tryParse(v) ?? 0.0;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isOptional = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            if (isOptional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: const Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap ?? () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
              child: const Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dueDateController,
          readOnly: true,
          onTap: () => _selectDueDate(context),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.date_range_rounded, color: AppColors.primary),
              onPressed: () => _selectDueDate(context),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Invoice Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
              child: const Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: () => _selectInvoiceDate(context),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.date_range_rounded, color: AppColors.primary),
              onPressed: () => _selectInvoiceDate(context),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: AppColors.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveInvoice,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
      label: Text(_isEdit ? 'Update Invoice' : 'Save Invoice'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        ),
      ),
    );
  }
}
