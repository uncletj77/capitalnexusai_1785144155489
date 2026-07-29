import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class ExecAiBriefingWidget extends StatelessWidget {
  final Map<String, dynamic> kpiData;

  const ExecAiBriefingWidget({required this.kpiData, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = (kpiData['monthlyIncome'] as double?) ?? 0;
    final expenses = (kpiData['monthlyExpenses'] as double?) ?? 0;
    final netWorth = (kpiData['netWorth'] as double?) ?? 0;
    final totalLiabilities = (kpiData['totalLiabilities'] as double?) ?? 0;
    final savings = (kpiData['save'] as double?) ?? 0;
    final netProfit = income - expenses;

    final insights = _generateInsights(
      income: income,
      expenses: expenses,
      netWorth: netWorth,
      totalLiabilities: totalLiabilities,
      savings: savings,
      netProfit: netProfit,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(15),
            AppTheme.primaryLight.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const CustomIconWidget(
                  iconName: 'psychology',
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Executive Briefing',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Based on your live financial data',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Live Analysis',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightItem(context, insight)),
        ],
      ),
    );
  }

  List<_AiInsight> _generateInsights({
    required double income,
    required double expenses,
    required double netWorth,
    required double totalLiabilities,
    required double savings,
    required double netProfit,
  }) {
    final insights = <_AiInsight>[];

    if (income == 0 && expenses == 0 && netWorth == 0) {
      insights.add(
        _AiInsight(
          type: 'info',
          title: 'Getting Started',
          message:
              'Start by adding your accounts, recording transactions, and registering your assets to unlock personalized AI financial insights.',
          icon: 'info_outline',
        ),
      );
      return insights;
    }

    // Net worth insight
    if (netWorth > 0) {
      insights.add(
        _AiInsight(
          type: 'success',
          title: 'Positive Net Worth',
          message:
              'Your net worth is positive at ${_fmt(netWorth)}. Your assets exceed your liabilities, indicating a healthy financial foundation.',
          icon: 'trending_up',
        ),
      );
    } else if (netWorth < 0) {
      insights.add(
        _AiInsight(
          type: 'warning',
          title: 'Net Worth Alert',
          message:
              'Your liabilities currently exceed your assets by ${_fmt(netWorth.abs())}. Focus on debt reduction and asset accumulation.',
          icon: 'warning_amber',
        ),
      );
    }

    // Cash flow insight
    if (netProfit > 0) {
      final margin = income > 0 ? (netProfit / income * 100) : 0;
      insights.add(
        _AiInsight(
          type: 'success',
          title: 'Positive Cash Flow',
          message:
              'You are generating ${_fmt(netProfit)} in monthly profit with a ${margin.toStringAsFixed(1)}% margin. Consider allocating surplus to investments.',
          icon: 'account_balance_wallet',
        ),
      );
    } else if (netProfit < 0 && income > 0) {
      insights.add(
        _AiInsight(
          type: 'danger',
          title: 'Expense Overrun',
          message:
              'Monthly expenses exceed income by ${_fmt(netProfit.abs())}. Review variable expenses and identify cost reduction opportunities.',
          icon: 'error_outline',
        ),
      );
    }

    // Debt insight
    if (totalLiabilities > 0) {
      final debtToIncome = income > 0 ? totalLiabilities / income : 0;
      if (debtToIncome > 36) {
        insights.add(
          _AiInsight(
            type: 'warning',
            title: 'High Debt Load',
            message:
                'Your debt-to-income ratio is elevated. Consider accelerating repayments on high-interest obligations to improve financial flexibility.',
            icon: 'credit_score',
          ),
        );
      }
    }

    // Savings insight
    if (savings > 0 && income > 0) {
      final savingsRate = savings / income * 100;
      if (savingsRate >= 20) {
        insights.add(
          _AiInsight(
            type: 'success',
            title: 'Strong Savings Rate',
            message:
                'Your savings rate of ${savingsRate.toStringAsFixed(1)}% exceeds the recommended 20% threshold. Excellent financial discipline.',
            icon: 'savings',
          ),
        );
      } else {
        insights.add(
          _AiInsight(
            type: 'info',
            title: 'Savings Opportunity',
            message:
                'Your current savings rate is ${savingsRate.toStringAsFixed(1)}%. Targeting 20% of income for savings would significantly accelerate wealth building.',
            icon: 'lightbulb_outline',
          ),
        );
      }
    }

    return insights.take(3).toList();
  }

  Widget _buildInsightItem(BuildContext context, _AiInsight insight) {
    final theme = Theme.of(context);
    final color = insight.type == 'success'
        ? AppTheme.success
        : insight.type == 'warning'
        ? AppTheme.warning
        : insight.type == 'danger'
        ? AppTheme.danger
        : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: insight.icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.message,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000000) return 'TZS ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }
}

class _AiInsight {
  final String type;
  final String title;
  final String message;
  final String icon;
  const _AiInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
  });
}
