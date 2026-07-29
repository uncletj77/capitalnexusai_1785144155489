import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/cfie_service.dart';
import '../../../theme/app_theme.dart';

class ScenarioSimulatorWidget extends StatefulWidget {
  const ScenarioSimulatorWidget({super.key});

  @override
  State<ScenarioSimulatorWidget> createState() =>
      _ScenarioSimulatorWidgetState();
}

class _ScenarioSimulatorWidgetState extends State<ScenarioSimulatorWidget> {
  String _selectedType = 'asset_purchase';
  bool _isRunning = false;
  Map<String, dynamic>? _result;

  final _nameController = TextEditingController(text: 'My Scenario');
  final _param1Controller = TextEditingController();
  final _param2Controller = TextEditingController();
  final _param3Controller = TextEditingController();

  final _scenarioTypes = [
    {
      'key': 'asset_purchase',
      'label': 'Asset Purchase',
      'icon': Icons.real_estate_agent,
    },
    {'key': 'loan', 'label': 'Loan Simulation', 'icon': Icons.account_balance},
    {
      'key': 'business_expansion',
      'label': 'Business Expansion',
      'icon': Icons.business_center,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _param1Controller.dispose();
    _param2Controller.dispose();
    _param3Controller.dispose();
    super.dispose();
  }

  Map<String, String> _getLabels() {
    switch (_selectedType) {
      case 'asset_purchase':
        return {
          'p1': 'Asset Price (TZS)',
          'p2': 'Expected Weekly Revenue (TZS)',
          'p3': 'Weekly Operating Cost (TZS)',
        };
      case 'loan':
        return {
          'p1': 'Loan Amount (TZS)',
          'p2': 'Interest Rate (%)',
          'p3': 'Duration (Months)',
        };
      case 'business_expansion':
        return {
          'p1': 'Investment Amount (TZS)',
          'p2': 'Expected Monthly Revenue (TZS)',
          'p3': 'Monthly Operating Cost (TZS)',
        };
      default:
        return {'p1': 'Parameter 1', 'p2': 'Parameter 2', 'p3': 'Parameter 3'};
    }
  }

  Map<String, dynamic> _buildAssumptions() {
    final p1 = double.tryParse(_param1Controller.text.replaceAll(',', '')) ?? 0;
    final p2 = double.tryParse(_param2Controller.text.replaceAll(',', '')) ?? 0;
    final p3 = double.tryParse(_param3Controller.text.replaceAll(',', '')) ?? 0;

    switch (_selectedType) {
      case 'asset_purchase':
        return {
          'asset_price': p1,
          'expected_weekly_revenue': p2,
          'weekly_fuel_cost': p3,
        };
      case 'loan':
        return {
          'loan_amount': p1,
          'interest_rate': p2,
          'duration_months': p3.toInt(),
        };
      case 'business_expansion':
        return {
          'investment_amount': p1,
          'expected_monthly_revenue': p2,
          'monthly_operating_cost': p3,
        };
      default:
        return {};
    }
  }

  Future<void> _runSimulation() async {
    if (_param1Controller.text.isEmpty) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });
    try {
      final res = await CfieService.instance.simulateScenario({
        'scenario_name': _nameController.text,
        'scenario_type': _selectedType,
        'assumptions': _buildAssumptions(),
      });
      setState(() => _result = res);
    } catch (_) {
    } finally {
      setState(() => _isRunning = false);
    }
  }

  String _formatAmount(dynamic v) {
    final val = (v as num?)?.toDouble() ?? 0;
    if (val.abs() >= 1000000) {
      return 'TZS ${(val / 1000000).toStringAsFixed(1)}M';
    }
    if (val.abs() >= 1000) return 'TZS ${(val / 1000).toStringAsFixed(0)}K';
    return 'TZS ${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = _getLabels();
    final resultData = _result?['result'] as Map<String, dynamic>?;
    final riskScore = _result?['risk_score'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.science,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Scenario Simulator',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Scenario type selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _scenarioTypes.map((t) {
                final isSelected = _selectedType == t['key'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = t['key'] as String;
                    _result = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          t['icon'] as IconData,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.mutedLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _inputField('Scenario Name', _nameController, 'e.g. Buy New Bus'),
          const SizedBox(height: 8),
          _inputField(labels['p1']!, _param1Controller, '0'),
          const SizedBox(height: 8),
          _inputField(labels['p2']!, _param2Controller, '0'),
          const SizedBox(height: 8),
          _inputField(labels['p3']!, _param3Controller, '0'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRunning
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Run Simulation',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (resultData != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Simulation Results',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      _riskBadge(riskScore),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...resultData.entries.where((e) => e.key != 'risk_level').map((
                    e,
                  ) {
                    final isAmount =
                        e.key.contains('amount') ||
                        e.key.contains('payment') ||
                        e.key.contains('profit') ||
                        e.key.contains('impact') ||
                        e.key.contains('gain');
                    final isPercent =
                        e.key.contains('percentage') || e.key.contains('ratio');
                    String displayValue;
                    if (isAmount) {
                      displayValue = _formatAmount(e.value);
                    } else if (isPercent) {
                      displayValue =
                          '${(e.value as num?)?.toStringAsFixed(1) ?? '0'}${e.key.contains('ratio') ? '' : '%'}';
                    } else {
                      displayValue = e.value?.toString() ?? '';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatKey(e.key),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          Text(
                            displayValue,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.mutedLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariantLight,
          ),
        ),
      ],
    );
  }

  Widget _riskBadge(int score) {
    Color color;
    String label;
    if (score < 30) {
      color = AppTheme.success;
      label = 'Low Risk';
    } else if (score < 60) {
      color = AppTheme.warning;
      label = 'Medium Risk';
    } else {
      color = AppTheme.error;
      label = 'High Risk';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
