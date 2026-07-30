import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class ApiKeyManagerWidget extends StatefulWidget {
  const ApiKeyManagerWidget({super.key});

  @override
  State<ApiKeyManagerWidget> createState() => _ApiKeyManagerWidgetState();
}

class _ApiKeyManagerWidgetState extends State<ApiKeyManagerWidget> {
  final _service = IntegrationService.instance;
  List<ApiKeyEntry> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getApiKeys();
    if (mounted) {
      setState(() {
        _keys = data;
        _loading = false;
      });
    }
  }

  void _showAddKeyDialog() {
    final providerCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add API Key',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(providerCtrl, 'Provider Name', 'e.g. OpenAI'),
            const SizedBox(height: 10),
            _field(labelCtrl, 'Key Label', 'e.g. Production Key'),
            const SizedBox(height: 10),
            _field(keyCtrl, 'API Key', 'sk-...', obscure: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'lock',
                    color: Color(0xFFF59E0B),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keys are encrypted before storage. Raw values are never saved.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFFF59E0B),
                      ),
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
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
            ),
            onPressed: () async {
              if (providerCtrl.text.isNotEmpty && keyCtrl.text.isNotEmpty) {
                await _service.addApiKey(
                  providerName: providerCtrl.text,
                  keyReference: keyCtrl.text,
                  keyLabel: labelCtrl.text.isNotEmpty
                      ? labelCtrl.text
                      : providerCtrl.text,
                );
                Navigator.pop(ctx);
                _load();
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool obscure = false,
  }) => TextField(
    controller: ctrl,
    obscureText: obscure,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppTheme.onSurfaceLight,
    ),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppTheme.mutedLight,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppTheme.mutedLight.withAlpha(100),
      ),
      filled: true,
      fillColor: AppTheme.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.outlineLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.outlineLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primaryLight),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_keys.length} API Keys',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showAddKeyDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryLight.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'add',
                        color: AppTheme.primaryLight,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Key',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final key = _keys[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'vpn_key',
                          color: AppTheme.primaryLight,
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
                            key.keyLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key.providerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '••••••••${key.keyReference.substring(key.keyReference.length > 8 ? key.keyReference.length - 6 : 0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: key.isActive
                                ? const Color(0xFF10B981).withAlpha(20)
                                : AppTheme.mutedLight.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            key.isActive ? 'Active' : 'Revoked',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: key.isActive
                                  ? const Color(0xFF10B981)
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ),
                        if (key.isActive) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              await _service.revokeApiKey(key.id);
                              _load();
                            },
                            child: Text(
                              'Revoke',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
