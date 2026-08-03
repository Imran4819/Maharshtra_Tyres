import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, this.customer});

  final Map<String, dynamic>? customer;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  String _status = 'active';
  bool _isSaving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.customer?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.customer?['email'] ?? '');
    _addressController = TextEditingController(text: widget.customer?['address'] ?? '');
    _cityController = TextEditingController(text: widget.customer?['city'] ?? '');
    _status = widget.customer?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success;
    if (_isEdit) {
      success = await CustomerService.updateCustomer(
        id: widget.customer!['id'],
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        status: _status,
      );
    } else {
      success = await CustomerService.createCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
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
                'Customer ${_isEdit ? 'updated' : 'added'} successfully!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context, true); // Return true to notify parent list to reload
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
                'Failed to ${_isEdit ? 'update' : 'add'} customer. Please try again.',
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
                          title: 'Customer Details',
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryLight,
                          children: [
                            _buildField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'e.g. Jane Doe',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'e.g. +1987655321',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'e.g. jane.doe@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isOptional: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _addressController,
                              label: 'Street Address',
                              hint: 'e.g. 123 Main St',
                              icon: Icons.home_outlined,
                              isOptional: true,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'e.g. Metropolis',
                              icon: Icons.location_city_outlined,
                              isOptional: true,
                            ),
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
                  _isEdit ? 'Edit Customer' : 'Add Customer',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  _isEdit ? 'Update the details of the customer' : 'Register a new customer',
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
                const Icon(Icons.people_alt_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(_isEdit ? 'Edit' : 'Customer', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                _nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim().substring(0, 1).toUpperCase()
                    : 'C',
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

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveCustomer,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
      label: Text(_isEdit ? 'Update Customer' : 'Save Customer'),
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
