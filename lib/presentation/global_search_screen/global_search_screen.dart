import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final res = await client.rpc(
        'global_search',
        params: {'p_user_id': userId, 'p_query': query.trim()},
      );

      final results = (res as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });
      }
    }
  }

  String _fmt(double? v) {
    if (v == null || v == 0) return '';
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  Map<String, dynamic> _typeConfig(String type) {
    switch (type) {
      case 'transaction':
        return {
          'icon': 'receipt_long',
          'color': const Color(0xFF27AE60),
          'label': 'Transaction',
        };
      case 'asset':
        return {
          'icon': 'real_estate_agent',
          'color': const Color(0xFF4BB8A0),
          'label': 'Asset',
        };
      case 'business':
        return {
          'icon': 'business_center',
          'color': const Color(0xFF2980B9),
          'label': 'Business',
        };
      case 'investment':
        return {
          'icon': 'trending_up',
          'color': const Color(0xFF1A5F7A),
          'label': 'Investment',
        };
      case 'loan':
        return {
          'icon': 'account_balance',
          'color': const Color(0xFFF2994A),
          'label': 'Loan',
        };
      case 'loan_receivable':
        return {
          'icon': 'payments',
          'color': const Color(0xFF9B59B6),
          'label': 'Receivable',
        };
      default:
        return {'icon': 'search', 'color': AppTheme.primary, 'label': type};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => _search(v),
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search transactions, assets, businesses...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.mutedLight,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = [];
                  _hasSearched = false;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
          ? _buildSearchHints(context)
          : _results.isEmpty
          ? _buildNoResults(context)
          : _buildResults(context),
    );
  }

  Widget _buildSearchHints(BuildContext context) {
    final theme = Theme.of(context);
    final hints = [
      {
        'icon': 'receipt_long',
        'label': 'Transactions',
        'route': AppRoutes.transactionHistoryScreen,
      },
      {
        'icon': 'real_estate_agent',
        'label': 'Assets',
        'route': AppRoutes.assetDashboardScreen,
      },
      {
        'icon': 'business_center',
        'label': 'Businesses',
        'route': AppRoutes.businessDashboardScreen,
      },
      {
        'icon': 'trending_up',
        'label': 'Investments',
        'route': AppRoutes.investmentDashboardScreen,
      },
      {
        'icon': 'account_balance',
        'label': 'Loans',
        'route': AppRoutes.loanDashboardScreen,
      },
      {
        'icon': 'payments',
        'label': 'Loan Receivables',
        'route': AppRoutes.loansReceivableScreen,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Modules',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.mutedLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: hints
                .map(
                  (h) => GestureDetector(
                    onTap: () => context.go(h['route'] as String),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: h['icon'] as String,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            h['label'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceLight,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: AppTheme.mutedLight,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);

    // Group by type
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _results) {
      final type = r['result_type'] as String? ?? 'other';
      grouped.putIfAbsent(type, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_results.length} result${_results.length != 1 ? 's' : ''} for "${_controller.text}"',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          final config = _typeConfig(entry.key);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: config['icon'] as String,
                      color: config['color'] as Color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      config['label'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: config['color'] as Color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineLight),
                ),
                child: Column(
                  children: List.generate(entry.value.length, (i) {
                    final item = entry.value[i];
                    final route =
                        item['route'] as String? ?? AppRoutes.dashboardScreen;
                    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                    final amtStr = _fmt(amount);

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => context.go(route),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (config['color'] as Color).withAlpha(
                                      20,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: config['icon'] as String,
                                      color: config['color'] as Color,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String? ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurfaceLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item['subtitle'] != null)
                                        Text(
                                          (item['subtitle'] as String)
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppTheme.mutedLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (amtStr.isNotEmpty)
                                  Text(
                                    amtStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: config['color'] as Color,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (i < entry.value.length - 1)
                          Divider(height: 1, color: AppTheme.outlineLight),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }
}
