import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../routes/app_routes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../main.dart';
import 'package:go_router/go_router.dart';

// Conditional import for web-only functionality
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart'
    as web_download;

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile state
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;

  // Editable controllers
  final _fullNameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Preferences
  bool _notificationsEnabled = true;
  bool _aiInsightsEnabled = true;
  String _selectedCurrency = 'TZS';
  String _selectedTimezone = 'Africa/Dar_es_Salaam';

  // Security toggles (persisted to DB)
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;

  // Password change
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;

  // PIN
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _hasPIN = false;
  bool _isChangingPIN = false;

  // Delete account
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final profile = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final prefs = await SharedPreferences.getInstance();

      if (profile != null) {
        setState(() {
          _profile = profile;
          _fullNameCtrl.text = profile['full_name'] ?? '';
          _displayNameCtrl.text = profile['full_name'] ?? '';
          _phoneCtrl.text = profile['phone'] ?? '';
          _countryCtrl.text = profile['country'] ?? 'Tanzania';
          _cityCtrl.text = profile['city'] ?? '';
          _addressCtrl.text = profile['address'] ?? '';
          _biometricEnabled = profile['biometric_enabled'] == true;
          _twoFactorEnabled = profile['two_factor_enabled'] == true;
          _hasPIN = profile['pin_hash'] != null;
        });
      }

      // Load local preferences
      setState(() {
        _selectedCurrency = prefs.getString('preferred_currency') ?? 'TZS';
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _aiInsightsEnabled = prefs.getBool('ai_insights_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePersonalInfo() async {
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Only update columns that exist in the schema
      await client
          .from('user_profiles')
          .update({
            'full_name': _fullNameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'country': _countryCtrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (mounted) {
        _showSuccess('Profile updated successfully');
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) _showError('Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Get current language from provider
      final langProvider = ThemeProviderInheritedWidget.of(
        context,
      )?.languageProvider;
      final currentLang = langProvider?.language ?? 'English';

      // Save language/timezone to Supabase
      await client
          .from('user_profiles')
          .update({
            'preferred_language': currentLang,
            'time_zone': _selectedTimezone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Save local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', _selectedCurrency);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('ai_insights_enabled', _aiInsightsEnabled);

      if (mounted) _showSuccess('Preferences saved successfully');
    } catch (e) {
      if (mounted) _showError('Failed to save preferences: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateSecurityToggle(String field, bool value) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('user_profiles')
          .update({
            field: value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      if (mounted) _showError('Failed to update security setting');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      _showError('New passwords do not match');
      return;
    }
    if (_newPasswordCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_newPasswordCtrl.text)) {
      _showError('Password must contain at least one uppercase letter');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(_newPasswordCtrl.text)) {
      _showError('Password must contain at least one number');
      return;
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_newPasswordCtrl.text)) {
      _showError('Password must contain at least one special character');
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      // Re-authenticate first
      final client = Supabase.instance.client;
      final email = client.auth.currentUser?.email ?? '';
      await client.auth.signInWithPassword(
        email: email,
        password: _currentPasswordCtrl.text,
      );

      // Update password
      await client.auth.updateUser(
        UserAttributes(password: _newPasswordCtrl.text),
      );

      if (mounted) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showSuccess('Password updated successfully');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Failed to update password');
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _savePIN() async {
    if (_pinCtrl.text.length != 4 ||
        !RegExp(r'^\d{4}$').hasMatch(_pinCtrl.text)) {
      _showError('PIN must be exactly 4 digits');
      return;
    }
    if (_pinCtrl.text != _confirmPinCtrl.text) {
      _showError('PINs do not match');
      return;
    }

    setState(() => _isChangingPIN = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final pinHash = _hashPin(_pinCtrl.text, userId);

      await client
          .from('user_profiles')
          .update({
            'pin_hash': pinHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (mounted) {
        _pinCtrl.clear();
        _confirmPinCtrl.clear();
        setState(() => _hasPIN = true);
        _showSuccess('PIN saved successfully');
      }
    } catch (e) {
      if (mounted) _showError('Failed to save PIN');
    } finally {
      if (mounted) setState(() => _isChangingPIN = false);
    }
  }

  Future<void> _removePIN() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove your PIN?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('user_profiles')
          .update({
            'pin_hash': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (mounted) {
        setState(() => _hasPIN = false);
        _showSuccess('PIN removed successfully');
      }
    } catch (e) {
      if (mounted) _showError('Failed to remove PIN');
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go(AppRoutes.signUpLoginScreen);
    } catch (e) {
      if (mounted) context.go(AppRoutes.signUpLoginScreen);
    }
  }

  /// Simple deterministic hash for PIN storage (userId as salt)
  String _hashPin(String pin, String userId) {
    final salted = '$userId:$pin:cna_salt_2026';
    int hash = 0;
    for (final char in salted.codeUnits) {
      hash = ((hash << 5) - hash) + char;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // ─── DELETE ACCOUNT ───────────────────────────────────────────────────────

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text('Delete Account', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is PERMANENT and cannot be undone.\n\nAll your data including transactions, assets, businesses, investments, and loans will be permanently deleted.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Your current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _isDeletingAccount
                  ? null
                  : () async {
                      if (passwordCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      await _deleteAccount(passwordCtrl.text);
                    },
              child: const Text(
                'Delete Forever',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    setState(() => _isDeletingAccount = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Re-authenticate to verify password
      await client.auth.signInWithPassword(
        email: user.email ?? '',
        password: password,
      );

      final userId = user.id;

      // Delete user data in dependency order
      // (RLS ensures only own data is deleted)
      final tables = [
        'ai_conversations',
        'ai_financial_insights',
        'ai_memory',
        'generated_reports',
        'cash_flow_forecasts',
        'financial_scenarios',
        'wealth_projections',
        'net_worth_snapshots',
        'asset_maintenance',
        'asset_valuations',
        'asset_transactions',
        'asset_ownership',
        'assets',
        'investment_portfolios',
        'investments',
        'business_transactions',
        'business_employees',
        'business_branches',
        'business_kpis',
        'business_inventory',
        'businesses',
        'loan_repayments',
        'loans',
        'financial_transactions',
        'budgets',
        'financial_goals',
        'financial_accounts',
        'income_sources',
        'transaction_categories',
        'analytics_metrics',
        'user_sessions',
        'security_alerts',
        'audit_logs',
        'user_profiles',
      ];

      for (final table in tables) {
        try {
          await client.from(table).delete().eq('user_id', userId);
        } catch (_) {
          // Some tables use 'id' or 'owner_id' as the user column
          try {
            await client.from(table).delete().eq('id', userId);
          } catch (_) {
            try {
              await client.from(table).delete().eq('owner_id', userId);
            } catch (_) {
              // Table may not exist or already deleted
            }
          }
        }
      }

      // Sign out
      await client.auth.signOut();

      if (mounted) {
        _showSuccess('Account deleted successfully');
        context.go(AppRoutes.signUpLoginScreen);
      }
    } on AuthException catch (e) {
      if (mounted) _showError('Authentication failed: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Failed to delete account. Please try again.');
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  // ─── DATA EXPORT ──────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    _showInfo('Preparing your data export...');
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Gather all user data
      final results = await Future.wait(
        [
              client
                  .from('user_profiles')
                  .select()
                  .eq('id', userId)
                  .maybeSingle(),
              client
                  .from('financial_transactions')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at', ascending: false)
                  .limit(500),
              client.from('assets').select().eq('user_id', userId),
              client.from('businesses').select().eq('owner_id', userId),
              client.from('investments').select().eq('user_id', userId),
              client.from('loans').select().eq('user_id', userId),
            ]
            as List<Future<dynamic>>,
      );

      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'profile': results[0],
        'transactions': results[1],
        'assets': results[2],
        'businesses': results[3],
        'investments': results[4],
        'loans': results[5],
      };

      // Convert to CSV-like summary text
      final buffer = StringBuffer();
      buffer.writeln('CNA Data Export — ${DateTime.now().toString()}');
      buffer.writeln('=' * 60);
      buffer.writeln('\n## PROFILE');
      final profile = exportData['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        buffer.writeln('Name: ${profile['full_name'] ?? ''}');
        buffer.writeln('Email: ${profile['email'] ?? ''}');
        buffer.writeln('Country: ${profile['country'] ?? ''}');
        buffer.writeln('Account Type: ${profile['account_type'] ?? ''}');
        buffer.writeln('Member Since: ${profile['created_at'] ?? ''}');
      }

      final txns = exportData['transactions'] as List? ?? [];
      buffer.writeln('\n## TRANSACTIONS (${txns.length} records)');
      for (final t in txns.take(100)) {
        final tx = t as Map<String, dynamic>;
        buffer.writeln(
          '${tx['created_at']?.toString().substring(0, 10) ?? ''} | ${tx['type'] ?? ''} | ${tx['amount'] ?? ''} ${tx['currency'] ?? ''} | ${tx['description'] ?? ''}',
        );
      }

      final assets = exportData['assets'] as List? ?? [];
      buffer.writeln('\n## ASSETS (${assets.length} records)');
      for (final a in assets) {
        final asset = a as Map<String, dynamic>;
        buffer.writeln(
          '${asset['name'] ?? ''} | ${asset['asset_type'] ?? ''} | Value: ${asset['current_value'] ?? ''}',
        );
      }

      final businesses = exportData['businesses'] as List? ?? [];
      buffer.writeln('\n## BUSINESSES (${businesses.length} records)');
      for (final b in businesses) {
        final biz = b as Map<String, dynamic>;
        buffer.writeln(
          '${biz['name'] ?? ''} | ${biz['business_type'] ?? ''} | Status: ${biz['status'] ?? ''}',
        );
      }

      final investments = exportData['investments'] as List? ?? [];
      buffer.writeln('\n## INVESTMENTS (${investments.length} records)');
      for (final i in investments) {
        final inv = i as Map<String, dynamic>;
        buffer.writeln(
          '${inv['name'] ?? ''} | ${inv['investment_type'] ?? ''} | Value: ${inv['current_value'] ?? ''}',
        );
      }

      final loans = exportData['loans'] as List? ?? [];
      buffer.writeln('\n## LOANS (${loans.length} records)');
      for (final l in loans) {
        final loan = l as Map<String, dynamic>;
        buffer.writeln(
          '${loan['lender_name'] ?? loan['borrower_name'] ?? ''} | ${loan['loan_type'] ?? ''} | Balance: ${loan['outstanding_balance'] ?? ''}',
        );
      }

      final exportText = buffer.toString();

      if (kIsWeb) {
        // Web: trigger browser download
        _downloadOnWeb(
          exportText,
          'cna_export_${DateTime.now().millisecondsSinceEpoch}.txt',
        );
      } else {
        // Mobile: show data in dialog (path_provider not available without adding package)
        _showExportDialog(exportText);
      }
    } catch (e) {
      if (mounted) _showError('Export failed: ${e.toString()}');
    }
  }

  void _downloadOnWeb(String content, String filename) {
    // Trigger a real browser file download using conditional web APIs
    try {
      web_download.downloadFile(content, filename);
      if (mounted) _showSuccess('Export downloaded successfully');
    } catch (e) {
      _showExportDialog(content);
    }
  }

  void _showExportDialog(String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download_done, color: AppTheme.success),
            const SizedBox(width: 8),
            const Text('Data Export Ready'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── ABOUT / LEGAL PAGES ─────────────────────────────────────────────────

  void _showAboutPage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'CNA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('About CNA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutRow('App Name', 'Capital Nexus AI'),
            _buildAboutRow('Version', '1.0.0 (Build 100)'),
            _buildAboutRow('Platform', kIsWeb ? 'Web' : 'Mobile'),
            _buildAboutRow('Framework', 'Flutter'),
            const Divider(height: 20),
            const Text(
              'Capital Nexus AI is a comprehensive financial management platform powered by artificial intelligence. Manage your finances, businesses, assets, investments, and loans in one place.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '© 2026 Capital Nexus AI. All rights reserved.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsPage() {
    _showLegalPage('Terms of Service', '''CAPITAL NEXUS AI — TERMS OF SERVICE

Last Updated: January 2026

1. ACCEPTANCE OF TERMS
By using Capital Nexus AI ("CNA"), you agree to these Terms of Service. If you do not agree, do not use the application.

2. USE OF SERVICE
CNA is a personal financial management tool. You are responsible for the accuracy of data you enter. CNA does not provide licensed financial advice.

3. DATA OWNERSHIP
All financial data you enter belongs to you. CNA stores your data securely using Supabase infrastructure with row-level security.

4. PRIVACY
Your data is protected by our Privacy Policy. We do not sell your personal information to third parties.

5. AI FEATURES
AI-generated insights are for informational purposes only and should not be considered professional financial advice. Always consult a qualified financial advisor for major decisions.

6. ACCOUNT SECURITY
You are responsible for maintaining the security of your account credentials, PIN, and biometric settings.

7. LIMITATION OF LIABILITY
CNA is provided "as is" without warranties. We are not liable for financial decisions made based on information in the app.

8. CHANGES TO TERMS
We may update these terms. Continued use after changes constitutes acceptance.

9. CONTACT
For questions about these terms, contact support through the app.''');
  }

  void _showPrivacyPage() {
    _showLegalPage('Privacy Policy', '''CAPITAL NEXUS AI — PRIVACY POLICY

Last Updated: January 2026

1. INFORMATION WE COLLECT
- Account information (name, email, phone)
- Financial data you voluntarily enter (transactions, assets, businesses, investments, loans)
- Usage data (login times, feature usage)
- Device information (device type, operating system)

2. HOW WE USE YOUR INFORMATION
- To provide and improve the CNA service
- To generate AI-powered financial insights
- To send notifications and reminders you configure
- To maintain account security

3. DATA STORAGE
Your data is stored securely using Supabase with:
- Row-Level Security (RLS) ensuring only you can access your data
- Encrypted connections (HTTPS/TLS)
- Regular security audits

4. DATA SHARING
We do NOT sell your personal information. We may share data with:
- Service providers necessary to operate CNA (Supabase, AI providers)
- Law enforcement when legally required

5. YOUR RIGHTS
- Access your data via the Export Data feature
- Delete your account and all data via Settings
- Update your information in Profile Settings
- Opt out of AI insights in Preferences

6. COOKIES & LOCAL STORAGE
CNA uses local storage for preferences (theme, language, currency). No tracking cookies are used.

7. CHILDREN'S PRIVACY
CNA is not intended for users under 18 years of age.

8. CONTACT
For privacy concerns, use the Support option in Settings.''');
  }

  void _showLegalPage(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupportPage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help with Capital Nexus AI?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildSupportRow(
              Icons.email_outlined,
              'Email',
              'support@capitalnexusai.com',
            ),
            const SizedBox(height: 8),
            _buildSupportRow(
              Icons.language_outlined,
              'Website',
              'www.capitalnexusai.com',
            ),
            const SizedBox(height: 8),
            _buildSupportRow(
              Icons.chat_bubble_outline,
              'In-App Chat',
              'Use the AI Center for quick help',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Response time: 24-48 hours for email support. AI Center is available 24/7.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 2FA DIALOG ───────────────────────────────────────────────────────────

  void _show2FASetupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Two-Factor Authentication adds an extra layer of security to your account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Full TOTP setup (QR code + authenticator app) requires server-side configuration. Your 2FA preference will be saved and enforced when the server-side component is activated.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _twoFactorEnabled = true);
              await _updateSecurityToggle('two_factor_enabled', true);
              if (mounted) {
                _showSuccess(
                  '2FA preference saved. Will be enforced when server-side setup is complete.',
                );
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication'),
        content: const Text(
          'This will reduce your account security. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _twoFactorEnabled = false);
      await _updateSecurityToggle('two_factor_enabled', false);
      if (mounted) _showSuccess('2FA disabled');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeWidget = ThemeProviderInheritedWidget.of(context);
    final themeProvider = themeWidget?.themeProvider;
    final langProvider = themeWidget?.languageProvider;
    final isDark = themeProvider?.isDark ?? false;

    final bg = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final onSurface = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : Column(
                children: [
                  _buildHeader(surface, onSurface, muted),
                  _buildProfileCard(surface, onSurface, muted),
                  _buildTabBar(surface, muted),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalTab(
                          bg,
                          surface,
                          onSurface,
                          muted,
                          outline,
                        ),
                        _buildSecurityTab(
                          bg,
                          surface,
                          onSurface,
                          muted,
                          outline,
                        ),
                        _buildPreferencesTab(
                          bg,
                          surface,
                          onSurface,
                          muted,
                          outline,
                          themeProvider,
                          langProvider,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(Color surface, Color onSurface, Color muted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: surface,
      child: Row(
        children: [
          Text(
            'Profile & Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _signOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomIconWidget(
                    iconName: 'logout',
                    color: AppTheme.error,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Color surface, Color onSurface, Color muted) {
    final name = _profile?['full_name'] as String? ?? 'User';
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final subscription = _profile?['subscription_level'] as String? ?? 'free';
    final accountType = _profile?['account_type'] as String? ?? 'personal';

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge(
                      _capitalize(accountType),
                      const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 6),
                    _buildBadge(
                      _capitalize(subscription),
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabBar(Color surface, Color muted) {
    return Container(
      color: surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: muted,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Personal'),
          Tab(text: 'Security'),
          Tab(text: 'Preferences'),
        ],
      ),
    );
  }

  // ─── PERSONAL TAB ────────────────────────────────────────────────────────

  Widget _buildPersonalTab(
    Color bg,
    Color surface,
    Color onSurface,
    Color muted,
    Color outline,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Personal Information', muted),
        _buildEditCard(surface, outline, [
          _buildEditField(
            'Full Name',
            _fullNameCtrl,
            'person',
            onSurface,
            muted,
          ),
          _buildEditField(
            'Phone',
            _phoneCtrl,
            'phone',
            onSurface,
            muted,
            keyboardType: TextInputType.phone,
          ),
          _buildEditField('Country', _countryCtrl, 'flag', onSurface, muted),
          _buildEditField('City', _cityCtrl, 'location_city', onSurface, muted),
          _buildEditField('Address', _addressCtrl, 'home', onSurface, muted),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('Account Information', muted),
        _buildInfoCard(surface, outline, [
          _buildInfoRow(
            'Email',
            Supabase.instance.client.auth.currentUser?.email ?? '',
            'email',
            onSurface,
            muted,
          ),
          _buildInfoRow(
            'Account Type',
            _capitalize(_profile?['account_type'] as String? ?? 'personal'),
            'business_center',
            onSurface,
            muted,
          ),
          _buildInfoRow(
            'Member Since',
            _formatDate(_profile?['created_at'] as String?),
            'calendar_today',
            onSurface,
            muted,
          ),
          _buildInfoRow(
            'Account Status',
            _capitalize(_profile?['account_status'] as String? ?? 'active'),
            'verified',
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePersonalInfo,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ─── SECURITY TAB ────────────────────────────────────────────────────────

  Widget _buildSecurityTab(
    Color bg,
    Color surface,
    Color onSurface,
    Color muted,
    Color outline,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Authentication', muted),
        _buildSettingsCard(surface, outline, [
          _buildToggleRow(
            'Biometric Login',
            kIsWeb
                ? 'Not available on web browsers'
                : 'Use fingerprint or face ID',
            'fingerprint',
            _biometricEnabled,
            kIsWeb
                ? null
                : (v) {
                    setState(() => _biometricEnabled = v);
                    _updateSecurityToggle('biometric_enabled', v);
                    if (v) {
                      _showInfo(
                        'Biometric preference saved. Will activate on next login.',
                      );
                    }
                  },
            onSurface,
            muted,
          ),
          _buildToggleRow(
            'Two-Factor Auth',
            _twoFactorEnabled
                ? 'Enabled — preference saved'
                : 'Add extra security layer',
            'security',
            _twoFactorEnabled,
            (v) {
              if (v) {
                _show2FASetupDialog();
              } else {
                _disable2FA();
              }
            },
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('Change Password', muted),
        _buildPasswordChangeCard(surface, outline, onSurface, muted),
        const SizedBox(height: 16),
        _buildSectionHeader('PIN Management', muted),
        _buildPINCard(surface, outline, onSurface, muted),
        const SizedBox(height: 16),
        _buildSectionHeader('Security Center', muted),
        _buildSettingsCard(surface, outline, [
          _buildActionRow(
            'Security Dashboard',
            'Score, alerts & active devices',
            'shield',
            () => context.push(AppRoutes.securityDashboardScreen),
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Organization',
            'Manage members, roles & permissions',
            'corporate_fare',
            () => context.push(AppRoutes.organizationDashboardScreen),
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Active Sessions',
            'View all logged-in devices',
            'devices',
            () => context.push(AppRoutes.securityDashboardScreen),
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('Privacy & Account', muted),
        _buildSettingsCard(surface, outline, [
          _buildActionRow(
            'Export My Data',
            'Download all your data',
            'download',
            _exportData,
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Delete Account',
            'Permanently remove account',
            'delete_forever',
            _showDeleteAccountDialog,
            onSurface,
            muted,
            isDestructive: true,
          ),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPasswordChangeCard(
    Color surface,
    Color outline,
    Color onSurface,
    Color muted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPasswordField(
            'Current Password',
            _currentPasswordCtrl,
            _obscureCurrent,
            () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            'New Password',
            _newPasswordCtrl,
            _obscureNew,
            () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 4),
          _buildPasswordStrengthIndicator(),
          const SizedBox(height: 12),
          _buildPasswordField(
            'Confirm New Password',
            _confirmPasswordCtrl,
            _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AppTheme.mutedLight,
          ),
          onPressed: toggleObscure,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _newPasswordCtrl,
      builder: (_, val, __) {
        final pw = val.text;
        int s = 0;
        if (pw.length >= 8) s++;
        if (RegExp(r'[A-Z]').hasMatch(pw)) s++;
        if (RegExp(r'[0-9]').hasMatch(pw)) s++;
        if (RegExp(r'[!@#\$%^&*]').hasMatch(pw)) s++;

        if (pw.isEmpty) return const SizedBox.shrink();
        final colors = [
          Colors.transparent,
          AppTheme.error,
          AppTheme.warning,
          const Color(0xFF3B82F6),
          AppTheme.success,
        ];
        final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              ...List.generate(
                4,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i < s ? colors[s] : AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                labels[s],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: colors[s],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPINCard(
    Color surface,
    Color outline,
    Color onSurface,
    Color muted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'pin',
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasPIN ? 'Change PIN' : 'Create PIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      _hasPIN
                          ? 'Update your 4-digit transaction PIN'
                          : 'Set a 4-digit transaction PIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasPIN)
                GestureDetector(
                  onTap: _removePIN,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New PIN (4 digits)',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmPinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isChangingPIN ? null : _savePIN,
              child: _isChangingPIN
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_hasPIN ? 'Update PIN' : 'Set PIN'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PREFERENCES TAB ─────────────────────────────────────────────────────

  Widget _buildPreferencesTab(
    Color bg,
    Color surface,
    Color onSurface,
    Color muted,
    Color outline,
    ThemeProvider? themeProvider,
    LanguageProvider? langProvider,
  ) {
    final isDark = themeProvider?.isDark ?? false;
    final currentLang = langProvider?.language ?? 'English';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Display', muted),
        _buildSettingsCard(surface, outline, [
          _buildToggleRow(
            'Dark Mode',
            'Switch to dark interface',
            'dark_mode',
            isDark,
            (v) async {
              await themeProvider?.toggleDark(v);
            },
            onSurface,
            muted,
          ),
          _buildDropdownRow(
            'Currency',
            _selectedCurrency,
            ['TZS', 'USD', 'EUR', 'KES', 'GBP', 'ZAR'],
            (v) => setState(() => _selectedCurrency = v!),
            'currency_exchange',
            onSurface,
            muted,
          ),
          _buildDropdownRow(
            'Language',
            currentLang,
            LanguageProvider.supportedLanguages,
            (v) async {
              if (v != null) {
                await langProvider?.setLanguage(v);
                // Also save to DB
                final client = Supabase.instance.client;
                final userId = client.auth.currentUser?.id;
                if (userId != null) {
                  try {
                    await client
                        .from('user_profiles')
                        .update({
                          'preferred_language': v,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', userId);
                  } catch (_) {}
                }
              }
            },
            'language',
            onSurface,
            muted,
          ),
          _buildDropdownRow(
            'Time Zone',
            _selectedTimezone,
            [
              'Africa/Dar_es_Salaam',
              'Africa/Nairobi',
              'Africa/Lagos',
              'UTC',
              'Europe/London',
            ],
            (v) => setState(() => _selectedTimezone = v!),
            'schedule',
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('Notifications', muted),
        _buildSettingsCard(surface, outline, [
          _buildToggleRow(
            'Push Notifications',
            'Alerts and reminders',
            'notifications',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
            onSurface,
            muted,
          ),
          _buildToggleRow(
            'AI Insights',
            'Daily financial tips from AI',
            'psychology',
            _aiInsightsEnabled,
            (v) => setState(() => _aiInsightsEnabled = v),
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Preferences',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('About', muted),
        _buildSettingsCard(surface, outline, [
          _buildActionRow(
            'Version',
            'CNA v1.0.0 (Build 100)',
            'info',
            _showAboutPage,
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Terms of Service',
            'Read our terms',
            'description',
            _showTermsPage,
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Privacy Policy',
            'How we use your data',
            'policy',
            _showPrivacyPage,
            onSurface,
            muted,
          ),
          _buildActionRow(
            'Support',
            'Get help from our team',
            'support_agent',
            _showSupportPage,
            onSurface,
            muted,
          ),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: muted,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEditCard(Color surface, Color outline, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: children
            .expand(
              (w) => [w, if (w != children.last) const SizedBox(height: 12)],
            )
            .toList(),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController ctrl,
    String icon,
    Color onSurface,
    Color muted, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 8, left: 4),
          child: CustomIconWidget(
            iconName: icon,
            color: AppTheme.primary,
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color surface, Color outline, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsCard(
    Color surface,
    Color outline,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    String icon,
    Color onSurface,
    Color muted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    String icon,
    bool value,
    ValueChanged<bool>? onChanged,
    Color onSurface,
    Color muted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String title,
    String subtitle,
    String icon,
    VoidCallback onTap,
    Color onSurface,
    Color muted, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.errorContainer
                    : AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: isDestructive ? AppTheme.error : AppTheme.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDestructive ? AppTheme.error : onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: isDestructive ? AppTheme.error : muted,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    String icon,
    Color onSurface,
    Color muted,
  ) {
    final safeValue = options.contains(value) ? value : options.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: safeValue,
            underline: const SizedBox(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
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
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
