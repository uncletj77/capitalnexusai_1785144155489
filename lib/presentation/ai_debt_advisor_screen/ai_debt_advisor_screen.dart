import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class AiDebtAdvisorScreen extends StatefulWidget {
  const AiDebtAdvisorScreen({super.key});

  @override
  State<AiDebtAdvisorScreen> createState() => _AiDebtAdvisorScreenState();
}

class _AiDebtAdvisorScreenState extends State<AiDebtAdvisorScreen> {
  final _client = SupabaseService.client;
  final _scrollController = ScrollController();
  final _messageCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isTyping = false;

  List<Map<String, dynamic>> _loans = [];
  Map<String, dynamic>? _healthSnapshot;
  double _monthlyIncome = 0;
  double _totalAssets = 0;

  final List<Map<String, String>> _messages = [];

  final List<String> _suggestedQuestions = [
    'How much debt do I have?',
    'Am I overleveraged?',
    'Which loan should I clear first?',
    'Can I afford another loan?',
    'What is my debt health score?',
    'How can I reduce my interest costs?',
  ];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final loansRes = await _client
          .from('loans')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active');
      final healthRes = await _client
          .from('debt_health_snapshots')
          .select()
          .eq('user_id', userId)
          .order('snapshot_date', ascending: false)
          .limit(1);
      final assetsRes = await _client
          .from('assets')
          .select('current_value')
          .eq('user_id', userId)
          .neq('asset_status', 'disposed');

      final now = DateTime.now();
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().split('T')[0];
      final txRes = await _client
          .from('financial_transactions')
          .select('amount, transaction_type')
          .eq('user_id', userId)
          .gte('transaction_date', monthStart);

      double income = 0;
      for (final t in txRes) {
        if (t['transaction_type'] == 'income') {
          income += (t['amount'] as num).toDouble();
        }
      }
      double assets = 0;
      for (final a in assetsRes) {
        assets += (a['current_value'] as num).toDouble();
      }

      setState(() {
        _loans = List<Map<String, dynamic>>.from(loansRes);
        _healthSnapshot = healthRes.isNotEmpty ? healthRes.first : null;
        _monthlyIncome = income > 0 ? income : 15500000;
        _totalAssets = assets > 0 ? assets : 850000000;
        _isLoading = false;
      });

      _addWelcomeMessage();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addWelcomeMessage() {
    final totalDebt = _loans.fold(
      0.0,
      (s, l) => s + (l['remaining_balance'] as num).toDouble(),
    );
    final score = _healthSnapshot?['debt_health_score'] as int? ?? 65;
    final risk = _healthSnapshot?['risk_level'] as String? ?? 'moderate';

    _messages.add({
      'role': 'assistant',
      'content':
          '👋 Hello! I\'m your AI Debt Advisor.\n\n'
          '📊 **Current Debt Overview:**\n'
          '• Total outstanding: TSh ${(totalDebt / 1000000).toStringAsFixed(1)}M\n'
          '• Active loans: ${_loans.length}\n'
          '• Debt health score: $score/100 (${risk.replaceAll('_', ' ')})\n\n'
          'Ask me anything about your debt position, affordability, or repayment strategy.',
    });
    setState(() {});
  }

  String _generateAIResponse(String question) {
    final q = question.toLowerCase();
    final totalDebt = _loans.fold(
      0.0,
      (s, l) => s + (l['remaining_balance'] as num).toDouble(),
    );
    final totalMonthly = _loans.fold(
      0.0,
      (s, l) => s + (l['monthly_payment'] as num).toDouble(),
    );
    final dti = _monthlyIncome > 0 ? totalMonthly / _monthlyIncome : 0.0;
    final dta = _totalAssets > 0 ? totalDebt / _totalAssets : 0.0;
    final score = _healthSnapshot?['debt_health_score'] as int? ?? 65;

    if (q.contains('how much debt') || q.contains('total debt')) {
      return '💰 **Your Total Debt Position:**\n\n'
          '• Total outstanding balance: TSh ${(totalDebt / 1000000).toStringAsFixed(2)}M\n'
          '• Active loans: ${_loans.length}\n'
          '• Monthly debt payments: TSh ${(totalMonthly / 1000).toStringAsFixed(0)}K\n\n'
          '${_loans.map((l) => '• ${l['loan_name']}: TSh ${((l['remaining_balance'] as num).toDouble() / 1000000).toStringAsFixed(1)}M').join('\n')}\n\n'
          '📈 Your debt-to-asset ratio is ${(dta * 100).toStringAsFixed(1)}%, which is ${dta < 0.20
              ? 'healthy'
              : dta < 0.40
              ? 'moderate'
              : 'high'}.';
    }

    if (q.contains('overleveraged') || q.contains('too much debt')) {
      final isOverleveraged = dti > 0.40 || dta > 0.40;
      return isOverleveraged
          ? '⚠️ **Overleveraged Analysis:**\n\n'
                'Based on your financial data:\n'
                '• DTI ratio: ${(dti * 100).toStringAsFixed(1)}% (threshold: 40%)\n'
                '• DTA ratio: ${(dta * 100).toStringAsFixed(1)}% (threshold: 40%)\n\n'
                '🔴 **You may be overleveraged.** Recommended actions:\n'
                '1. Prioritize clearing high-interest loans\n'
                '2. Avoid taking new debt until DTI drops below 35%\n'
                '3. Increase income streams to improve ratio'
          : '✅ **Leverage Analysis:**\n\n'
                '• DTI ratio: ${(dti * 100).toStringAsFixed(1)}% ✓ (healthy below 40%)\n'
                '• DTA ratio: ${(dta * 100).toStringAsFixed(1)}% ✓ (healthy below 40%)\n\n'
                '🟢 **You are not overleveraged.** Your debt levels are manageable relative to your income and assets.';
    }

    if (q.contains('which loan') ||
        q.contains('clear first') ||
        q.contains('pay first')) {
      if (_loans.isEmpty) return 'You have no active loans to prioritize.';
      final sorted = List<Map<String, dynamic>>.from(_loans)
        ..sort(
          (a, b) =>
              (b['interest_rate'] as num).compareTo(a['interest_rate'] as num),
        );
      final highest = sorted.first;
      return '🎯 **Debt Repayment Strategy:**\n\n'
          '**Avalanche Method (Recommended):**\n'
          'Clear the highest interest loan first to minimize total interest cost.\n\n'
          '🔴 **Priority 1:** ${highest['loan_name']}\n'
          '   Rate: ${(highest['interest_rate'] as num).toStringAsFixed(1)}% | Balance: TSh ${((highest['remaining_balance'] as num).toDouble() / 1000000).toStringAsFixed(1)}M\n\n'
          '${sorted.skip(1).take(3).map((l) => '• ${l['loan_name']}: ${(l['interest_rate'] as num).toStringAsFixed(1)}%').join('\n')}\n\n'
          '💡 Paying off the highest-rate loan first saves the most money in interest over time.';
    }

    if (q.contains('afford') ||
        q.contains('another loan') ||
        q.contains('new loan')) {
      final maxAffordable = (_monthlyIncome * 0.35 - totalMonthly).clamp(
        0.0,
        double.infinity,
      );
      return '🏦 **Loan Affordability Analysis:**\n\n'
          '• Monthly income: TSh ${(_monthlyIncome / 1000000).toStringAsFixed(1)}M\n'
          '• Current debt payments: TSh ${(totalMonthly / 1000).toStringAsFixed(0)}K\n'
          '• Current DTI: ${(dti * 100).toStringAsFixed(1)}%\n\n'
          '${maxAffordable > 0 ? '✅ **You can afford up to TSh ${(maxAffordable / 1000).toStringAsFixed(0)}K/month** in additional debt payments while staying within the 35% DTI threshold.\n\nUse the Loan Simulator to test specific scenarios.' : '⚠️ **Not recommended** to take new debt. Your DTI is already at ${(dti * 100).toStringAsFixed(1)}%. Focus on reducing existing debt first.'}';
    }

    if (q.contains('health score') || q.contains('debt score')) {
      return '📊 **Debt Health Score: $score/100**\n\n'
          '${score >= 70
              ? '🟢 Healthy'
              : score >= 50
              ? '🟡 Moderate'
              : '🔴 Needs Attention'}\n\n'
          '**Score Breakdown:**\n'
          '• DTI ratio (${(dti * 100).toStringAsFixed(1)}%): ${dti < 0.30
              ? '✅ Excellent'
              : dti < 0.40
              ? '⚠️ Moderate'
              : '❌ High'}\n'
          '• DTA ratio (${(dta * 100).toStringAsFixed(1)}%): ${dta < 0.20
              ? '✅ Excellent'
              : dta < 0.40
              ? '⚠️ Moderate'
              : '❌ High'}\n'
          '• Active loans: ${_loans.length} (${_loans.length <= 3 ? '✅ Manageable' : '⚠️ Many loans'})\n\n'
          '**To improve your score:**\n'
          '1. Reduce high-interest debt\n'
          '2. Increase income\n'
          '3. Avoid new consumer debt';
    }

    if (q.contains('interest') || q.contains('reduce') || q.contains('save')) {
      final highInterestLoans = _loans
          .where((l) => (l['interest_rate'] as num).toDouble() > 18)
          .toList();
      return '💡 **Interest Reduction Strategies:**\n\n'
          '${highInterestLoans.isNotEmpty ? '⚠️ High-interest loans detected:\n${highInterestLoans.map((l) => '• ${l['loan_name']}: ${(l['interest_rate'] as num).toStringAsFixed(1)}%').join('\n')}\n\n' : ''}'
          '**Recommended Actions:**\n'
          '1. 🎯 **Avalanche method**: Pay extra on highest-rate loans first\n'
          '2. 🔄 **Refinancing**: Explore lower rates from other lenders\n'
          '3. 💰 **Lump sum payments**: Use bonuses/windfalls to reduce principal\n'
          '4. 📅 **Bi-weekly payments**: Pay half monthly payment every 2 weeks (saves ~1 month/year)\n\n'
          'Use the Loan Simulator to calculate exact savings from extra payments.';
    }

    // Default response
    return '🤖 **AI Debt Analysis:**\n\n'
        'Based on your current debt profile:\n\n'
        '• Total debt: TSh ${(totalDebt / 1000000).toStringAsFixed(1)}M\n'
        '• Monthly payments: TSh ${(totalMonthly / 1000).toStringAsFixed(0)}K\n'
        '• Debt health score: $score/100\n'
        '• DTI ratio: ${(dti * 100).toStringAsFixed(1)}%\n\n'
        'Try asking me:\n'
        '• "Which loan should I clear first?"\n'
        '• "Am I overleveraged?"\n'
        '• "Can I afford another loan?"';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    final response = _generateAIResponse(text);
    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Debt Advisor',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Powered by CNA Brain',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const CnaLoadingState(message: 'Loading AI brain...')
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length +
                        (_isTyping ? 1 : 0) +
                        (_messages.isEmpty ? 0 : 1),
                    itemBuilder: (ctx, i) {
                      if (i == 0 && _messages.isNotEmpty) {
                        return _buildSuggestedQuestions(theme);
                      }
                      final msgIndex = i - 1;
                      if (_isTyping && msgIndex == _messages.length) {
                        return _buildTypingIndicator(theme);
                      }
                      if (msgIndex < 0 || msgIndex >= _messages.length) {
                        return const SizedBox.shrink();
                      }
                      final msg = _messages[msgIndex];
                      return _buildMessageBubble(theme, msg);
                    },
                  ),
                ),
                _buildInputBar(theme),
              ],
            ),
    );
  }

  Widget _buildSuggestedQuestions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Questions',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQuestions
                .map(
                  (q) => GestureDetector(
                    onTap: () => _sendMessage(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(40),
                        ),
                      ),
                      child: Text(
                        q,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildMessageBubble(ThemeData theme, Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.outlineLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg['content'] ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isUser ? Colors.white : AppTheme.onSurfaceLight,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.outlineLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology, color: AppTheme.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              'Analyzing your debt...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText: 'Ask about your debt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.outlineLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.outlineLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariantLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
}
