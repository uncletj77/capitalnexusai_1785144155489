import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class ExportWizardWidget extends StatefulWidget {
  const ExportWizardWidget({super.key});

  @override
  State<ExportWizardWidget> createState() => _ExportWizardWidgetState();
}

class _ExportWizardWidgetState extends State<ExportWizardWidget> {
  final _service = IntegrationService.instance;
  List<ImportExportJob> _jobs = [];
  bool _loading = true;
  bool _exporting = false;
  String _selectedFormat = 'csv';
  String _selectedType = 'financial_report';

  final _formats = ['csv', 'json', 'excel'];
  final _exportTypes = [
    {
      'key': 'financial_report',
      'label': 'Financial Report',
      'icon': 'account_balance_wallet',
    },
    {
      'key': 'business_report',
      'label': 'Business Report',
      'icon': 'business_center',
    },
    {'key': 'assets', 'label': 'Assets Export', 'icon': 'real_estate_agent'},
    {'key': 'loans', 'label': 'Loans Export', 'icon': 'credit_card'},
    {
      'key': 'investments',
      'label': 'Investments Export',
      'icon': 'trending_up',
    },
    {'key': 'analytics', 'label': 'Analytics Export', 'icon': 'analytics'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getImportExportJobs();
    if (mounted) {
      setState(() {
        _jobs = data.where((j) => j.jobType == 'export').toList();
        _loading = false;
      });
    }
  }

  Future<void> _runExport() async {
    setState(() => _exporting = true);
    final typeLabel =
        _exportTypes.firstWhere((t) => t['key'] == _selectedType)['label']
            as String;
    await _service.generateExport(
      exportType: _selectedType,
      fileFormat: _selectedFormat,
      title: typeLabel,
    );
    if (mounted) {
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$typeLabel exported successfully',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export type selector
          Text(
            'Select Export Type',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: _exportTypes.map((t) {
              final sel = _selectedType == t['key'];
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t['key'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primaryLight.withAlpha(15)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? AppTheme.primaryLight
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: t['icon'] as String,
                        color: sel
                            ? AppTheme.primaryLight
                            : AppTheme.mutedLight,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppTheme.primaryLight
                                : AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Format selector
          Text(
            'Export Format',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _formats.map((f) {
              final sel = _selectedFormat == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFormat = f),
                  child: Container(
                    margin: EdgeInsets.only(right: f != _formats.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryLight
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryLight
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        f.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _exporting ? null : _runExport,
              child: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Generate Export',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Export History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 10),
          ..._jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'download',
                      color: const Color(0xFF2D9CDB),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.fileName ?? 'Export file',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            (job.fileFormat ?? '').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: job.status == 'completed'
                            ? const Color(0xFF10B981).withAlpha(20)
                            : AppTheme.mutedLight.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: job.status == 'completed'
                              ? const Color(0xFF10B981)
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
