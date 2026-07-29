import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AiInvestmentAdvisorScreen extends StatefulWidget {
  const AiInvestmentAdvisorScreen({super.key});

  @override
  State<AiInvestmentAdvisorScreen> createState() =>
      _AiInvestmentAdvisorScreenState();
}

class _AiInvestmentAdvisorScreenState extends State<AiInvestmentAdvisorScreen> {
  final _client = SupabaseService.client;
  final _scrollController = ScrollController();
  final _inputCtrl = TextEditingController();
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _investments = [];
  bool _dataLoaded = false;

  final List<String> _quickQuestions = [
    'How are my investments performing?',
    'Which investment gives the highest return?',
    'Am I taking too much risk?',
    'Which investment should I exit?',
    'How can I grow my wealth in 10 years?',
    'What is my portfolio concentration risk?',
  ];

  @override
  void initState() {
    super.initState();
    _loadInvestmentData();
    _messages.add({
      'role': 'assistant',
      'content':
          '👋 Hello! I\'m your AI Investment Advisor. I have access to your portfolio data and can help you understand your investments, analyze risks, and make smarter financial decisions.\n\nWhat would you like to know about your investments?',
    });
  }

  Future<void> _loadInvestmentData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _client
          .from('investments')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true)
          .order('current_value', ascending: false);
      setState(() {
        _investments = List<Map<String, dynamic>>.from(res);
        _dataLoaded = true;
      });
    } catch (_) {}
  }

  String _buildPortfolioContext() {
    if (_investments.isEmpty) return 'No investment data available.';

    double totalInvested = 0, currentValue = 0;
    final Map<String, double> catAlloc = {};

    for (final inv in _investments) {
      final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
      final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
      totalInvested += initial;
      currentValue += current;
      final cat = inv['category'] as String? ?? 'other';
      catAlloc[cat] = (catAlloc[cat] ?? 0) + current;
    }

    final profit = currentValue - totalInvested;
    final roi = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;

    final invList = _investments
        .map((inv) {
          final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
          final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
          final invRoi = initial > 0
              ? ((current - initial) / initial) * 100
              : 0.0;
          return '- ${inv['name']} (${inv['category']}): Initial TSh ${(initial / 1000000).toStringAsFixed(1)}M → Current TSh ${(current / 1000000).toStringAsFixed(1)}M, ROI: ${invRoi.toStringAsFixed(1)}%, Risk: ${inv['risk_level']}';
        })
        .join('\n');

    final allocStr = catAlloc.entries
        .map(
          (e) =>
              '${e.key}: ${currentValue > 0 ? ((e.value / currentValue) * 100).toStringAsFixed(0) : 0}%',
        )
        .join(', ');

    return '''
Portfolio Summary:
- Total Invested: TSh ${(totalInvested / 1000000).toStringAsFixed(1)}M
- Current Value: TSh ${(currentValue / 1000000).toStringAsFixed(1)}M
- Total Profit: TSh ${(profit / 1000000).toStringAsFixed(1)}M
- Overall ROI: ${roi.toStringAsFixed(1)}%
- Investments: ${_investments.length}
- Allocation: $allocStr

Individual Investments:
$invList
''';
  }

  String _generateAiResponse(String question) {
    final q = question.toLowerCase();
    final ctx = _buildPortfolioContext();

    double totalInvested = 0, currentValue = 0;
    for (final inv in _investments) {
      totalInvested += (inv['initial_value'] as num?)?.toDouble() ?? 0;
      currentValue += (inv['current_value'] as num?)?.toDouble() ?? 0;
    }
    final profit = currentValue - totalInvested;
    final roi = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;

    // Best performer
    Map<String, dynamic>? best;
    double bestRoi = -999;
    for (final inv in _investments) {
      final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
      final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
      final r = initial > 0 ? ((current - initial) / initial) * 100 : 0.0;
      if (r > bestRoi) {
        bestRoi = r;
        best = inv;
      }
    }

    // Worst performer
    Map<String, dynamic>? worst;
    double worstRoi = 999;
    for (final inv in _investments) {
      final initial = (inv['initial_value'] as num?)?.toDouble() ?? 0;
      final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
      final r = initial > 0 ? ((current - initial) / initial) * 100 : 0.0;
      if (r < worstRoi) {
        worstRoi = r;
        worst = inv;
      }
    }

    // Category concentration
    final Map<String, double> catAlloc = {};
    for (final inv in _investments) {
      final cat = inv['category'] as String? ?? 'other';
      catAlloc[cat] =
          (catAlloc[cat] ?? 0) +
          ((inv['current_value'] as num?)?.toDouble() ?? 0);
    }
    String topCat = '';
    double topPct = 0;
    for (final e in catAlloc.entries) {
      final pct = currentValue > 0 ? (e.value / currentValue) * 100 : 0.0;
      if (pct > topPct) {
        topPct = pct;
        topCat = e.key;
      }
    }

    if (q.contains('performing') ||
        q.contains('performance') ||
        q.contains('how are')) {
      return '''📊 **Portfolio Performance Summary**

Your portfolio is currently ${roi >= 0 ? 'performing well' : 'under pressure'}.

• **Total Invested**: TSh ${(totalInvested / 1000000).toStringAsFixed(1)}M
• **Current Value**: TSh ${(currentValue / 1000000).toStringAsFixed(1)}M  
• **Total ${profit >= 0 ? 'Profit' : 'Loss'}**: TSh ${(profit.abs() / 1000000).toStringAsFixed(1)}M
• **Overall ROI**: ${roi.toStringAsFixed(1)}%

${best != null ? '🏆 Best performer: **${best['name']}** with ${bestRoi.toStringAsFixed(1)}% ROI' : ''}
${worst != null && worstRoi < 0 ? '⚠️ Underperformer: **${worst['name']}** at ${worstRoi.toStringAsFixed(1)}% ROI' : ''}

${roi > 15 ? '✅ Your portfolio is outperforming the average market return of 10–12%.' : '💡 Consider reviewing underperforming investments to improve overall returns.'}''';
    }

    if (q.contains('highest return') ||
        q.contains('best investment') ||
        q.contains('best performer')) {
      if (best == null) return 'No investment data available.';
      return '''🏆 **Best Performing Investment**

**${best['name']}** (${best['category']}) is your top performer.

• **Initial Capital**: TSh ${((best['initial_value'] as num?)?.toDouble() ?? 0) ~/ 1000000}M
• **Current Value**: TSh ${((best['current_value'] as num?)?.toDouble() ?? 0) ~/ 1000000}M
• **ROI**: ${bestRoi.toStringAsFixed(1)}%
• **Risk Level**: ${best['risk_level']}

💡 This investment demonstrates strong returns. Consider whether you can increase your exposure while managing risk appropriately.''';
    }

    if (q.contains('risk') ||
        q.contains('risky') ||
        q.contains('too much risk')) {
      final highRisk = _investments
          .where(
            (i) => i['risk_level'] == 'high' || i['risk_level'] == 'very_high',
          )
          .length;
      return '''🛡️ **Risk Analysis**

Portfolio risk assessment:

• **High/Very High Risk Investments**: $highRisk of ${_investments.length}
• **Concentration**: ${topPct.toStringAsFixed(0)}% in ${topCat.replaceAll('_', ' ')}

${topPct > 60 ? '⚠️ **Concentration Risk**: Over 60% of your portfolio is in one category. Diversification is recommended.' : '✅ Your portfolio is reasonably diversified.'}

${highRisk > _investments.length / 2 ? '⚠️ More than half your investments carry high risk. Consider balancing with stable, income-generating assets.' : '✅ Your risk distribution is acceptable.'}

**Recommendation**: Maintain a mix of low-risk (real estate, bonds) and growth assets (business, digital) for optimal risk-adjusted returns.''';
    }

    if (q.contains('exit') ||
        q.contains('sell') ||
        q.contains('should i exit')) {
      if (worst == null) return 'No investment data to analyze.';
      return '''🚪 **Exit Decision Analysis**

Based on your portfolio performance:

${worstRoi < 0 ? '⚠️ **Consider Exiting**: **${worst['name']}** is currently at ${worstRoi.toStringAsFixed(1)}% ROI. If the outlook remains negative, exiting and reinvesting elsewhere may be wise.' : '✅ All your investments are currently profitable. No immediate exit is recommended.'}

**Exit Decision Framework**:
1. If ROI < -10% with no recovery path → Consider exit
2. If better opportunities exist → Compare opportunity cost
3. If concentration risk is high → Partial exit to rebalance
4. If exit date is approaching → Plan orderly exit strategy

💡 Use the Investment Simulator to model exit vs. hold scenarios.''';
    }

    if (q.contains('10 years') ||
        q.contains('future') ||
        q.contains('grow') ||
        q.contains('wealth')) {
      final avgReturn = _investments.isNotEmpty
          ? _investments.fold<double>(
                  0,
                  (s, i) =>
                      s +
                      ((i['expected_return_rate'] as num?)?.toDouble() ?? 12),
                ) /
                _investments.length
          : 12.0;
      double fv = currentValue;
      for (int i = 0; i < 10; i++) {
        fv *= (1 + avgReturn / 100);
      }
      return '''🔮 **10-Year Wealth Projection**

Based on your current portfolio and average expected return of ${avgReturn.toStringAsFixed(1)}%:

• **Current Portfolio Value**: TSh ${(currentValue / 1000000).toStringAsFixed(1)}M
• **Projected Value in 10 Years**: TSh ${(fv / 1000000).toStringAsFixed(1)}M
• **Projected Growth**: TSh ${((fv - currentValue) / 1000000).toStringAsFixed(1)}M

**To accelerate growth**:
1. 💰 Reinvest all distributions and dividends
2. 📈 Add regular monthly contributions
3. 🔄 Rebalance annually to maintain target allocation
4. 🎯 Focus on investments with 15%+ annual returns

💡 Use the Investment Simulator to model different contribution scenarios.''';
    }

    if (q.contains('concentration') || q.contains('diversif')) {
      return '''📊 **Portfolio Concentration Analysis**

Your current allocation:
${catAlloc.entries.map((e) => '• ${e.key.replaceAll('_', ' ')}: ${currentValue > 0 ? ((e.value / currentValue) * 100).toStringAsFixed(0) : 0}%').join('\n')}

${topPct > 60 ? '⚠️ **High Concentration**: ${topPct.toStringAsFixed(0)}% in ${topCat.replaceAll('_', ' ')} exceeds the recommended 40% maximum for any single category.' : '✅ Your portfolio concentration is within acceptable limits.'}

**Recommended Allocation**:
• Real Estate: 30–40%
• Business: 20–30%
• Stocks/Bonds: 15–25%
• Agriculture: 10–15%
• Digital Assets: 5–10%

💡 Rebalancing towards this target will reduce concentration risk while maintaining growth potential.''';
    }

    // Default response
    return '''🤖 **AI Investment Analysis**

Based on your portfolio data:

${ctx.split('\n').take(8).join('\n')}

**Key Insights**:
• Your portfolio has ${roi >= 0 ? 'generated positive returns' : 'experienced losses'} of ${roi.toStringAsFixed(1)}%
• ${best != null ? 'Top performer: ${best['name']} (${bestRoi.toStringAsFixed(1)}% ROI)' : ''}
• ${topPct > 60 ? 'Concentration risk: ${topPct.toStringAsFixed(0)}% in ${topCat.replaceAll('_', ' ')}' : 'Portfolio is reasonably diversified'}

Feel free to ask specific questions about performance, risk, exit decisions, or future projections!''';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final question = text.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': question});
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 800));

    final response = _generateAiResponse(question);

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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF9B51E0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Investment Advisor',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _dataLoaded
                      ? '${_investments.length} investments analyzed'
                      : 'Loading portfolio...',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => context.push(AppRoutes.investmentSimulatorScreen),
            tooltip: 'Simulator',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_isTyping && i == _messages.length) {
                  return _buildTypingIndicator(theme);
                }
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return _buildMessage(theme, msg['content'] as String, isUser);
              },
            ),
          ),
          if (_messages.length <= 2) _buildQuickQuestions(theme),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildMessage(ThemeData theme, String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1A5F7A)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          content,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: isUser ? Colors.white : theme.colorScheme.onSurface,
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
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Color(0xFF1A5F7A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Analyzing...',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions(ThemeData theme) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickQuestions.length,
        itemBuilder: (ctx, i) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickQuestions[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5F7A).withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1A5F7A).withAlpha(50),
                ),
              ),
              child: Text(
                _quickQuestions[i],
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF1A5F7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              decoration: InputDecoration(
                hintText: 'Ask about your investments...',
                hintStyle: GoogleFonts.manrope(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(60),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(60),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }
}