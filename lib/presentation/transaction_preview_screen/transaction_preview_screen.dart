import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/universal_registration_service.dart';
import '../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION PREVIEW SCREEN
// Shown after a successful commit — confirms what was saved and what synced.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionPreviewScreen extends StatelessWidget {
  final CommitResult commitResult;
  final RegistrationCategory registrationCategory;
  final String registrationType;
  final Map<String, dynamic> formData;

  const TransactionPreviewScreen({
    super.key,
    required this.commitResult,
    required this.registrationCategory,
    required this.registrationType,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    final syncedModules = commitResult.syncedModules;
    final typeLabel =
        RegistrationTypes.byCategory[registrationCategory]?.firstWhere(
          (t) => t['key'] == registrationType,
          orElse: () => {'label': registrationType},
        )['label'] ??
        registrationType;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Success animation
              _buildSuccessHeader(typeLabel),
              const SizedBox(height: 32),

              // Record ID
              if (commitResult.entityId != null) ...[
                _buildRecordIdCard(commitResult.entityId!),
                const SizedBox(height: 16),
              ],

              // What was saved
              _buildSavedDataCard(formData),
              const SizedBox(height: 16),

              // Synced modules
              _buildSyncedModulesCard(syncedModules),
              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(String typeLabel) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.success,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Successfully Saved!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$typeLabel has been registered and synchronized across all connected modules.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.mutedLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordIdCard(String entityId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          const CustomIconWidget(
            iconName: 'fingerprint',
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record ID',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                  ),
                ),
                Text(
                  entityId.length > 20
                      ? '${entityId.substring(0, 20)}...'
                      : entityId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: entityId));
            },
            child: const CustomIconWidget(
              iconName: 'copy',
              color: AppTheme.mutedLight,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDataCard(Map<String, dynamic> data) {
    final displayEntries = data.entries
        .where(
          (e) =>
              e.value != null &&
              e.value.toString().isNotEmpty &&
              !e.key.endsWith('_id'),
        )
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registration Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.outlineLight),
          const SizedBox(height: 8),
          ...displayEntries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      _fieldKeyToLabel(e.key),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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

  Widget _buildSyncedModulesCard(Map<String, bool> syncedModules) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'sync',
                color: AppTheme.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Synchronized Modules',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...syncedModules.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: e.value ? 'check_circle' : 'error',
                    color: e.value ? AppTheme.success : AppTheme.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    e.key,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    e.value ? 'Updated' : 'Failed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: e.value ? AppTheme.success : AppTheme.danger,
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

  Widget _buildActionButtons(BuildContext context) {
    final nextRoute = _getNextRoute();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Register another of the same type
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const _URWLauncher()),
              );
            },
            icon: const CustomIconWidget(
              iconName: 'add',
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              'Register Another',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (nextRoute != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(nextRoute),
              icon: CustomIconWidget(
                iconName: 'open_in_new',
                color: AppTheme.primary,
                size: 18,
              ),
              label: Text(
                'View in ${_getModuleLabel()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.dashboardScreen),
            child: Text(
              'Go to Dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _getNextRoute() {
    switch (registrationCategory) {
      case RegistrationCategory.transaction:
        return AppRoutes.transactionHistoryScreen;
      case RegistrationCategory.business:
        return AppRoutes.businessDashboardScreen;
      case RegistrationCategory.investment:
        return AppRoutes.investmentDashboardScreen;
      case RegistrationCategory.asset:
        return AppRoutes.assetDashboardScreen;
      case RegistrationCategory.loan:
        return registrationType == 'loan_receivable'
            ? AppRoutes.loansReceivableScreen
            : AppRoutes.loanDashboardScreen;
      case RegistrationCategory.organization:
        return AppRoutes.organizationDashboardScreen;
    }
  }

  String _getModuleLabel() {
    switch (registrationCategory) {
      case RegistrationCategory.transaction:
        return 'Transactions';
      case RegistrationCategory.business:
        return 'Business';
      case RegistrationCategory.investment:
        return 'Investments';
      case RegistrationCategory.asset:
        return 'Assets';
      case RegistrationCategory.loan:
        return 'Loans';
      case RegistrationCategory.organization:
        return 'Organizations';
    }
  }

  String _fieldKeyToLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// Helper widget to re-launch the URW
class _URWLauncher extends StatelessWidget {
  const _URWLauncher();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.universalRegistrationWizardScreen);
    });
    return const Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}