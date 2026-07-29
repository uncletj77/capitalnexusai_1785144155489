import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../services/finance_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AiInsightsWidget extends StatefulWidget {
  const AiInsightsWidget({super.key});

  @override
  State<AiInsightsWidget> createState() => _AiInsightsWidgetState();
}

class _AiInsightsWidgetState extends State<AiInsightsWidget> {
  List<Map<String, dynamic>> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  String _fmt(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final generated = <Map<String, dynamic>>[];

    try {
      // Load all data in parallel
      final results = await Future.wait([
        FinanceService.instance.getCashFlowSummary(),
        FinanceService.instance.getNetWorth(),
        FinanceService.instance.getBudgetsWithSpending(),
        _getLoansData(userId),
        _getAssetsData(userId),
        _getBusinessesData(userId),
        _getInvestmentsData(userId),
        FinanceService.instance.getRecentTransactions(limit: 30),
      ]);

      final cashFlow = results[0] as Map<String, double>;
      final netWorth = results[1] as Map<String, double>;
      final budgets = results[2] as List<Map<String, dynamic>>;
      final loans = results[3] as List<Map<String, dynamic>>;
      final assets = results[4] as List<Map<String, dynamic>>;
      final businesses = results[5] as List<Map<String, dynamic>>;
      final investments = results[6] as List<Map<String, dynamic>>;
      final recentTxns = results[7] as List<Map<String, dynamic>>;

      final income = cashFlow['income'] ?? 0;
      final expenses = cashFlow['expenses'] ?? 0;
      final net = cashFlow['net'] ?? 0;
      final nwValue = netWorth['netWorth'] ?? 0;

      // ── Insight 1: Cash Flow Health ──────────────────────────────────
      if (income > 0 || expenses > 0) {
        if (net > 0) {
          final rate = income > 0 ? (net / income * 100) : 0;
          generated.add({
            'title': 'Positive Cash Flow',
            'body':
                'This month you earned TZS ${_fmt(income)} and spent TZS ${_fmt(expenses)}. '
                'Net surplus: TZS ${_fmt(net)} (${rate.toStringAsFixed(0)}% savings rate).',
            'icon': 'trending_up',
            'color': const Color(0xFF10B981),
            'tag': 'Cash Flow',
          });
        } else if (net < 0) {
          generated.add({
            'title': 'Spending Exceeds Income',
            'body':
                'This month expenses (TZS ${_fmt(expenses)}) exceeded income (TZS ${_fmt(income)}) '
                'by TZS ${_fmt(net.abs())}. Review your budget.',
            'icon': 'trending_down',
            'color': const Color(0xFFEF4444),
            'tag': 'Alert',
          });
        }
      }

      // ── Insight 2: Net Worth ─────────────────────────────────────────
      if (nwValue != 0) {
        final assets_ = netWorth['assets'] ?? 0;
        final liab = netWorth['liabilities'] ?? 0;
        generated.add({
          'title': 'Net Worth Summary',
          'body':
              'Your net worth is TZS ${_fmt(nwValue)}. '
              'Assets: TZS ${_fmt(assets_)} | Liabilities: TZS ${_fmt(liab)}.',
          'icon': 'account_balance_wallet',
          'color': const Color(0xFF2D9CDB),
          'tag': 'Wealth',
        });
      }

      // ── Insight 3: Overdue Loans ─────────────────────────────────────
      final now = DateTime.now();
      final overdueLoans = loans.where((l) {
        final dueStr = l['next_payment_date'] as String?;
        if (dueStr == null) return false;
        final due = DateTime.tryParse(dueStr);
        return due != null && due.isBefore(now);
      }).toList();

      final upcomingLoans = loans.where((l) {
        final dueStr = l['next_payment_date'] as String?;
        if (dueStr == null) return false;
        final due = DateTime.tryParse(dueStr);
        return due != null &&
            due.isAfter(now) &&
            due.isBefore(now.add(const Duration(days: 7)));
      }).toList();

      if (overdueLoans.isNotEmpty) {
        final totalOverdue = overdueLoans.fold<double>(
          0,
          (s, l) => s + ((l['monthly_payment'] as num?)?.toDouble() ?? 0),
        );
        generated.add({
          'title': '${overdueLoans.length} Loan(s) Overdue',
          'body':
              '${overdueLoans.length} loan repayment(s) are past due. '
              'Total overdue: TZS ${_fmt(totalOverdue)}. Take action now.',
          'icon': 'credit_score',
          'color': const Color(0xFFEF4444),
          'tag': 'Alert',
        });
      } else if (upcomingLoans.isNotEmpty) {
        final totalDue = upcomingLoans.fold<double>(
          0,
          (s, l) => s + ((l['monthly_payment'] as num?)?.toDouble() ?? 0),
        );
        generated.add({
          'title': 'Loan Payment Due Soon',
          'body':
              '${upcomingLoans.length} loan payment(s) due within 7 days. '
              'Amount: TZS ${_fmt(totalDue)}.',
          'icon': 'credit_score',
          'color': const Color(0xFFF59E0B),
          'tag': 'Reminder',
        });
      }

      // ── Insight 4: Budget Alerts ─────────────────────────────────────
      final overBudget = budgets
          .where((b) => b['is_over_budget'] == true)
          .toList();
      final nearLimit = budgets.where((b) {
        final progress = (b['progress'] as double?) ?? 0;
        return progress >= 0.85 && progress < 1.0;
      }).toList();

      if (overBudget.isNotEmpty) {
        generated.add({
          'title': '${overBudget.length} Budget(s) Exceeded',
          'body':
              'You have exceeded your budget in ${overBudget.length} categor${overBudget.length == 1 ? 'y' : 'ies'}: '
              '${overBudget.take(2).map((b) => b['name'] ?? b['category']).join(', ')}.',
          'icon': 'pie_chart',
          'color': const Color(0xFFEF4444),
          'tag': 'Budget',
        });
      } else if (nearLimit.isNotEmpty) {
        generated.add({
          'title': 'Budget Nearly Exhausted',
          'body':
              '${nearLimit.length} budget(s) are over 85% used this month: '
              '${nearLimit.take(2).map((b) => b['name'] ?? b['category']).join(', ')}.',
          'icon': 'pie_chart',
          'color': const Color(0xFFF59E0B),
          'tag': 'Budget',
        });
      }

      // ── Insight 5: Business Performance ─────────────────────────────
      if (businesses.isNotEmpty) {
        final totalRevenue = businesses.fold<double>(
          0,
          (s, b) => s + ((b['monthly_revenue'] as num?)?.toDouble() ?? 0),
        );
        if (totalRevenue > 0) {
          generated.add({
            'title':
                '${businesses.length} Active Business${businesses.length == 1 ? '' : 'es'}',
            'body':
                'Your ${businesses.length} business${businesses.length == 1 ? '' : 'es'} generated '
                'TZS ${_fmt(totalRevenue)} in revenue this month.',
            'icon': 'business',
            'color': const Color(0xFF8B5CF6),
            'tag': 'Business',
          });
        } else {
          generated.add({
            'title':
                '${businesses.length} Business${businesses.length == 1 ? '' : 'es'} Registered',
            'body':
                'You have ${businesses.length} registered business${businesses.length == 1 ? '' : 'es'}. '
                'Add transactions to track revenue and expenses.',
            'icon': 'business',
            'color': const Color(0xFF8B5CF6),
            'tag': 'Business',
          });
        }
      }

      // ── Insight 6: Investment Portfolio ─────────────────────────────
      if (investments.isNotEmpty) {
        final totalValue = investments.fold<double>(
          0,
          (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0),
        );
        final totalCost = investments.fold<double>(
          0,
          (s, i) => s + ((i['purchase_price'] as num?)?.toDouble() ?? 0),
        );
        final gain = totalValue - totalCost;
        if (totalValue > 0) {
          generated.add({
            'title': 'Investment Portfolio',
            'body': gain >= 0
                ? 'Portfolio value: TZS ${_fmt(totalValue)}. '
                      'Unrealized gain: TZS ${_fmt(gain)} across ${investments.length} investment${investments.length == 1 ? '' : 's'}.'
                : 'Portfolio value: TZS ${_fmt(totalValue)}. '
                      'Unrealized loss: TZS ${_fmt(gain.abs())} — review your positions.',
            'icon': 'show_chart',
            'color': gain >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            'tag': 'Investment',
          });
        }
      }

      // ── Insight 7: Asset Portfolio ───────────────────────────────────
      if (assets.isNotEmpty) {
        final totalAssetValue = assets.fold<double>(
          0,
          (s, a) => s + ((a['current_value'] as num?)?.toDouble() ?? 0),
        );
        if (totalAssetValue > 0) {
          generated.add({
            'title':
                '${assets.length} Asset${assets.length == 1 ? '' : 's'} in Portfolio',
            'body':
                'Total asset value: TZS ${_fmt(totalAssetValue)} across '
                '${assets.length} asset${assets.length == 1 ? '' : 's'}.',
            'icon': 'home_work',
            'color': const Color(0xFF2D9CDB),
            'tag': 'Assets',
          });
        }
      }

      // ── Insight 8: Spending Pattern ──────────────────────────────────
      if (recentTxns.isNotEmpty) {
        final expenseTxns = recentTxns
            .where((t) => t['transaction_type'] == 'expense')
            .toList();
        if (expenseTxns.isNotEmpty) {
          final catMap = <String, double>{};
          for (final t in expenseTxns) {
            final cat = t['category'] as String? ?? 'other';
            catMap[cat] =
                (catMap[cat] ?? 0) + ((t['amount'] as num).toDouble());
          }
          final topCat = catMap.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
          generated.add({
            'title': 'Top Spending Category',
            'body':
                'Your highest expense this month is "${_formatCategory(topCat.key)}" '
                'at TZS ${_fmt(topCat.value)}.',
            'icon': 'receipt_long',
            'color': const Color(0xFFF59E0B),
            'tag': 'Spending',
          });
        }
      }

      // ── Insight 9: Savings Opportunity ──────────────────────────────
      if (income > 0 && net > 0 && investments.isEmpty) {
        generated.add({
          'title': 'Investment Opportunity',
          'body':
              'You have a monthly surplus of TZS ${_fmt(net)}. '
              'Consider starting an investment to grow your wealth.',
          'icon': 'savings',
          'color': const Color(0xFF10B981),
          'tag': 'Opportunity',
        });
      }
    } catch (_) {
      // Silently fail — show empty state
    }

    if (mounted) {
      setState(() {
        _insights = generated;
        _isLoading = false;
      });
    }
  }

  String _formatCategory(String cat) {
    return cat
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<List<Map<String, dynamic>>> _getLoansData(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('user_loans')
          .select(
            'id, loan_name, outstanding_balance, monthly_payment, next_payment_date, loan_status',
          )
          .eq('user_id', userId)
          .eq('loan_status', 'active');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAssetsData(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('assets')
          .select('id, asset_name, current_value, asset_type')
          .eq('user_id', userId)
          .neq('asset_status', 'disposed');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getBusinessesData(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('businesses')
          .select('id, name, monthly_revenue')
          .eq('user_id', userId)
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getInvestmentsData(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('user_investments')
          .select('id, investment_name, current_value, purchase_price')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go(AppRoutes.aiAssistantScreen),
                child: Text(
                  'Ask AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 240,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          )
        else if (_insights.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: [
                  const CustomIconWidget(
                    iconName: 'auto_awesome',
                    color: AppTheme.mutedLight,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No insights yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add transactions, assets, or businesses to get personalized AI insights.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _insights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final insight = _insights[i];
                return GestureDetector(
                  onTap: () => context.go(AppRoutes.aiAssistantScreen),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: (insight['color'] as Color).withAlpha(
                                  20,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: insight['icon'] as String,
                                  color: insight['color'] as Color,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                insight['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (insight['color'] as Color).withAlpha(
                                  20,
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                insight['tag'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: insight['color'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            insight['body'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
