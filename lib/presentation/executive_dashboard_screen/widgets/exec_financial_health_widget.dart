import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ExecFinancialHealthWidget extends StatelessWidget {
  final Map<String, dynamic> kpiData;

  const ExecFinancialHealthWidget({required this.kpiData, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = (kpiData['monthlyIncome'] as double?) ?? 0;
    final expenses = (kpiData['monthlyExpenses'] as double?) ?? 0;
    final netWorth = (kpiData['netWorth'] as double?) ?? 0;
    final totalLiabilities = (kpiData['totalLiabilities'] as double?) ?? 0;
    final totalAssets = (kpiData['totalAssets'] as double?) ?? 0;
    final savings = (kpiData['save'] as double?) ?? 0;

    // Calculate health scores
    final savingsRate = income > 0
        ? (savings / income * 100).clamp(0, 100)
        : 0.0;
    final debtRatio = totalAssets > 0
        ? (totalLiabilities / totalAssets * 100).clamp(0, 100)
        : 0.0;
    final profitMargin = income > 0
        ? ((income - expenses) / income * 100).clamp(0, 100)
        : 0.0;
    final liquidityScore = income > 0
        ? ((kpiData['availableCash'] as double? ?? 0) / income * 100).clamp(
            0,
            100,
          )
        : 0.0;

    // Overall health score (0-100)
    final healthScore =
        ((savingsRate * 0.3) +
                ((100 - debtRatio) * 0.3) +
                (profitMargin * 0.2) +
                (liquidityScore.clamp(0, 100) * 0.2))
            .clamp(0, 100);

    final healthLabel = healthScore >= 80
        ? 'Excellent'
        : healthScore >= 60
        ? 'Good'
        : healthScore >= 40
        ? 'Fair'
        : 'Needs Attention';
    final healthColor = healthScore >= 80
        ? AppTheme.success
        : healthScore >= 60
        ? AppTheme.primaryLight
        : healthScore >= 40
        ? AppTheme.warning
        : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Score',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          healthScore.toStringAsFixed(0),
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: healthColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 2),
                          child: Text(
                            '/100',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: healthColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        healthLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: healthColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: healthScore / 100,
                      strokeWidth: 8,
                      backgroundColor: theme.colorScheme.outline.withAlpha(60),
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                    Text(
                      '${healthScore.toStringAsFixed(0)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Health Indicators
          _healthIndicator(
            context,
            'Savings Rate',
            savingsRate.toDouble(),
            100,
            '${savingsRate.toStringAsFixed(1)}%',
            AppTheme.success,
          ),
          const SizedBox(height: 10),
          _healthIndicator(
            context,
            'Debt Ratio',
            (100 - debtRatio).toDouble(),
            100,
            '${debtRatio.toStringAsFixed(1)}%',
            debtRatio > 50 ? AppTheme.danger : AppTheme.warning,
          ),
          const SizedBox(height: 10),
          _healthIndicator(
            context,
            'Profit Margin',
            profitMargin.toDouble(),
            100,
            '${profitMargin.toStringAsFixed(1)}%',
            AppTheme.primaryLight,
          ),
          const SizedBox(height: 10),
          _healthIndicator(
            context,
            'Liquidity',
            liquidityScore.clamp(0, 100).toDouble(),
            100,
            '${liquidityScore.toStringAsFixed(1)}%',
            const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }

  Widget _healthIndicator(
    BuildContext context,
    String label,
    double value,
    double max,
    String displayValue,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              displayValue,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0, 1),
            backgroundColor: theme.colorScheme.outline.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
