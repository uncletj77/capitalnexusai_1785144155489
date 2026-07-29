import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/decision_engine_service.dart';

/// Scenario Builder Widget — allows users to create and configure decision scenarios
class ScenarioBuilderWidget extends ConsumerStatefulWidget {
  final VoidCallback? onScenarioCreated;

  const ScenarioBuilderWidget({super.key, this.onScenarioCreated});

  @override
  ConsumerState<ScenarioBuilderWidget> createState() =>
      _ScenarioBuilderWidgetState();
}

class _ScenarioBuilderWidgetState extends ConsumerState<ScenarioBuilderWidget> {
  String _selectedCategory = 'asset_purchase';
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCreating = false;

  // Dynamic inputs per category
  final Map<String, List<Map<String, dynamic>>> _categoryInputTemplates = {
    'asset_purchase': [
      {'name': 'Purchase Price', 'type': 'amount', 'hint': 'e.g. 80000000'},
      {'name': 'Down Payment', 'type': 'amount', 'hint': 'e.g. 30000000'},
      {'name': 'Loan Amount', 'type': 'amount', 'hint': 'e.g. 50000000'},
      {'name': 'Interest Rate (%)', 'type': 'percentage', 'hint': 'e.g. 18'},
      {'name': 'Loan Duration (months)', 'type': 'months', 'hint': 'e.g. 36'},
      {
        'name': 'Expected Monthly Income',
        'type': 'amount',
        'hint': 'e.g. 6000000',
      },
      {
        'name': 'Monthly Operating Costs',
        'type': 'amount',
        'hint': 'e.g. 1500000',
      },
    ],
    'loan': [
      {'name': 'Loan Amount', 'type': 'amount', 'hint': 'e.g. 50000000'},
      {'name': 'Interest Rate (%)', 'type': 'percentage', 'hint': 'e.g. 18'},
      {'name': 'Loan Duration (months)', 'type': 'months', 'hint': 'e.g. 36'},
      {'name': 'Monthly Income', 'type': 'amount', 'hint': 'e.g. 8000000'},
    ],
    'business_expansion': [
      {'name': 'Expansion Cost', 'type': 'amount', 'hint': 'e.g. 120000000'},
      {
        'name': 'Expected Revenue Increase',
        'type': 'amount',
        'hint': 'e.g. 10000000',
      },
      {
        'name': 'Additional Monthly Expenses',
        'type': 'amount',
        'hint': 'e.g. 3000000',
      },
      {'name': 'Additional Employees', 'type': 'count', 'hint': 'e.g. 2'},
    ],
    'investment': [
      {'name': 'Investment Amount', 'type': 'amount', 'hint': 'e.g. 50000000'},
      {
        'name': 'Expected Annual Return (%)',
        'type': 'percentage',
        'hint': 'e.g. 15',
      },
      {'name': 'Investment Period (years)', 'type': 'years', 'hint': 'e.g. 5'},
      {'name': 'Risk Level', 'type': 'scale', 'hint': '1-5 (1=low, 5=high)'},
    ],
    'financial_survival': [
      {'name': 'Current Savings', 'type': 'amount', 'hint': 'e.g. 20000000'},
      {'name': 'Monthly Expenses', 'type': 'amount', 'hint': 'e.g. 4000000'},
      {
        'name': 'Monthly Debt Payments',
        'type': 'amount',
        'hint': 'e.g. 1500000',
      },
    ],
  };

  late Map<String, TextEditingController> _inputControllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _inputControllers = {};
    final templates = _categoryInputTemplates[_selectedCategory] ?? [];
    for (final t in templates) {
      _inputControllers[t['name'] as String] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    setState(() {
      _selectedCategory = category;
      _initControllers();
    });
  }

  Future<void> _createAndSimulate() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a scenario name',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isCreating = true);

    final service = DecisionEngineService.instance;

    // Create scenario
    final scenarioId = await service.createScenario(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
    );

    if (scenarioId == null) {
      setState(() => _isCreating = false);
      Fluttertoast.showToast(
        msg: 'Failed to create scenario',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Save inputs
    final templates = _categoryInputTemplates[_selectedCategory] ?? [];
    final inputs = templates.map((t) {
      final name = t['name'] as String;
      final value = double.tryParse(_inputControllers[name]?.text ?? '') ?? 0;
      return {
        'input_name': name,
        'input_value': value,
        'input_type': t['type'],
      };
    }).toList();

    await service.saveScenarioInputs(scenarioId, inputs);

    // Run simulation
    await service.runSimulation(scenarioId);

    setState(() => _isCreating = false);

    Fluttertoast.showToast(
      msg: 'Scenario created and simulated!',
      backgroundColor: AppTheme.success,
    );

    ref.invalidate(decisionScenariosProvider);
    widget.onScenarioCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _categoryInputTemplates[_selectedCategory] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'add_chart',
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Decision Scenario',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  Text(
                    'Test a financial decision before making it',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scenario Name
          _buildLabel('Scenario Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('e.g. Buy Transport Bus'),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Category Selector
          _buildLabel('Decision Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DecisionEngineService.categoryLabels.entries.map((e) {
              final isSelected = _selectedCategory == e.key;
              return GestureDetector(
                onTap: () => _onCategoryChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName:
                            DecisionEngineService.categoryIcons[e.key] ??
                            'lightbulb',
                        color: isSelected ? Colors.white : AppTheme.mutedLight,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        e.value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
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
          const SizedBox(height: 16),

          // Description
          _buildLabel('Description (Optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: _inputDecoration(
              'Describe what you want to evaluate...',
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Dynamic Inputs
          _buildLabel('Scenario Inputs'),
          const SizedBox(height: 10),
          ...templates.map((t) {
            final name = t['name'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _inputControllers[name],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(t['hint'] as String),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Create & Simulate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createAndSimulate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomIconWidget(
                          iconName: 'play_arrow',
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create & Run Simulation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.onSurfaceLight,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: AppTheme.mutedLight,
    ),
    filled: true,
    fillColor: AppTheme.surfaceVariantLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
    ),
  );
}
