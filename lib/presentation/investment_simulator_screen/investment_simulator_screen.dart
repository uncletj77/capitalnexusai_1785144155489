import 'package:flutter/material.dart';

import '../../core/app_export.dart';

class InvestmentSimulatorScreen extends StatefulWidget {
  const InvestmentSimulatorScreen({super.key});

  @override
  State<InvestmentSimulatorScreen> createState() =>
      _InvestmentSimulatorScreenState();
}

class _InvestmentSimulatorScreenState extends State<InvestmentSimulatorScreen> {
  int _selectedScenario = 0;

  // Scenario 1 – New Investment
  final _newAmountCtrl = TextEditingController(text: '50000000');
  final _newReturnCtrl = TextEditingController(text: '15');
  final _newYearsCtrl = TextEditingController(text: '5');
  String _newRisk = 'medium';

  // Scenario 2 – Additional Capital
  final _baseAmountCtrl = TextEditingController(text: '100000000');
  final _monthlyAddCtrl = TextEditingController(text: '5000000');
  final _addReturnCtrl = TextEditingController(text: '12');
  final _addYearsCtrl = TextEditingController(text: '10');

  // Scenario 3 – Exit Decision
  final _exitInitialCtrl = TextEditingController(text: '45000000');
  final _exitCurrentCtrl = TextEditingController(text: '72000000');
  final _exitFutureReturnCtrl = TextEditingController(text: '15');
  final _exitYearsCtrl = TextEditingController(text: '3');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Investment Simulator',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildScenarioTabs(theme),
          Expanded(
            child: IndexedStack(
              index: _selectedScenario,
              children: [
                _buildNewInvestmentScenario(theme),
                _buildAdditionalCapitalScenario(theme),
                _buildExitDecisionScenario(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioTabs(ThemeData theme) {
    final tabs = ['New Investment', 'Add Capital', 'Exit Decision'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isSelected = e.key == _selectedScenario;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedScenario = e.key),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A5F7A)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewInvestmentScenario(ThemeData theme) {
    final amount = double.tryParse(_newAmountCtrl.text) ?? 0;
    final rate = double.tryParse(_newReturnCtrl.text) ?? 0;
    final years = int.tryParse(_newYearsCtrl.text) ?? 5;

    // Compound growth
    final futureValue = amount * (1 + rate / 100).toDouble().pow(years);
    final totalProfit = futureValue - amount;
    final roi = amount > 0 ? (totalProfit / amount) * 100 : 0.0;

    // Yearly projections
    final projections = List.generate(years, (i) {
      final yr = i + 1;
      return amount * (1 + rate / 100).toDouble().pow(yr);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scenarioHeader(
            theme,
            'New Investment Scenario',
            'If I invest this amount, what can happen?',
            Icons.add_circle_outline,
            const Color(0xFF1A5F7A),
          ),
          const SizedBox(height: 16),
          _simField(theme, 'Investment Amount (TSh)', _newAmountCtrl),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Expected Annual Return (%)',
            _newReturnCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Investment Period (Years)',
            _newYearsCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _sectionLabel(theme, 'Risk Level'),
          const SizedBox(height: 8),
          Row(
            children: ['low', 'medium', 'high'].map((r) {
              final isSelected = _newRisk == r;
              final colors = {
                'low': const Color(0xFF27AE60),
                'medium': const Color(0xFFF2994A),
                'high': const Color(0xFFEB5757),
              };
              final color = colors[r]!;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _newRisk = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(25)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : theme.colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      r[0].toUpperCase() + r.substring(1),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildResultCard(theme, [
            _resultRow(
              theme,
              'Future Value',
              'TSh ${(futureValue / 1000000).toStringAsFixed(1)}M',
              const Color(0xFF1A5F7A),
            ),
            _resultRow(
              theme,
              'Total Profit',
              'TSh ${(totalProfit / 1000000).toStringAsFixed(1)}M',
              const Color(0xFF27AE60),
            ),
            _resultRow(
              theme,
              'Total ROI',
              '${roi.toStringAsFixed(1)}%',
              const Color(0xFF27AE60),
            ),
            _resultRow(
              theme,
              'Investment Period',
              '$years years',
              theme.colorScheme.onSurface,
            ),
          ]),
          const SizedBox(height: 16),
          Text(
            'Year-by-Year Projection',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...projections.asMap().entries.map((e) {
            final yr = e.key + 1;
            final val = e.value;
            final profit = val - amount;
            return _projectionRow(
              theme,
              'Year $yr',
              'TSh ${(val / 1000000).toStringAsFixed(1)}M',
              '+TSh ${(profit / 1000000).toStringAsFixed(1)}M',
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAdditionalCapitalScenario(ThemeData theme) {
    final base = double.tryParse(_baseAmountCtrl.text) ?? 0;
    final monthly = double.tryParse(_monthlyAddCtrl.text) ?? 0;
    final rate = double.tryParse(_addReturnCtrl.text) ?? 0;
    final years = int.tryParse(_addYearsCtrl.text) ?? 10;
    final monthlyRate = rate / 100 / 12;
    final months = years * 12;

    // Future value of lump sum
    final fvLump = base * (1 + rate / 100).toDouble().pow(years);
    // Future value of monthly contributions (annuity)
    final fvAnnuity = monthlyRate > 0
        ? monthly *
              ((((1 + monthlyRate).toDouble().pow(months)) - 1) / monthlyRate)
        : monthly * months;
    final totalFuture = fvLump + fvAnnuity;
    final totalContributed = base + (monthly * months);
    final totalProfit = totalFuture - totalContributed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scenarioHeader(
            theme,
            'Additional Capital Scenario',
            'What if I add money every month?',
            Icons.savings,
            const Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 16),
          _simField(theme, 'Current Portfolio Value (TSh)', _baseAmountCtrl),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Monthly Addition (TSh)',
            _monthlyAddCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Expected Annual Return (%)',
            _addReturnCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Investment Period (Years)',
            _addYearsCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildResultCard(theme, [
            _resultRow(
              theme,
              'Future Portfolio Value',
              'TSh ${(totalFuture / 1000000).toStringAsFixed(1)}M',
              const Color(0xFF2D9CDB),
            ),
            _resultRow(
              theme,
              'Total Contributed',
              'TSh ${(totalContributed / 1000000).toStringAsFixed(1)}M',
              theme.colorScheme.onSurface,
            ),
            _resultRow(
              theme,
              'Total Growth',
              'TSh ${(totalProfit / 1000000).toStringAsFixed(1)}M',
              const Color(0xFF27AE60),
            ),
            _resultRow(
              theme,
              'Monthly Addition',
              'TSh ${(monthly / 1000).toStringAsFixed(0)}K',
              theme.colorScheme.onSurface,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2D9CDB).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D9CDB).withAlpha(50)),
            ),
            child: Text(
              '💡 By adding TSh ${(monthly / 1000).toStringAsFixed(0)}K monthly for $years years at ${rate.toStringAsFixed(0)}% annual return, your portfolio grows from TSh ${(base / 1000000).toStringAsFixed(1)}M to TSh ${(totalFuture / 1000000).toStringAsFixed(1)}M — a ${totalContributed > 0 ? ((totalProfit / totalContributed) * 100).toStringAsFixed(0) : 0}% total return on contributions.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExitDecisionScenario(ThemeData theme) {
    final initial = double.tryParse(_exitInitialCtrl.text) ?? 0;
    final current = double.tryParse(_exitCurrentCtrl.text) ?? 0;
    final futureRate = double.tryParse(_exitFutureReturnCtrl.text) ?? 0;
    final years = int.tryParse(_exitYearsCtrl.text) ?? 3;

    final currentProfit = current - initial;
    final currentRoi = initial > 0 ? (currentProfit / initial) * 100 : 0.0;
    final futureValue = current * (1 + futureRate / 100).toDouble().pow(years);
    final futureProfit = futureValue - initial;
    final futureRoi = initial > 0 ? (futureProfit / initial) * 100 : 0.0;

    final shouldHold = futureRoi > currentRoi * 1.3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scenarioHeader(
            theme,
            'Exit Decision Scenario',
            'Should I sell this investment now?',
            Icons.exit_to_app,
            const Color(0xFFF2994A),
          ),
          const SizedBox(height: 16),
          _simField(theme, 'Initial Investment (TSh)', _exitInitialCtrl),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Current Value (TSh)',
            _exitCurrentCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Expected Future Annual Return (%)',
            _exitFutureReturnCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _simField(
            theme,
            'Hold Period (Years)',
            _exitYearsCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _exitOptionCard(
                  theme,
                  'Exit Now',
                  _formatCurrency(current),
                  'Profit: ${_formatCurrency(currentProfit)}',
                  'ROI: ${currentRoi.toStringAsFixed(1)}%',
                  !shouldHold,
                  const Color(0xFFEB5757),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _exitOptionCard(
                  theme,
                  'Hold $years Years',
                  _formatCurrency(futureValue),
                  'Profit: ${_formatCurrency(futureProfit)}',
                  'ROI: ${futureRoi.toStringAsFixed(1)}%',
                  shouldHold,
                  const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: shouldHold
                  ? const Color(0xFF27AE60).withAlpha(15)
                  : const Color(0xFFEB5757).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: shouldHold
                    ? const Color(0xFF27AE60).withAlpha(50)
                    : const Color(0xFFEB5757).withAlpha(50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  shouldHold ? Icons.trending_up : Icons.sell,
                  color: shouldHold
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFEB5757),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shouldHold
                        ? '🤖 AI Recommendation: HOLD. Holding for $years more years could increase your value by ${_formatCurrency(futureValue - current)} (${((futureValue - current) / current * 100).toStringAsFixed(0)}% additional growth).'
                        : '🤖 AI Recommendation: Consider EXIT. Current gains are strong. Reinvest proceeds into higher-return opportunities.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _exitOptionCard(
    ThemeData theme,
    String title,
    String value,
    String profit,
    String roi,
    bool isRecommended,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRecommended
            ? color.withAlpha(20)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended
              ? color
              : theme.colorScheme.outline.withAlpha(40),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'RECOMMENDED',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          if (isRecommended) const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isRecommended ? color : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            profit,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            roi,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scenarioHeader(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Results',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _resultRow(
    ThemeData theme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectionRow(
    ThemeData theme,
    String year,
    String value,
    String growth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            year,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            growth,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF27AE60),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _simField(
    ThemeData theme,
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(theme, label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(60),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(60),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'TSh ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'TSh ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _newAmountCtrl.dispose();
    _newReturnCtrl.dispose();
    _newYearsCtrl.dispose();
    _baseAmountCtrl.dispose();
    _monthlyAddCtrl.dispose();
    _addReturnCtrl.dispose();
    _addYearsCtrl.dispose();
    _exitInitialCtrl.dispose();
    _exitCurrentCtrl.dispose();
    _exitFutureReturnCtrl.dispose();
    _exitYearsCtrl.dispose();
    super.dispose();
  }
}

extension _NumPow on double {
  double pow(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= this;
    }
    return result;
  }
}
