import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/services/customer_service.dart';
import 'package:maharashtra_tyres/widgets/custom_snackbar.dart';

class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({super.key, this.customer});

  final Map<String, dynamic>? customer;

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

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
    FocusScope.of(context).unfocus();
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
      showAppSnackBar(
        context,
        _isEdit ? 'Customer details updated successfully!' : 'New customer registered successfully!',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } else {
      showAppSnackBar(
        context,
        'Failed to save customer. Please try again.',
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
                        _isEdit ? LanguageService.tr('update_customer') : LanguageService.tr('add_customer'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        _isEdit ? 'Update customer profile & contact details' : 'Add new customer to shop records',
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
                      children: [
                        // Avatar Badge
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F5132), Color(0xFF10B981)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                                      blurRadius: 18,
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
                                    color: _status == 'active' ? AppColors.success : AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    _status == 'active' ? Icons.check_rounded : Icons.close_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

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
                                          'Active',
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
                                          'Inactive',
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

                        // Details Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('full_name'),
                                  hintText: 'e.g. Ramesh Patil',
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('phone'),
                                  hintText: 'e.g. 9876543210',
                                  prefixIcon: const Icon(Icons.phone_android_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('email'),
                                  hintText: 'e.g. ramesh@example.com',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('city'),
                                  hintText: 'e.g. Pune / Mumbai / Nashik',
                                  prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: LanguageService.tr('address'),
                                  hintText: 'Full residential or business address',
                                  prefixIcon: const Icon(Icons.home_outlined, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveCustomer,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            label: Text(_isEdit ? LanguageService.tr('update_customer') : LanguageService.tr('add_customer')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
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
