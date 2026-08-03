import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Admin';
  String _userInitials = 'AD';
  String _userIdentifier = 'admin@maharashtratyres.com';
  bool _darkMode = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserDisplayName();
    final initials = await AuthService.getUserInitials();
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('logged_user_identifier') ??
        prefs.getString('saved_identifier') ??
        'admin@maharashtratyres.com';

    if (mounted) {
      setState(() {
        _userName = name;
        _userInitials = initials;
        _userIdentifier = identifier;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, currentLang, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildLanguageSection(currentLang),
                          const SizedBox(height: 20),
                          _buildAppPreferencesSection(),
                          const SizedBox(height: 20),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
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
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr('settings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '${LanguageService.tr('select_language')} & Preferences',
                  style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── USER PROFILE CARD ─────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userIdentifier,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LANGUAGE SELECTION SECTION ───────────────────────────────────────────
  Widget _buildLanguageSection(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                LanguageService.tr('language'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // English option
          _buildLanguageOption(
            title: 'English',
            subtitle: 'Default language',
            code: 'en',
            selected: currentLang == 'en',
            flag: '🇬🇧',
          ),
          const SizedBox(height: 10),

          // Marathi option
          _buildLanguageOption(
            title: 'मराठी (Marathi)',
            subtitle: 'महाराष्ट्राची प्रादेशिक भाषा',
            code: 'mr',
            selected: currentLang == 'mr',
            flag: '🚩',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String code,
    required bool selected,
    required String flag,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await LanguageService.setLanguage(code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                code == 'mr'
                    ? 'ॲपची भाषा मराठीत बदलली आहे.'
                    : 'App language changed to English.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── APP PREFERENCES SECTION ───────────────────────────────────────────────
  Widget _buildAppPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'App Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(LanguageService.tr('dark_mode'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: const Text('Light / Dark theme toggle', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: _darkMode,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            title: Text(LanguageService.tr('notifications'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: const Text('Push alerts for stock & payment due dates', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: _pushNotifications,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
        ],
      ),
    );
  }

  // ─── ABOUT SECTION ─────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                LanguageService.tr('app_title'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ListTile(
            dense: true,
            leading: Icon(Icons.verified_outlined, size: 18, color: AppColors.textSecondary),
            title: Text('App Version', style: TextStyle(fontSize: 13)),
            trailing: Text('v1.0.0+1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            dense: true,
            leading: const Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.textSecondary),
            title: Text(LanguageService.tr('privacy_policy'), style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            onTap: () {},
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            dense: true,
            leading: const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.textSecondary),
            title: Text(LanguageService.tr('help_support'), style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── LOGOUT BUTTON ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        label: Text(
          LanguageService.tr('logout'),
          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
