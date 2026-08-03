import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/inventory_service.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key, this.item});

  final Map<String, dynamic>? item;

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _productNameController;
  late final TextEditingController _companyController;
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _dateController;

  String _status = 'active';
  bool _isSaving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.item?['product_name'] ?? '');
    _companyController = TextEditingController(text: widget.item?['company'] ?? '');
    _sizeController = TextEditingController(text: widget.item?['size'] ?? '');
    _quantityController = TextEditingController(text: widget.item?['quantity'] ?? '');
    _dateController = TextEditingController(text: widget.item?['date'] ?? '');
    _status = widget.item?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _companyController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Format to YYYY-MM-DD
        _dateController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success;
    if (_isEdit) {
      success = await InventoryService.updateInventoryItem(
        id: widget.item!['id'],
        productName: _productNameController.text.trim(),
        company: _companyController.text.trim(),
        size: _sizeController.text.trim(),
        quantity: _quantityController.text.trim(),
        date: _dateController.text.trim(),
        status: _status,
      );
    } else {
      success = await InventoryService.createInventoryItem(
        productName: _productNameController.text.trim(),
        company: _companyController.text.trim(),
        size: _sizeController.text.trim(),
        quantity: _quantityController.text.trim(),
        date: _dateController.text.trim(),
        status: _status,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Product ${_isEdit ? 'updated' : 'added'} successfully!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Failed to ${_isEdit ? 'update' : 'add'} product. Please try again.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 24),
                        _buildStatusToggle(),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Product Information',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryLight,
                          children: [
                            _buildField(
                              controller: _productNameController,
                              label: 'Product Name',
                              hint: 'e.g. Premium Layer Feed',
                              icon: Icons.label_important_outline_rounded,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Product name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _companyController,
                              label: 'Company/Brand',
                              hint: 'e.g. Supreme Feeds Ltd',
                              icon: Icons.business_outlined,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _sizeController,
                              label: 'Size/Dimensions',
                              hint: 'e.g. 50kg Bag',
                              icon: Icons.aspect_ratio_rounded,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _quantityController,
                              label: 'Quantity',
                              hint: 'e.g. 250',
                              icon: Icons.layers_outlined,
                              keyboardType: TextInputType.number,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildDateField(),
                          ],
                        ),
                        const SizedBox(height: 28),
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
                  _isEdit ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  _isEdit ? 'Update product details in stock' : 'Add new items to the inventory',
                  style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(_isEdit ? 'Edit' : 'Stock', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _productNameController.text.trim().isNotEmpty
                    ? _productNameController.text.trim().substring(0, 1).toUpperCase()
                    : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
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
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _status = 'active'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _status == 'active'
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: _status == 'active' ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Active',
                        style: TextStyle(
                            color: _status == 'active' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold)),
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
                  gradient: _status == 'inactive'
                      ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 18, color: _status == 'inactive' ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Inactive',
                        style: TextStyle(
                            color: _status == 'inactive' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isOptional = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.8),
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
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
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
          onTap: () => _selectDate(context),
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
              onPressed: () => _selectDate(context),
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

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveItem,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
      label: Text(_isEdit ? 'Update Product' : 'Save Product'),
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
