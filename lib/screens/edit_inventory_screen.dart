import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/services/inventory_service.dart';
import 'package:maharashtra_tyres/widgets/custom_snackbar.dart';

class EditInventoryScreen extends StatefulWidget {
  const EditInventoryScreen({super.key, this.item});

  final Map<String, dynamic>? item;

  @override
  State<EditInventoryScreen> createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  String _status = 'active';
  bool _isSaving = false;

  bool get _isEdit => widget.item != null;

  final List<String> _popularBrands = ['MRF', 'CEAT', 'Apollo', 'JK Tyre', 'Bridgestone', 'Goodyear', 'Michelin'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?['product_name'] ?? '');
    _companyController = TextEditingController(text: widget.item?['company'] ?? '');
    _sizeController = TextEditingController(text: widget.item?['size'] ?? '');
    _quantityController = TextEditingController(text: widget.item?['quantity']?.toString() ?? '1');
    _priceController = TextEditingController(text: widget.item?['price']?.toString() ?? '0');
    _status = widget.item?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    bool success;
    if (_isEdit) {
      success = await InventoryService.updateInventoryItem(
        id: widget.item!['id'],
        productName: _nameController.text.trim(),
        company: _companyController.text.trim(),
        size: _sizeController.text.trim(),
        quantity: _quantityController.text.trim(),
        status: _status,
      );
    } else {
      success = await InventoryService.createInventoryItem(
        productName: _nameController.text.trim(),
        company: _companyController.text.trim(),
        size: _sizeController.text.trim(),
        quantity: _quantityController.text.trim(),
        status: _status,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      showAppSnackBar(
        context,
        _isEdit ? 'Product stock updated successfully!' : 'New product added to inventory!',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } else {
      showAppSnackBar(
        context,
        'Failed to save product. Please try again.',
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
                        _isEdit ? LanguageService.tr('update_product') : LanguageService.tr('add_product'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        _isEdit ? 'Edit inventory item details & stock count' : 'Add new tyre model or accessory',
                        style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size.width < 600 ? double.infinity : 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _status = 'active'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _status == 'active' ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded,
                                            size: 18, color: _status == 'active' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                        const SizedBox(width: 8),
                                        Text(
                                          LanguageService.tr('active_stock'),
                                          style: TextStyle(
                                            color: _status == 'active' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _status = 'inactive'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _status == 'inactive' ? AppColors.error : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cancel_outlined,
                                            size: 18, color: _status == 'inactive' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                        const SizedBox(width: 8),
                                        Text(
                                          LanguageService.tr('inactive_stock'),
                                          style: TextStyle(
                                            color: _status == 'inactive' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
                        const SizedBox(height: 20),

                        // Form Inputs Card
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
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('product_name'),
                                  hintText: 'e.g. ZVTS 175/65 R14',
                                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Quick Brand Chips
                              Text(
                                LanguageService.tr('brand'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _popularBrands.map((b) {
                                  final selected = _companyController.text.trim().toLowerCase() == b.toLowerCase();
                                  return ChoiceChip(
                                    label: Text(b),
                                    selected: selected,
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: selected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _companyController.text = b);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _companyController,
                                decoration: InputDecoration(
                                  labelText: 'Brand / Manufacturer',
                                  hintText: 'e.g. MRF, CEAT, Apollo',
                                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Brand is required' : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sizeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Size / Spec',
                                        hintText: 'e.g. 175/65 R14',
                                        prefixIcon: Icon(Icons.aspect_ratio_rounded, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.tr('quantity'),
                                        hintText: 'e.g. 10',
                                        prefixIcon: const Icon(Icons.layers_outlined, size: 20),
                                      ),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'Qty is required' : null,
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
                            onPressed: _isSaving ? null : _saveProduct,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            label: Text(_isEdit ? LanguageService.tr('update_product') : LanguageService.tr('add_product')),
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
}
