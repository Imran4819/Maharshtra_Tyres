import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/language_service.dart';
import 'package:maharashtra_tyres/services/reminder_notification_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/widgets/custom_snackbar.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Admin';
  String _userInitials = 'AD';
  String _userIdentifier = 'admin@maharashtratyres.com';
  bool _pushNotifications = false;
  bool _updatingPushNotifications = false;

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
    final notificationsEnabled =
        await ReminderNotificationService.instance.isEnabled();

    if (mounted) {
      setState(() {
        _userName = name;
        _userInitials = initials;
        _userIdentifier = identifier;
        _pushNotifications = notificationsEnabled;
      });
    }
  }

  Future<void> _setPushNotifications(bool enabled) async {
    setState(() => _updatingPushNotifications = true);
    final result =
        await ReminderNotificationService.instance.setEnabled(enabled);
    if (!mounted) return;

    setState(() {
      _pushNotifications = result;
      _updatingPushNotifications = false;
    });

    if (enabled && !result) {
      showAppSnackBar(
        context,
        'Allow notifications in your device or browser settings to receive alerts.',
        type: SnackBarType.info,
      );
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
          backgroundColor: AppColors.getScaffoldBg(context),
          drawer: const AppSidebarDrawer(),
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
                  style: const TextStyle(color: Color(0xFFE6F4EA), fontSize: 12),
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
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
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
                colors: [Color(0xFF073822), Color(0xFF0F5132)],
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userIdentifier,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
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
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
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
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                LanguageService.tr('language'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.getBorder(context), height: 1),
          const SizedBox(height: 14),

          // English option
          _buildLanguageOption(
            title: 'English',
            subtitle: 'Default system language',
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
          const SizedBox(height: 10),

          // Hindi option
          _buildLanguageOption(
            title: 'हिंदी (Hindi)',
            subtitle: 'राष्ट्रभाषा संवाद',
            code: 'hi',
            selected: currentLang == 'hi',
            flag: '🇮🇳',
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
          showAppSnackBar(
            context,
            code == 'mr'
                ? 'ॲपची भाषा मराठीत बदलली आहे.'
                : code == 'hi'
                    ? 'ऐप की भाषा हिंदी में बदल दी गई है।'
                    : 'App language changed to English.',
            type: SnackBarType.success,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.getScaffoldBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.getBorder(context),
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
                      color: selected ? AppColors.primary : AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // ─── APP PREFERENCES SECTION ───────────────────────────────────────────────
  Widget _buildAppPreferencesSection() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        final isDarkMode = currentMode == ThemeMode.dark;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(context)),
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
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'App Preferences',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(LanguageService.tr('dark_mode'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context))),
                subtitle: Text('Light / Dark green theme toggle', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                value: isDarkMode,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  AppTheme.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              Divider(height: 1, color: AppColors.getBorder(context)),
              SwitchListTile(
                title: Text(LanguageService.tr('notifications'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context))),
                subtitle: Text('Local alerts for stock and payment reminders', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                value: _pushNotifications,
                activeColor: AppColors.primary,
                onChanged: _updatingPushNotifications ? null : _setPushNotifications,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ABOUT SECTION ─────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            dense: true,
            leading: Icon(Icons.verified_outlined, size: 18, color: AppColors.getTextSecondary(context)),
            title: Text('App Version', style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(context))),
            trailing: Text('v2.0.0 (Dark Green Redesign)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(context))),
          ),
          Divider(height: 1, color: AppColors.getBorder(context)),
          ListTile(
            dense: true,
            leading: Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.getTextSecondary(context)),
            title: Text(LanguageService.tr('privacy_policy'), style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(context))),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.getTextSecondary(context)),
            onTap: () {},
          ),
          Divider(height: 1, color: AppColors.getBorder(context)),
          ListTile(
            dense: true,
            leading: Icon(Icons.support_agent_rounded, size: 18, color: AppColors.getTextSecondary(context)),
            title: Text(LanguageService.tr('help_support'), style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(context))),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.getTextSecondary(context)),
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
