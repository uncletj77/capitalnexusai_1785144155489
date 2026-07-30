import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AiBusinessAdvisorScreen extends StatefulWidget {
  final Map<String, dynamic>? business;
  const AiBusinessAdvisorScreen({super.key, this.business});

  @override
  State<AiBusinessAdvisorScreen> createState() =>
      _AiBusinessAdvisorScreenState();
}

class _AiBusinessAdvisorScreenState extends State<AiBusinessAdvisorScreen> {
  final _client = SupabaseService.client;
  final _scrollController = ScrollController();
  final _inputCtrl = TextEditingController();
  bool _isThinking = false;
  Map<String, dynamic>? _activeBusiness;

  double _totalRevenue = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  int _employeeCount = 0;
  int _branchCount = 0;
  int _healthScore = 0;
  List<Map<String, dynamic>> _topExpenses = [];

  final List<Map<String, dynamic>> _messages = [];

  final _quickQuestions = [
    'How is my business performing?',
    'Where am I losing money?',
    'Which branch is best?',
    'Should I expand?',
    'How can I increase revenue?',
    'Am I overspending on salaries?',
    'What is my profit margin?',
    'Should I hire more staff?',
  ];

  @override
  void initState() {
    super.initState();
    _activeBusiness = widget.business;
    _loadBusinessData();
    _messages.add({
      'role': 'ai',
      'text':
          'Hello! I am your AI Business Advisor. I have analyzed your business data and I am ready to provide strategic insights.\n\nYou can ask me anything about your business performance, profitability, growth opportunities, or strategic decisions.',
      'time': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      if (_activeBusiness == null) {
        final biz = await _client
            .from('businesses')
            .select()
            .eq('owner_id', userId)
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();
        _activeBusiness = biz;
      }
      if (_activeBusiness == null) return;

      final bizId = _activeBusiness!['id'] as String;
      final now = DateTime.now();
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      ).toIso8601String().split('T')[0];

      final results = await Future.wait(<Future<dynamic>>[
        _client
            .from('business_transactions')
            .select()
            .eq('business_id', bizId)
            .gte('transaction_date', monthStart),
        _client
            .from('business_employees')
            .select()
            .eq('business_id', bizId)
            .eq('emp_status', 'active'),
        _client
            .from('business_branches')
            .select()
            .eq('business_id', bizId)
            .eq('is_active', true),
        _client
            .from('business_kpis')
            .select()
            .eq('business_id', bizId)
            .order('kpi_date', ascending: false)
            .limit(10),
      ]);

      final txList = List<Map<String, dynamic>>.from(results[0]);
      final empList = List<Map<String, dynamic>>.from(results[1]);
      final branchList = List<Map<String, dynamic>>.from(results[2]);
      final kpiList = List<Map<String, dynamic>>.from(results[3]);

      double rev = 0, exp = 0;
      final Map<String, double> expByCategory = {};
      for (final t in txList) {
        final amt = (t['amount'] as num).toDouble();
        if (t['transaction_type'] == 'revenue') rev += amt;
        if (t['transaction_type'] == 'expense') {
          exp += amt;
          final cat = t['category'] as String;
          expByCategory[cat] = (expByCategory[cat] ?? 0) + amt;
        }
      }

      final sortedExp = expByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topExp = sortedExp
          .take(3)
          .map((e) => {'category': e.key, 'amount': e.value})
          .toList();

      int score = 0;
      for (final k in kpiList) {
        if (k['metric'] == 'health_score') {
          score = (k['value'] as num).toInt();
          break;
        }
      }
      if (score == 0 && rev > 0) {
        score = ((rev - exp) / rev * 100).clamp(0, 100).toInt();
      }

      setState(() {
        _totalRevenue = rev;
        _totalExpenses = exp;
        _netProfit = rev - exp;
        _employeeCount = empList.length;
        _branchCount = branchList.length;
        _healthScore = score;
        _topExpenses = topExp;
      });
    } catch (_) {}
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'TSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'TSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text.trim(),
        'time': DateTime.now(),
      });
      _isThinking = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    final response = _generateResponse(text.toLowerCase());

    setState(() {
      _messages.add({'role': 'ai', 'text': response, 'time': DateTime.now()});
      _isThinking = false;
    });
    _scrollToBottom();
  }

  String _generateResponse(String query) {
    final bizName = _activeBusiness?['name'] as String? ?? 'your business';
    final margin = _totalRevenue > 0
        ? ((_netProfit / _totalRevenue) * 100)
        : 0.0;

    if (query.contains('perform') ||
        query.contains('how is') ||
        query.contains('health')) {
      return '📊 Business Performance Analysis — $bizName\n\n'
          '• Health Score: $_healthScore/100 — ${_healthScore >= 80
              ? 'Excellent'
              : _healthScore >= 60
              ? 'Good'
              : 'Needs Attention'}\n'
          '• Monthly Revenue: ${_fmt(_totalRevenue)}\n'
          '• Monthly Expenses: ${_fmt(_totalExpenses)}\n'
          '• Net Profit: ${_fmt(_netProfit)}\n'
          '• Profit Margin: ${margin.toStringAsFixed(1)}%\n'
          '• Active Employees: $_employeeCount\n'
          '• Operating Branches: $_branchCount\n\n'
          '${_netProfit > 0 ? '✅ The business is profitable. Focus on scaling revenue streams while controlling costs.' : '⚠️ The business is currently at a loss. Immediate cost review is recommended.'}';
    }

    if (query.contains('losing') ||
        query.contains('loss') ||
        query.contains('expense') ||
        query.contains('cost')) {
      final expStr = _topExpenses
          .map(
            (e) =>
                '• ${e['category']}: ${_fmt((e['amount'] as num).toDouble())}',
          )
          .join('\n');
      return '💸 Expense Analysis — Where Money Is Going\n\n'
          'Top expense categories this month:\n$expStr\n\n'
          'Total Expenses: ${_fmt(_totalExpenses)}\n\n'
          '${_topExpenses.isNotEmpty ? 'Recommendation: Review your top expense category "${_topExpenses.first['category']}" for potential savings. Even a 10% reduction could improve profit by ${_fmt(_totalExpenses * 0.1)}.' : 'No expense data available yet. Start recording transactions to get detailed analysis.'}';
    }

    if (query.contains('branch') || query.contains('location')) {
      return '🏢 Branch Performance\n\n'
          'You currently operate $_branchCount branch${_branchCount != 1 ? 'es' : ''}.\n\n'
          'Recommendation: Visit the Branch Management screen to see detailed revenue rankings per branch. The top-performing branch should receive priority investment, while underperforming branches need operational review.\n\n'
          'Key metric to track: Revenue per branch as a percentage of total revenue.';
    }

    if (query.contains('expand') ||
        query.contains('grow') ||
        query.contains('new branch')) {
      return '🚀 Expansion Analysis\n\n'
          'Current financial position:\n'
          '• Monthly Net Profit: ${_fmt(_netProfit)}\n'
          '• Profit Margin: ${margin.toStringAsFixed(1)}%\n\n'
          '${_netProfit > 0 && margin > 15 ? '✅ Your business shows strong profitability. Expansion is financially viable.\n\nRecommended approach:\n1. Ensure 3-6 months operating capital reserve\n2. Analyze target market before opening new branch\n3. Use the Business Simulator to model expansion costs\n4. Consider phased expansion to manage risk' : '⚠️ Current profit margins suggest caution before expansion. Focus on optimizing existing operations first.\n\nSuggested steps:\n1. Increase revenue by 20% in current operations\n2. Reduce top expense categories by 10%\n3. Build a capital reserve of at least ${_fmt(_totalExpenses * 3)}'}';
    }

    if (query.contains('revenue') ||
        query.contains('income') ||
        query.contains('sales')) {
      return '📈 Revenue Growth Strategies for $bizName\n\n'
          'Current monthly revenue: ${_fmt(_totalRevenue)}\n\n'
          'Strategies to increase revenue:\n'
          '1. Diversify income streams — add complementary services\n'
          '2. Improve customer retention — repeat customers cost less to serve\n'
          '3. Review pricing — a 10% price increase could add ${_fmt(_totalRevenue * 0.1)} monthly\n'
          '4. Expand to underserved markets in your region\n'
          '5. Leverage your best-performing branch model for new locations\n\n'
          'Target: Grow revenue by 20% to reach ${_fmt(_totalRevenue * 1.2)}/month.';
    }

    if (query.contains('salary') ||
        query.contains('staff') ||
        query.contains('hire') ||
        query.contains('employee')) {
      final totalSalary = _totalExpenses * 0.4;
      final salaryRatio = _totalRevenue > 0
          ? (totalSalary / _totalRevenue) * 100
          : 0;
      return '👥 Workforce Analysis\n\n'
          '• Active Employees: $_employeeCount\n'
          '• Estimated Payroll Ratio: ${salaryRatio.toStringAsFixed(1)}% of revenue\n\n'
          '${salaryRatio < 30
              ? '✅ Payroll ratio is healthy. You have capacity to hire if needed.'
              : salaryRatio < 50
              ? '⚠️ Payroll is moderate. New hires should be tied to clear revenue targets.'
              : '🔴 High payroll ratio. Review staffing levels before hiring.'}\n\n'
          'Hiring recommendation: Only hire when a new employee can generate at least 3x their salary in additional revenue within 6 months.';
    }

    if (query.contains('margin') || query.contains('profit')) {
      return '💰 Profitability Analysis\n\n'
          '• Gross Revenue: ${_fmt(_totalRevenue)}\n'
          '• Total Expenses: ${_fmt(_totalExpenses)}\n'
          '• Net Profit: ${_fmt(_netProfit)}\n'
          '• Profit Margin: ${margin.toStringAsFixed(1)}%\n\n'
          '${margin >= 20
              ? '✅ Excellent margin. Industry benchmark for most businesses is 10-20%.'
              : margin >= 10
              ? '✅ Good margin. Focus on maintaining this level while scaling.'
              : margin >= 0
              ? '⚠️ Low margin. Target 15%+ by reducing top expenses.'
              : '🔴 Negative margin. Immediate action required to cut costs or increase prices.'}\n\n'
          'To reach 20% margin, you need to either increase revenue to ${_fmt(_totalExpenses / 0.8)} or reduce expenses to ${_fmt(_totalRevenue * 0.8)}.';
    }

    return '🤖 AI Business Analysis\n\n'
        'Based on your current data for $bizName:\n\n'
        '• Revenue: ${_fmt(_totalRevenue)}\n'
        '• Expenses: ${_fmt(_totalExpenses)}\n'
        '• Net Profit: ${_fmt(_netProfit)}\n'
        '• Health Score: $_healthScore/100\n\n'
        'I can help you analyze:\n'
        '• Business performance and health\n'
        '• Expense optimization opportunities\n'
        '• Revenue growth strategies\n'
        '• Expansion feasibility\n'
        '• Staffing decisions\n'
        '• Profit margin improvement\n\n'
        'Ask me a specific question about your business!';
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Business Advisor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                if (_activeBusiness != null)
                  Text(
                    _activeBusiness!['name'] as String,
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
      body: Column(
        children: [
          _buildMetricBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (_isThinking && i == _messages.length) {
                  return _buildThinkingBubble();
                }
                return _buildMessageBubble(_messages[i]);
              },
            ),
          ),
          _buildQuickQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMetricBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surfaceLight,
      child: Row(
        children: [
          _metricChip('Revenue', _fmt(_totalRevenue), AppTheme.success),
          const SizedBox(width: 8),
          _metricChip(
            'Profit',
            _fmt(_netProfit),
            _netProfit >= 0 ? AppTheme.primary : AppTheme.error,
          ),
          const SizedBox(width: 8),
          _metricChip(
            'Score',
            '$_healthScore/100',
            _healthScore >= 70 ? AppTheme.success : AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isAi = msg['role'] == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAi ? AppTheme.surfaceLight : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAi ? 4 : 14),
                  topRight: Radius.circular(isAi ? 14 : 4),
                  bottomLeft: const Radius.circular(14),
                  bottomRight: const Radius.circular(14),
                ),
                border: isAi ? Border.all(color: AppTheme.outlineLight) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg['text'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isAi ? AppTheme.onSurfaceLight : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!isAi) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CustomIconWidget(
                iconName: 'psychology',
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: Duration(milliseconds: 300 + i * 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      height: 38,
      color: AppTheme.surfaceLight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(_quickQuestions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Text(
              _quickQuestions[i],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask about your business...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.mutedLight,
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'send',
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
