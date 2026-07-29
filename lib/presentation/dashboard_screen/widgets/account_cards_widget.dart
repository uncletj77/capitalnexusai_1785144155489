import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/cna_shared_components.dart';

class AccountCardsWidget extends StatefulWidget {
  const AccountCardsWidget({super.key});

  @override
  State<AccountCardsWidget> createState() => _AccountCardsWidgetState();
}

class _AccountCardsWidgetState extends State<AccountCardsWidget> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final accounts = await FinanceService.instance.getAccountsWithBalances();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  String _formatValue(double v) {
    if (v >= 1000000000) return 'TZS ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  Color _parseColor(String? hex) {
    return Color(
      int.tryParse((hex ?? '#1A5F7A').replaceFirst('#', '0xFF')) ?? 0xFF1A5F7A,
    );
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case 'bank':
        return 'BANK';
      case 'mobile_money':
        return 'MOBILE';
      case 'cash':
        return 'CASH';
      case 'investment':
        return 'INVEST';
      case 'other':
        return 'OTHER';
      default:
        return (cat ?? 'ACCOUNT').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: CnaLoadingState(message: '')),
      );
    }

    if (_accounts.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No accounts yet — add your first account',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedLight),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _accounts.length,
        itemBuilder: (context, i) {
          final account = _accounts[i];
          final balance =
              (account['calculated_balance'] as num?)?.toDouble() ?? 0;
          final color = _parseColor(account['color'] as String?);
          return _AccountCard(
            label: _categoryLabel(account['account_category'] as String?),
            name: account['account_name'] as String? ?? 'Account',
            formattedValue: _formatValue(balance),
            color: color,
            isPositive: balance >= 0,
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String label;
  final String name;
  final String formattedValue;
  final Color color;
  final bool isPositive;

  const _AccountCard({
    required this.label,
    required this.name,
    required this.formattedValue,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Simple static bar data for visual interest
    final trend = [8.0, 12.0, 10.0, 15.0, 11.0, 18.0, 14.0];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 30,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(show: false),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(trend.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: trend[i],
                        color: isPositive
                            ? color.withAlpha(179)
                            : AppTheme.mutedLight.withAlpha(128),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formattedValue,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.onSurfaceLight,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPositive ? AppTheme.success : AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
