import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/cna_shared_components.dart';

/// Debt Health Score Widget — dynamically calculated from Finance Engine
class DebtHealthWidget extends StatefulWidget {
  const DebtHealthWidget({super.key});

  @override
  State<DebtHealthWidget> createState() => _DebtHealthWidgetState();
}

class _DebtHealthWidgetState extends State<DebtHealthWidget> {
  bool _isLoading = true;
  double _healthScore = 0;
  String _riskLevel = 'Unknown';
  Color _riskColor = AppTheme.mutedLight;
  List<Map<String, String>> _factors = [];
  String _trend = 'stable';
  String _aiRecommendation = '';

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() => _isLoading = true);
    try {
      final fs = FinanceService.instance;
      final results = await Future.wait([
        fs.getNetWorth(),
        fs.getCashFlowSummary(),
        fs.getLoansReceivable(),
      ]);

      final nw = results[0] as Map<String, double>;
      final cf = results[1] as Map<String, double>;
      final receivables = results[2] as List<Map<String, dynamic>>;

      final totalAssets = nw['assets'] ?? 0;
      final totalLiabilities = nw['liabilities'] ?? 0;
      final monthlyIncome = cf['income'] ?? 0;
      final monthlyExpenses = cf['expenses'] ?? 0;

      // Fetch active loans for overdue check
      double overdueAmount = 0;
      double activeLoansBalance = totalLiabilities;
      double receivableBalance = 0;

      for (final r in receivables) {
        if (r['loan_status'] == 'overdue') {
          overdueAmount += (r['remaining_balance'] as num?)?.toDouble() ?? 0;
        }
        if ([
          'active',
          'partially_paid',
          'overdue',
        ].contains(r['loan_status'])) {
          receivableBalance +=
              (r['remaining_balance'] as num?)?.toDouble() ?? 0;
        }
      }

      // Calculate health score (0-100)
      double score = 100;
      final factors = <Map<String, String>>[];

      // Debt-to-asset ratio (max 40 points deduction)
      if (totalAssets > 0) {
        final dtar = totalLiabilities / totalAssets;
        if (dtar > 0.8) {
          score -= 40;
          factors.add({
            'label': 'High debt-to-asset ratio',
            'impact': 'negative',
            'value': '${(dtar * 100).toStringAsFixed(0)}%',
          });
        } else if (dtar > 0.5) {
          score -= 20;
          factors.add({
            'label': 'Moderate debt-to-asset ratio',
            'impact': 'warning',
            'value': '${(dtar * 100).toStringAsFixed(0)}%',
          });
        } else if (dtar > 0) {
          factors.add({
            'label': 'Healthy debt-to-asset ratio',
            'impact': 'positive',
            'value': '${(dtar * 100).toStringAsFixed(0)}%',
          });
        }
      }

      // Debt-to-income ratio (max 30 points deduction)
      if (monthlyIncome > 0) {
        final dti = totalLiabilities / (monthlyIncome * 12);
        if (dti > 3) {
          score -= 30;
          factors.add({
            'label': 'Debt exceeds 3x annual income',
            'impact': 'negative',
            'value': '${dti.toStringAsFixed(1)}x',
          });
        } else if (dti > 1.5) {
          score -= 15;
          factors.add({
            'label': 'Debt-to-income elevated',
            'impact': 'warning',
            'value': '${dti.toStringAsFixed(1)}x',
          });
        } else if (monthlyIncome > 0) {
          factors.add({
            'label': 'Debt-to-income manageable',
            'impact': 'positive',
            'value': '${dti.toStringAsFixed(1)}x',
          });
        }
      }

      // Overdue loans (max 20 points deduction)
      if (overdueAmount > 0) {
        score -= 20;
        factors.add({
          'label': 'Overdue loan receivables',
          'impact': 'negative',
          'value': _fmt(overdueAmount),
        });
      }

      // Cash reserves vs monthly expenses (max 10 points deduction)
      if (monthlyExpenses > 0) {
        final cashReserves = totalAssets - totalLiabilities;
        final monthsCovered = cashReserves / monthlyExpenses;
        if (monthsCovered < 1) {
          score -= 10;
          factors.add({
            'label': 'Low cash reserves',
            'impact': 'negative',
            'value': '${monthsCovered.toStringAsFixed(1)} months',
          });
        } else if (monthsCovered >= 3) {
          factors.add({
            'label': 'Strong cash reserves',
            'impact': 'positive',
            'value': '${monthsCovered.toStringAsFixed(1)} months',
          });
        }
      }

      // Loan receivables as asset (positive factor)
      if (receivableBalance > 0) {
        factors.add({
          'label': 'Loan receivables as assets',
          'impact': 'positive',
          'value': _fmt(receivableBalance),
        });
      }

      score = score.clamp(0, 100);

      String riskLevel;
      Color riskColor;
      String recommendation;
      if (score >= 80) {
        riskLevel = 'Excellent';
        riskColor = const Color(0xFF27AE60);
        recommendation =
            'Your debt health is excellent. Consider investing surplus cash for higher returns.';
      } else if (score >= 60) {
        riskLevel = 'Good';
        riskColor = const Color(0xFF2D9CDB);
        recommendation =
            'Debt health is good. Focus on reducing high-interest loans to improve further.';
      } else if (score >= 40) {
        riskLevel = 'Fair';
        riskColor = const Color(0xFFF2994A);
        recommendation =
            'Moderate debt risk. Prioritize loan repayments and avoid new debt.';
      } else if (score >= 20) {
        riskLevel = 'Poor';
        riskColor = const Color(0xFFE53E3E);
        recommendation =
            'High debt risk. Seek debt consolidation and reduce discretionary spending immediately.';
      } else {
        riskLevel = 'Critical';
        riskColor = const Color(0xFF9B2335);
        recommendation =
            'Critical debt situation. Consider professional financial counseling urgently.';
      }

      if (mounted) {
        setState(() {
          _healthScore = score;
          _riskLevel = riskLevel;
          _riskColor = riskColor;
          _factors = factors;
          _aiRecommendation = recommendation;
          _trend = totalLiabilities == 0
              ? 'stable'
              : (score >= 60 ? 'improving' : 'declining');
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.go(AppRoutes.loanDashboardScreen),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Debt Health Score',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: _trend == 'improving'
                            ? 'trending_up'
                            : _trend == 'declining'
                            ? 'trending_down'
                            : 'trending_flat',
                        color: _riskColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _trend.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const SizedBox(
                height: 120,
                child: Center(
                  child: CnaLoadingState(message: 'Calculating...'),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 32,
                            sections: [
                              PieChartSectionData(
                                value: _healthScore,
                                color: _riskColor,
                                radius: 16,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: 100 - _healthScore,
                                color: AppTheme.outlineLight,
                                radius: 14,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_healthScore.toInt()}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _riskColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _riskColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _riskLevel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _riskColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._factors
                            .take(3)
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: f['impact'] == 'positive'
                                          ? 'check_circle'
                                          : f['impact'] == 'warning'
                                          ? 'warning'
                                          : 'cancel',
                                      color: f['impact'] == 'positive'
                                          ? const Color(0xFF27AE60)
                                          : f['impact'] == 'warning'
                                          ? const Color(0xFFF2994A)
                                          : const Color(0xFFE53E3E),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        f['label'] ?? '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.mutedLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            if (!_isLoading && _aiRecommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'psychology',
                      color: AppTheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiRecommendation,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurfaceLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
