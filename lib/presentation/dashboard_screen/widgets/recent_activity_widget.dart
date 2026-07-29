import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/finance_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/cna_shared_components.dart';
import '../../../routes/app_routes.dart';

class RecentActivityWidget extends StatefulWidget {
  const RecentActivityWidget({super.key});

  @override
  State<RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<RecentActivityWidget> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load from multiple sources in parallel
      final results = await Future.wait([
        FinanceService.instance.getRecentTransactions(limit: 10),
        _getBusinessActivities(userId),
        _getAssetActivities(userId),
        _getInvestmentActivities(userId),
        _getLoanActivities(userId),
      ]);

      final txns = results[0];
      final bizActivities = results[1];
      final assetActivities = results[2];
      final investActivities = results[3];
      final loanActivities = results[4];

      final all = <Map<String, dynamic>>[];

      for (final t in txns) {
        all.add({
          'type': 'transaction',
          'subtype': t['transaction_type'] ?? 'other',
          'title': t['description'] ?? t['category'] ?? 'Transaction',
          'subtitle': (t['category'] as String? ?? 'other')
              .replaceAll('_', ' ')
              .toUpperCase(),
          'amount': (t['amount'] as num?)?.toDouble() ?? 0,
          'isPositive': t['transaction_type'] == 'income',
          'date':
              t['transaction_date'] as String? ??
              t['created_at'] as String? ??
              '',
          'icon': _categoryIcon(t['category'] as String?),
          'color': t['transaction_type'] == 'income'
              ? const Color(0xFF27AE60)
              : const Color(0xFFE53E3E),
        });
      }

      for (final b in bizActivities) {
        all.add({
          'type': 'business',
          'subtype': 'business',
          'title': b['title'] as String? ?? 'Business Activity',
          'subtitle': 'BUSINESS',
          'amount': (b['amount'] as num?)?.toDouble() ?? 0,
          'isPositive': (b['amount'] as num?)?.toDouble() ?? 0 >= 0,
          'date': b['date'] as String? ?? '',
          'icon': 'business_center',
          'color': const Color(0xFF2980B9),
        });
      }

      for (final a in assetActivities) {
        all.add({
          'type': 'asset',
          'subtype': 'asset',
          'title': a['title'] as String? ?? 'Asset Activity',
          'subtitle': 'ASSET',
          'amount': (a['amount'] as num?)?.toDouble() ?? 0,
          'isPositive': true,
          'date': a['date'] as String? ?? '',
          'icon': 'real_estate_agent',
          'color': const Color(0xFF4BB8A0),
        });
      }

      for (final i in investActivities) {
        all.add({
          'type': 'investment',
          'subtype': 'investment',
          'title': i['title'] as String? ?? 'Investment Update',
          'subtitle': 'INVESTMENT',
          'amount': (i['amount'] as num?)?.toDouble() ?? 0,
          'isPositive': true,
          'date': i['date'] as String? ?? '',
          'icon': 'trending_up',
          'color': const Color(0xFF1A5F7A),
        });
      }

      for (final l in loanActivities) {
        all.add({
          'type': 'loan',
          'subtype': 'loan',
          'title': l['title'] as String? ?? 'Loan Activity',
          'subtitle': 'LOAN',
          'amount': (l['amount'] as num?)?.toDouble() ?? 0,
          'isPositive': false,
          'date': l['date'] as String? ?? '',
          'icon': 'account_balance',
          'color': const Color(0xFFF2994A),
        });
      }

      // Sort by date descending
      all.sort((a, b) {
        final da = a['date'] as String;
        final db = b['date'] as String;
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _activities = all.take(20).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getBusinessActivities(
    String userId,
  ) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('business_transactions')
          .select('description, amount, transaction_date, transaction_type')
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .limit(5);
      return (res as List)
          .map(
            (r) => {
              'title': r['description'] ?? 'Business Transaction',
              'amount': r['amount'],
              'date': r['transaction_date'] ?? '',
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAssetActivities(String userId) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('assets')
          .select('asset_name, current_value, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(3);
      return (res as List)
          .map(
            (r) => {
              'title': 'Asset: ${r['asset_name'] ?? 'Unknown'}',
              'amount': r['current_value'],
              'date': (r['updated_at'] as String? ?? '').split('T')[0],
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getInvestmentActivities(
    String userId,
  ) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('investments')
          .select('investment_name, current_value, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(3);
      return (res as List)
          .map(
            (r) => {
              'title': 'Investment: ${r['investment_name'] ?? 'Unknown'}',
              'amount': r['current_value'],
              'date': (r['updated_at'] as String? ?? '').split('T')[0],
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLoanActivities(String userId) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('loan_repayments')
          .select('amount, payment_date, notes')
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(3);
      return (res as List)
          .map(
            (r) => {
              'title': 'Loan Repayment',
              'amount': r['amount'],
              'date': r['payment_date'] ?? '',
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _activities;
    if (_filterType != 'all') {
      list = list.where((a) => a['type'] == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (a) =>
                (a['title'] as String).toLowerCase().contains(q) ||
                (a['subtitle'] as String).toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  String _formatAmount(double amount, bool isIncome) {
    final prefix = isIncome ? '+' : '-';
    if (amount >= 1000000) {
      return '$prefix TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$prefix TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$prefix TZS ${amount.toStringAsFixed(0)}';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return '1d ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }

  String _categoryIcon(String? category) {
    const icons = {
      'business': 'business_center',
      'rental': 'apartment',
      'investment': 'trending_up',
      'dividends': 'show_chart',
      'salary': 'wallet',
      'consulting': 'work',
      'freelance': 'laptop',
      'food': 'restaurant',
      'transport': 'directions_car',
      'fuel': 'local_gas_station',
      'utilities': 'bolt',
      'housing': 'home',
      'healthcare': 'local_hospital',
      'education': 'school',
      'entertainment': 'movie',
      'salaries': 'people',
      'loan_payment': 'account_balance',
      'insurance': 'shield',
      'maintenance': 'build',
      'marketing': 'campaign',
      'subscriptions': 'subscriptions',
      'taxes': 'receipt_long',
      'loan_given': 'payments',
      'loan_repayment_received': 'payments',
    };
    return icons[category?.toLowerCase()] ?? 'receipt';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.transactionHistoryScreen),
                child: Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search activity...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedLight),
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.mutedLight,
                  size: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    'all',
                    'transaction',
                    'business',
                    'asset',
                    'investment',
                    'loan',
                  ].map((f) {
                    final selected = _filterType == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filterType = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f == 'all'
                              ? 'All'
                              : f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const CnaLoadingState(message: 'Loading activity...')
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'receipt_long',
                    color: AppTheme.mutedLight,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No results found'
                        : 'No activity yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add transactions to see your activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: List.generate(filtered.length, (i) {
                  final item = filtered[i];
                  final isPositive = item['isPositive'] as bool;
                  final amount = item['amount'] as double;
                  final color = item['color'] as Color;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withAlpha(18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: item['icon'] as String,
                                  color: color,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurfaceLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppTheme.mutedLight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(amount, isPositive),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  _timeAgo(item['date'] as String?),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.mutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i < filtered.length - 1)
                        Divider(height: 1, color: AppTheme.outlineLight),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
