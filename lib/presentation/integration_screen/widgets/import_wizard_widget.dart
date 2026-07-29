import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class ImportWizardWidget extends StatefulWidget {
  const ImportWizardWidget({super.key});

  @override
  State<ImportWizardWidget> createState() => _ImportWizardWidgetState();
}

class _ImportWizardWidgetState extends State<ImportWizardWidget> {
  final _service = IntegrationService.instance;
  List<ImportExportJob> _jobs = [];
  bool _loading = true;
  int _wizardStep = 0;
  String _selectedFormat = 'csv';
  String _selectedType = 'transactions';

  final _formats = ['csv', 'excel', 'json'];
  final _importTypes = [
    'transactions',
    'assets',
    'loans',
    'investments',
    'businesses',
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
        _jobs = data.where((j) => j.jobType == 'import').toList();
        _loading = false;
      });
    }
  }

  void _startWizard() {
    setState(() => _wizardStep = 1);
  }

  Future<void> _runImport() async {
    setState(() => _loading = true);
    // Simulate import with sample data
    final sampleRows = List.generate(
      10,
      (i) => {
        'date': '2025-0${(i % 9) + 1}-01',
        'amount': (i + 1) * 50000,
        'description': 'Sample transaction $i',
      },
    );
    final preview = await _service.previewImport(
      fileName: '${_selectedType}_import.$_selectedFormat',
      fileFormat: _selectedFormat,
      sampleRows: sampleRows,
    );

    if (preview['can_import'] == true) {
      await _service.startImportJob(
        fileName: '${_selectedType}_import.$_selectedFormat',
        fileFormat: _selectedFormat,
        recordCount: 10,
      );
    }
    setState(() {
      _wizardStep = 0;
      _loading = false;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_wizardStep > 0) return _buildWizard();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: _startWizard,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryLight.withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'upload_file',
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start New Import',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'CSV, Excel, JSON supported',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CustomIconWidget(
                    iconName: 'arrow_forward',
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Import History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _jobs.isEmpty
              ? Center(
                  child: Text(
                    'No imports yet',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _jobCard(_jobs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildWizard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _wizardStep = 0),
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.onSurfaceLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Import Wizard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _wizardSection(
            '1. Select Data Type',
            _importTypes,
            _selectedType,
            (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 16),
          _wizardSection(
            '2. Select File Format',
            _formats,
            _selectedFormat,
            (v) => setState(() => _selectedFormat = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Validation Rules',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 8),
                _validationRow('Required columns check', true),
                _validationRow('Duplicate detection', true),
                _validationRow('Data type validation', true),
                _validationRow('Referential integrity', true),
              ],
            ),
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
              onPressed: _runImport,
              child: Text(
                'Preview & Import',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizardSection(
    String title,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.outlineLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((o) {
            final sel = o == selected;
            return GestureDetector(
              onTap: () => onSelect(o),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primaryLight : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? AppTheme.primaryLight : AppTheme.outlineLight,
                  ),
                ),
                child: Text(
                  o.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppTheme.mutedLight,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _validationRow(String label, bool enabled) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        CustomIconWidget(
          iconName: enabled ? 'check_circle' : 'cancel',
          color: enabled ? const Color(0xFF10B981) : AppTheme.mutedLight,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.onSurfaceLight,
          ),
        ),
      ],
    ),
  );

  Widget _jobCard(ImportExportJob job) {
    final statusColor = job.status == 'completed'
        ? const Color(0xFF10B981)
        : job.status == 'processing'
        ? const Color(0xFF2D9CDB)
        : AppTheme.mutedLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'upload_file',
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.fileName ?? 'Unknown file',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${job.recordCount} records · ${(job.fileFormat ?? '').toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              job.status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}