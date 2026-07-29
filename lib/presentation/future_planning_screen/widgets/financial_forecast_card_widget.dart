import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class FinancialForecastCardWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;
  final bool isFirst;

  const FinancialForecastCardWidget({
    super.key,
    required this.forecast,
    this.isFirst = false,
  });

  String _formatAmount(dynamic value) {
    final v = (value as num?)?.toDouble() ?? 0;
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  String _formatPeriod(String? period) {
    if (period == null) return '';
    final parts = period.split('-');
    if (parts.length < 2) return period;
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${m > 0 && m <= 12 ? months[m] : ''} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = forecast['confidence_score'] as int? ?? 0;
    final balance =
        (forecast['projected_cash_balance'] as num?)?.toDouble() ?? 0;
    final income =
        ((forecast['expected_income'] as num?)?.toDouble() ?? 0) +
        ((forecast['expected_business_income'] as num?)?.toDouble() ?? 0) +
        ((forecast['expected_investment_returns'] as num?)?.toDouble() ?? 0);
    final expenses =
        ((forecast['expected_expenses'] as num?)?.toDouble() ?? 0) +
        ((forecast['expected_loan_payments'] as num?)?.toDouble() ?? 0);
    final isPositive = balance >= 0;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isFirst
            ? const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFirst ? null : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isFirst ? null : Border.all(color: AppTheme.outlineLight),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPeriod(forecast['forecast_period'] as String?),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFirst ? Colors.white70 : AppTheme.mutedLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isFirst
                      ? Colors.white.withAlpha(30)
                      : AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$confidence%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isFirst ? Colors.white : AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatAmount(balance),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isFirst
                  ? Colors.white
                  : (isPositive ? AppTheme.success : AppTheme.error),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Projected Balance',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isFirst ? Colors.white60 : AppTheme.mutedLight,
            ),
          ),
          const SizedBox(height: 10),
          _row(
            '↑ Income',
            _formatAmount(income),
            isFirst ? Colors.white70 : AppTheme.success,
            isFirst,
          ),
          const SizedBox(height: 4),
          _row(
            '↓ Expenses',
            _formatAmount(expenses),
            isFirst ? Colors.white70 : AppTheme.error,
            isFirst,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor, bool isFirst) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isFirst ? Colors.white60 : AppTheme.mutedLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
