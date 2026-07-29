import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/aiIntegrations/chat_completion_service.dart';

/// CNA Brain — Central AI Intelligence Layer
/// All AI calls go through AWS Lambda (never direct OpenAI).
/// Every recommendation is traceable to real Finance Engine data.
class AiBrainService {
  static AiBrainService? _instance;
  static AiBrainService get instance => _instance ??= AiBrainService._();
  AiBrainService._();

  SupabaseClient get _client => Supabase.instance.client;
  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  // ============================================================
  // SYSTEM PROMPT — Personal CFO Intelligence
  // ============================================================

  String _buildSystemPrompt(Map<String, dynamic> context) {
    final memory = context['memory'] as List? ?? [];
    final memoryText = memory.isNotEmpty
        ? memory.map((m) => '- ${m['content']}').join('\n')
        : '- No memory stored yet.';

    final userName = context['user_name'] as String? ?? 'the user';

    return '''You are the CNA Brain — a Personal CFO, Business Strategist, Wealth Advisor, and Financial Intelligence System for Capital Nexus AI.

USER: $userName

=== LIVE FINANCIAL DATA (from Finance Engine) ===
${context['summary'] ?? 'No financial data available yet. Tell the user to add transactions, accounts, or assets to get personalized insights.'}

=== LONG-TERM MEMORY ===
$memoryText

=== YOUR CAPABILITIES ===
You operate in two modes:
1. PERSONAL INTELLIGENCE — Uses the user's real financial data above for personalized insights
2. GENERAL INTELLIGENCE — Answers general questions about business, economics, accounting, entrepreneurship, technology

Automatically choose the correct mode based on the question.

=== SPECIALIZED AGENTS ===
- Financial Analyst: income, expenses, cash flow, financial health score
- Asset Intelligence: asset performance, ROI, depreciation, poor performers
- Business Advisor: business growth, operational problems, profitability
- Investment Analyst: returns, risk, portfolio diversification, concentration risk
- Debt Advisor: loan strategies, repayment optimization, affordability analysis
- Planning Agent: future projections, goal achievement, scenario simulation
- Risk Guardian: unusual spending, overdue loans, cash shortages, budget overruns
- Opportunity Engine: idle cash, underperforming assets, savings opportunities

=== RESPONSE FRAMEWORK ===
For financial questions, always structure your response:
📊 SITUATION: What is happening based on real data
🔍 ANALYSIS: Why it is happening (data-driven reasoning)
⚠️ RISK: What could go wrong
💡 OPPORTUNITY: What can improve
✅ ACTION: Specific next steps with TZS amounts

=== EXPLAINABILITY RULES ===
- Always cite which data you used (e.g., "Based on your 3 active loans totaling TZS X...")
- State your confidence level when making projections
- Explain assumptions in scenario analysis
- Never invent financial figures — if data is missing, say so clearly
- Use TZS (Tanzanian Shilling) as the primary currency

=== MASTER RULES ===
- NEVER fabricate financial information
- NEVER use demo or placeholder data
- If data is insufficient, clearly explain what information is needed
- Every recommendation must be traceable to real data
- Require explicit user confirmation before suggesting changes to financial records
- Respect user privacy — never expose other users' data
- Be concise but complete — connect information across modules''';
  }

  String buildSystemPromptPublic(Map<String, dynamic> context) =>
      _buildSystemPrompt(context);

  // ============================================================
  // DIGITAL WEALTH TWIN — Complete Financial Context Builder
  // ============================================================

  Future<Map<String, dynamic>> buildUserContext() async {
    if (_currentUserId.isEmpty) return {'summary': 'User not authenticated.'};

    try {
      final results = await Future.wait([
        _getUserProfile(),
        _getFinancialSummary(),
        _getAssetsSummary(),
        _getLoansSummary(),
        _getLoansReceivableSummary(),
        _getBusinessSummary(),
        _getInvestmentsSummary(),
        _getGoalsSummary(),
        _getBudgetSummary(),
        _getRecentTransactions(),
        _getLongTermMemory(),
      ]);

      final context = {
        'user_name': (results[0] as Map)['name'] ?? 'User',
        'financial': results[1],
        'assets': results[2],
        'loans': results[3],
        'loans_receivable': results[4],
        'businesses': results[5],
        'investments': results[6],
        'goals': results[7],
        'budgets': results[8],
        'recent_transactions': results[9],
        'memory': results[10],
      };

      context['summary'] = _buildContextSummary(context);
      return context;
    } catch (e) {
      return {
        'summary': 'Unable to load full financial context. Error: $e',
        'memory': [],
      };
    }
  }

  String _buildContextSummary(Map<String, dynamic> ctx) {
    final fin = ctx['financial'] as Map<String, dynamic>? ?? {};
    final assets = ctx['assets'] as Map<String, dynamic>? ?? {};
    final loans = ctx['loans'] as Map<String, dynamic>? ?? {};
    final recv = ctx['loans_receivable'] as Map<String, dynamic>? ?? {};
    final biz = ctx['businesses'] as Map<String, dynamic>? ?? {};
    final inv = ctx['investments'] as Map<String, dynamic>? ?? {};
    final goals = ctx['goals'] as Map<String, dynamic>? ?? {};
    final budgets = ctx['budgets'] as Map<String, dynamic>? ?? {};
    final txns = ctx['recent_transactions'] as List? ?? [];

    final sb = StringBuffer();
    sb.writeln('=== CASH & ACCOUNTS ===');
    sb.writeln('Total Cash/Accounts: ${fin['total_balance'] ?? 'N/A'}');
    sb.writeln('Monthly Income: ${fin['monthly_income'] ?? 'N/A'}');
    sb.writeln('Monthly Expenses: ${fin['monthly_expenses'] ?? 'N/A'}');
    sb.writeln('Net Cash Flow: ${fin['net_cash_flow'] ?? 'N/A'}');
    sb.writeln('Account Count: ${fin['account_count'] ?? 0}');

    sb.writeln('\n=== ASSETS ===');
    sb.writeln('Total Assets: ${assets['count'] ?? 0} items');
    sb.writeln('Total Asset Value: ${assets['total_value'] ?? 'N/A'}');
    if ((assets['list'] as List?)?.isNotEmpty == true) {
      sb.writeln('Asset Details:');
      for (final a in (assets['list'] as List).take(5)) {
        sb.writeln(
          '  - ${a['name']}: ${a['type']} | Value: ${a['value']} | Status: ${a['status']}',
        );
      }
    }

    sb.writeln('\n=== BUSINESSES ===');
    sb.writeln('Active Businesses: ${biz['count'] ?? 0}');
    if ((biz['list'] as List?)?.isNotEmpty == true) {
      for (final b in (biz['list'] as List)) {
        sb.writeln(
          '  - ${b['name']}: ${b['type'] ?? 'Business'} | Revenue: ${b['revenue']}',
        );
      }
    }

    sb.writeln('\n=== INVESTMENTS ===');
    sb.writeln('Portfolio Value: ${inv['total_value'] ?? 'N/A'}');
    sb.writeln('Investment Count: ${inv['count'] ?? 0}');
    if ((inv['list'] as List?)?.isNotEmpty == true) {
      for (final i in (inv['list'] as List).take(3)) {
        sb.writeln(
          '  - ${i['name']}: ${i['category']} | Value: ${i['value']} | ROI: ${i['roi']}',
        );
      }
    }

    sb.writeln('\n=== LOANS PAYABLE ===');
    sb.writeln('Active Loans: ${loans['count'] ?? 0}');
    sb.writeln('Total Outstanding: ${loans['total_outstanding'] ?? 'N/A'}');
    sb.writeln('Overdue Loans: ${loans['overdue_count'] ?? 0}');
    if ((loans['list'] as List?)?.isNotEmpty == true) {
      for (final l in (loans['list'] as List).take(3)) {
        sb.writeln(
          '  - ${l['name']}: Outstanding: ${l['outstanding']} | Due: ${l['due_date']} | Status: ${l['status']}',
        );
      }
    }

    sb.writeln('\n=== LOANS RECEIVABLE ===');
    sb.writeln('Money Lent Out: ${recv['count'] ?? 0} loans');
    sb.writeln('Total Receivable: ${recv['total_outstanding'] ?? 'N/A'}');

    sb.writeln('\n=== FINANCIAL GOALS ===');
    sb.writeln('Active Goals: ${goals['count'] ?? 0}');
    if ((goals['list'] as List?)?.isNotEmpty == true) {
      for (final g in (goals['list'] as List).take(3)) {
        sb.writeln(
          '  - ${g['name']}: Target: ${g['target']} | Progress: ${g['progress']}% | Priority: ${g['priority']}',
        );
      }
    }

    sb.writeln('\n=== BUDGETS ===');
    sb.writeln('Active Budgets: ${budgets['count'] ?? 0}');
    sb.writeln('Budget Utilization: ${budgets['utilization'] ?? 'N/A'}');

    if (txns.isNotEmpty) {
      sb.writeln('\n=== RECENT TRANSACTIONS (last 10) ===');
      for (final t in txns.take(10)) {
        sb.writeln(
          '  - ${t['transaction_date']}: ${t['transaction_type']} | ${t['category']} | ${_fmt(t['amount'])} | ${t['description'] ?? ''}',
        );
      }
    }

    return sb.toString();
  }

  // ─── Data Fetchers ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      final profile = await _client
          .from('user_profiles')
          .select('full_name, first_name')
          .eq('id', _currentUserId)
          .maybeSingle();
      return {
        'name': profile?['full_name'] ?? profile?['first_name'] ?? 'User',
      };
    } catch (_) {
      return {'name': 'User'};
    }
  }

  Future<Map<String, dynamic>> _getFinancialSummary() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final accounts = await _client
          .from('financial_accounts')
          .select('current_balance, account_name, account_category')
          .eq('user_id', _currentUserId)
          .eq('is_active', true);

      final txns = await _client
          .from('financial_transactions')
          .select('transaction_type, amount')
          .eq('user_id', _currentUserId)
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .gte('transaction_date', monthStart.toIso8601String().split('T')[0]);

      double totalBalance = 0;
      for (final a in accounts) {
        totalBalance += (a['current_balance'] as num?)?.toDouble() ?? 0;
      }

      double income = 0, expenses = 0;
      for (final t in txns) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0;
        if (t['transaction_type'] == 'income') income += amt;
        if (t['transaction_type'] == 'expense') expenses += amt;
      }

      return {
        'total_balance': 'TZS ${_formatNumber(totalBalance)}',
        'monthly_income': 'TZS ${_formatNumber(income)}',
        'monthly_expenses': 'TZS ${_formatNumber(expenses)}',
        'net_cash_flow': 'TZS ${_formatNumber(income - expenses)}',
        'account_count': accounts.length,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getAssetsSummary() async {
    try {
      final assets = await _client
          .from('assets')
          .select('name, asset_type, current_value, status')
          .eq('owner_id', _currentUserId);

      double total = 0;
      final list = <Map<String, dynamic>>[];
      for (final a in assets) {
        final val = (a['current_value'] as num?)?.toDouble() ?? 0;
        total += val;
        list.add({
          'name': a['name'] ?? 'Asset',
          'type': a['asset_type'] ?? 'Other',
          'value': 'TZS ${_formatNumber(val)}',
          'status': a['status'] ?? 'active',
        });
      }

      return {
        'count': assets.length,
        'total_value': 'TZS ${_formatNumber(total)}',
        'list': list,
      };
    } catch (_) {
      return {'count': 0, 'list': []};
    }
  }

  Future<Map<String, dynamic>> _getLoansSummary() async {
    try {
      final loans = await _client
          .from('loans')
          .select('loan_name, outstanding_balance, due_date, status')
          .eq('borrower_id', _currentUserId);

      double total = 0;
      int overdue = 0;
      final list = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (final l in loans) {
        final bal = (l['outstanding_balance'] as num?)?.toDouble() ?? 0;
        total += bal;
        final dueDate = l['due_date'] != null
            ? DateTime.tryParse(l['due_date'] as String)
            : null;
        if (dueDate != null && dueDate.isBefore(now)) overdue++;
        list.add({
          'name': l['loan_name'] ?? 'Loan',
          'outstanding': 'TZS ${_formatNumber(bal)}',
          'due_date': l['due_date'] ?? 'N/A',
          'status': l['status'] ?? 'active',
        });
      }

      return {
        'count': loans.length,
        'total_outstanding': 'TZS ${_formatNumber(total)}',
        'overdue_count': overdue,
        'list': list,
      };
    } catch (_) {
      return {'count': 0, 'list': []};
    }
  }

  Future<Map<String, dynamic>> _getLoansReceivableSummary() async {
    try {
      final loans = await _client
          .from('loans_receivable')
          .select('borrower_name, remaining_balance, status')
          .eq('lender_id', _currentUserId);

      double total = 0;
      for (final l in loans) {
        total += (l['remaining_balance'] as num?)?.toDouble() ?? 0;
      }

      return {
        'count': loans.length,
        'total_outstanding': 'TZS ${_formatNumber(total)}',
      };
    } catch (_) {
      return {'count': 0};
    }
  }

  Future<Map<String, dynamic>> _getBusinessSummary() async {
    try {
      final businesses = await _client
          .from('businesses')
          .select('id, name, business_type')
          .eq('owner_id', _currentUserId);

      final list = <Map<String, dynamic>>[];
      for (final b in businesses) {
        // Get monthly revenue for each business
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        double revenue = 0;
        try {
          final txns = await _client
              .from('financial_transactions')
              .select('amount')
              .eq('user_id', _currentUserId)
              .eq('related_business_id', b['id'] as String)
              .eq('transaction_type', 'income')
              .gte(
                'transaction_date',
                monthStart.toIso8601String().split('T')[0],
              );
          for (final t in txns) {
            revenue += (t['amount'] as num?)?.toDouble() ?? 0;
          }
        } catch (_) {}

        list.add({
          'name': b['name'] ?? 'Business',
          'type': b['business_type'] ?? 'Business',
          'revenue': 'TZS ${_formatNumber(revenue)}/month',
        });
      }

      return {'count': businesses.length, 'list': list};
    } catch (_) {
      return {'count': 0, 'list': []};
    }
  }

  Future<Map<String, dynamic>> _getInvestmentsSummary() async {
    try {
      final investments = await _client
          .from('investments')
          .select('name, category, current_value, purchase_price')
          .eq('user_id', _currentUserId);

      double total = 0;
      final list = <Map<String, dynamic>>[];
      for (final i in investments) {
        final val = (i['current_value'] as num?)?.toDouble() ?? 0;
        final cost = (i['purchase_price'] as num?)?.toDouble() ?? 0;
        total += val;
        final roi = cost > 0
            ? ((val - cost) / cost * 100).toStringAsFixed(1)
            : 'N/A';
        list.add({
          'name': i['name'] ?? 'Investment',
          'category': i['category'] ?? 'Other',
          'value': 'TZS ${_formatNumber(val)}',
          'roi': roi != 'N/A' ? '$roi%' : 'N/A',
        });
      }

      return {
        'count': investments.length,
        'total_value': 'TZS ${_formatNumber(total)}',
        'list': list,
      };
    } catch (_) {
      return {'count': 0, 'list': []};
    }
  }

  Future<Map<String, dynamic>> _getGoalsSummary() async {
    try {
      final goals = await _client
          .from('financial_goals')
          .select('name, target_amount, current_amount, priority, status')
          .eq('user_id', _currentUserId)
          .eq('status', 'active');

      final list = <Map<String, dynamic>>[];
      for (final g in goals) {
        final target = (g['target_amount'] as num?)?.toDouble() ?? 0;
        final current = (g['current_amount'] as num?)?.toDouble() ?? 0;
        final progress = target > 0
            ? (current / target * 100).toStringAsFixed(0)
            : '0';
        list.add({
          'name': g['name'] ?? 'Goal',
          'target': 'TZS ${_formatNumber(target)}',
          'progress': progress,
          'priority': g['priority'] ?? 'medium',
        });
      }

      return {'count': goals.length, 'list': list};
    } catch (_) {
      return {'count': 0, 'list': []};
    }
  }

  Future<Map<String, dynamic>> _getBudgetSummary() async {
    try {
      final budgets = await _client
          .from('budgets')
          .select('id, total_budget, spent_amount')
          .eq('user_id', _currentUserId)
          .eq('status', 'active');

      double totalBudget = 0, totalSpent = 0;
      for (final b in budgets) {
        totalBudget += (b['total_budget'] as num?)?.toDouble() ?? 0;
        totalSpent += (b['spent_amount'] as num?)?.toDouble() ?? 0;
      }

      final utilization = totalBudget > 0
          ? '${(totalSpent / totalBudget * 100).toStringAsFixed(0)}%'
          : 'N/A';

      return {
        'count': budgets.length,
        'utilization': utilization,
        'total_budget': 'TZS ${_formatNumber(totalBudget)}',
        'total_spent': 'TZS ${_formatNumber(totalSpent)}',
      };
    } catch (_) {
      return {'count': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentTransactions() async {
    try {
      final txns = await _client
          .from('financial_transactions')
          .select(
            'transaction_type, category, amount, transaction_date, description',
          )
          .eq('user_id', _currentUserId)
          .eq('is_archived', false)
          .neq('status', 'cancelled')
          .order('transaction_date', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(txns);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLongTermMemory() async {
    try {
      final memory = await _client
          .from('ai_memory')
          .select('content, memory_type, importance_score')
          .eq('user_id', _currentUserId)
          .eq('is_active', true)
          .order('importance_score', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(memory);
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // AI MODE DETECTION
  // ============================================================

  /// Determines if a question needs personal financial data or is general
  bool _isPersonalQuestion(String message) {
    final lower = message.toLowerCase();
    final personalKeywords = [
      'my ',
      'i have',
      'i owe',
      'i earn',
      'i spend',
      'my business',
      'my loan',
      'my asset',
      'my investment',
      'my goal',
      'my budget',
      'my cash',
      'my net worth',
      'my income',
      'my expense',
      'my debt',
      'should i buy',
      'can i afford',
      'how much do i',
      'what is my',
      'my financial',
      'my portfolio',
      'my savings',
      'my account',
    ];
    return personalKeywords.any((kw) => lower.contains(kw));
  }

  // ============================================================
  // CONVERSATION MANAGEMENT
  // ============================================================

  Future<String> createConversation(String title) async {
    try {
      final result = await _client
          .from('ai_conversations')
          .insert({'user_id': _currentUserId, 'title': title})
          .select('id')
          .single();
      return result['id'] as String;
    } catch (_) {
      return 'local-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final result = await _client
          .from('ai_conversations')
          .select('id, title, created_at')
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    if (conversationId.startsWith('local-')) return [];
    try {
      final result = await _client
          .from('ai_messages')
          .select('id, role, content, agent_type, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessage({
    required String conversationId,
    required String role,
    required String content,
    String? agentType,
  }) async {
    if (conversationId.startsWith('local-')) return;
    try {
      await _client.from('ai_messages').insert({
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'agent_type': agentType,
      });
    } catch (_) {}
  }

  // ============================================================
  // AI ORCHESTRATOR — Main Chat Engine (via Lambda)
  // ============================================================

  Future<String> chat({
    required String conversationId,
    required List<Map<String, dynamic>> messageHistory,
    required String userMessage,
  }) async {
    final agentType = _detectAgent(userMessage);
    final isPersonal = _isPersonalQuestion(userMessage);

    // Build context — only fetch full context for personal questions
    Map<String, dynamic> context;
    if (isPersonal) {
      context = await buildUserContext();
    } else {
      context = {
        'user_name': 'User',
        'summary':
            'This is a general knowledge question — no personal financial data needed.',
        'memory': await _getLongTermMemory(),
      };
    }

    final systemPrompt = _buildSystemPrompt(context);
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...messageHistory.map(
        (m) => {'role': m['role'] as String, 'content': m['content'] as String},
      ),
      {'role': 'user', 'content': userMessage},
    ];

    // Call AI via Lambda (never direct OpenAI)
    final response = await getChatCompletion(
      'OPEN_AI',
      'gpt-4.1',
      messages,
      parameters: {'max_completion_tokens': 1500},
    );

    final aiResponse =
        response['choices']?[0]?['message']?['content'] as String? ??
        'I was unable to process your request. Please try again.';

    // Persist messages
    await saveMessage(
      conversationId: conversationId,
      role: 'user',
      content: userMessage,
    );
    await saveMessage(
      conversationId: conversationId,
      role: 'assistant',
      content: aiResponse,
      agentType: agentType,
    );

    // Auto-save important memory
    await _autoSaveMemory(userMessage, aiResponse);

    return aiResponse;
  }

  /// Streaming chat — calls onChunk for each token, onComplete when done
  Future<void> chatStreaming({
    required String conversationId,
    required List<Map<String, dynamic>> messageHistory,
    required String userMessage,
    required void Function(String token) onChunk,
    required void Function(String fullResponse) onComplete,
    required void Function(Exception error) onError,
  }) async {
    final agentType = _detectAgent(userMessage);
    final isPersonal = _isPersonalQuestion(userMessage);

    Map<String, dynamic> context;
    if (isPersonal) {
      context = await buildUserContext();
    } else {
      context = {
        'user_name': 'User',
        'summary': 'General knowledge question.',
        'memory': await _getLongTermMemory(),
      };
    }

    final systemPrompt = _buildSystemPrompt(context);
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...messageHistory.map(
        (m) => {'role': m['role'] as String, 'content': m['content'] as String},
      ),
      {'role': 'user', 'content': userMessage},
    ];

    final fullBuffer = StringBuffer();

    await getStreamingChatCompletion(
      'OPEN_AI',
      'gpt-4.1',
      messages,
      onChunk: (chunk) {
        final content = chunk['choices']?[0]?['delta']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          fullBuffer.write(content);
          onChunk(content);
        }
      },
      onComplete: () async {
        final fullResponse = fullBuffer.toString();
        onComplete(fullResponse);
        // Persist after streaming completes
        await saveMessage(
          conversationId: conversationId,
          role: 'user',
          content: userMessage,
        );
        await saveMessage(
          conversationId: conversationId,
          role: 'assistant',
          content: fullResponse,
          agentType: agentType,
        );
        await _autoSaveMemory(userMessage, fullResponse);
      },
      onError: onError,
      parameters: {'max_completion_tokens': 1500},
    );
  }

  String detectAgentPublic(String message) => _detectAgent(message);

  String _detectAgent(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('asset') ||
        lower.contains('vehicle') ||
        lower.contains('property') ||
        lower.contains('equipment')) {
      return 'asset_intelligence';
    } else if (lower.contains('business') ||
        lower.contains('revenue') ||
        lower.contains('profit') ||
        lower.contains('operational')) {
      return 'business_advisor';
    } else if (lower.contains('invest') ||
        lower.contains('portfolio') ||
        lower.contains('return') ||
        lower.contains('roi')) {
      return 'investment_analyst';
    } else if (lower.contains('loan') ||
        lower.contains('debt') ||
        lower.contains('borrow') ||
        lower.contains('repay')) {
      return 'debt_advisor';
    } else if (lower.contains('goal') ||
        lower.contains('future') ||
        lower.contains('plan') ||
        lower.contains('billion') ||
        lower.contains('year') ||
        lower.contains('scenario') ||
        lower.contains('what if')) {
      return 'planning_agent';
    } else if (lower.contains('risk') ||
        lower.contains('warning') ||
        lower.contains('overdue') ||
        lower.contains('shortage')) {
      return 'risk_guardian';
    }
    return 'financial_analyst';
  }

  Future<void> _autoSaveMemory(String userMessage, String aiResponse) async {
    try {
      final lower = userMessage.toLowerCase();
      String? memoryType;
      String? content;

      if (lower.contains('goal') ||
          lower.contains('want to reach') ||
          lower.contains('billion') ||
          lower.contains('target')) {
        memoryType = 'financial_goal';
        content = 'User goal: $userMessage';
      } else if (lower.contains('prefer') ||
          lower.contains('always') ||
          lower.contains('i like') ||
          lower.contains('i want')) {
        memoryType = 'user_preference';
        content = 'User preference: $userMessage';
      } else if (lower.contains('risk') ||
          lower.contains('conservative') ||
          lower.contains('aggressive')) {
        memoryType = 'risk_profile';
        content = 'Risk preference noted: $userMessage';
      }

      if (memoryType != null && content != null) {
        await _client.from('ai_memory').insert({
          'user_id': _currentUserId,
          'memory_type': memoryType,
          'content': content,
          'importance_score': 6,
          'is_active': true,
        });
      }
    } catch (_) {}
  }

  // ============================================================
  // EXECUTIVE BRIEFING
  // ============================================================

  Future<String> generateExecutiveBriefing() async {
    final context = await buildUserContext();
    final prompt =
        '''Generate a concise executive financial briefing for today based on this data:

${context['summary']}

Format as:
📊 NET WORTH SNAPSHOT
💰 CASH POSITION
📈 REVENUE & EXPENSES
🏢 BUSINESS HIGHLIGHTS
💼 INVESTMENT PERFORMANCE
🏦 LOAN STATUS
🎯 GOAL PROGRESS
⚠️ HIGH-PRIORITY ALERTS
✅ SUGGESTED NEXT ACTIONS (top 3)

Be specific with TZS amounts. If data is missing, say so.''';

    try {
      final response = await getChatCompletion(
        'OPEN_AI',
        'gpt-4.1-mini',
        [
          {'role': 'user', 'content': prompt},
        ],
        parameters: {'max_completion_tokens': 1000},
      );
      return response['choices']?[0]?['message']?['content'] as String? ??
          'Unable to generate briefing.';
    } catch (_) {
      return 'Unable to generate executive briefing at this time.';
    }
  }

  // ============================================================
  // RECOMMENDATIONS & INSIGHTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final result = await _client
          .from('ai_recommendations')
          .select('*')
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<void> updateRecommendationStatus(String id, String status) async {
    try {
      await _client
          .from('ai_recommendations')
          .update({'status': status})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> generateInsights() async {
    try {
      final context = await buildUserContext();
      final prompt =
          '''Based on this user's real financial data, generate exactly 3 actionable insights.
Return ONLY a valid JSON array with no other text.
Each item must have: title, body, category (warning/opportunity/info), priority (high/medium/low), agent_type.

Financial Data:
${context['summary']}

Example format:
[{"title":"...", "body":"...", "category":"warning", "priority":"high", "agent_type":"financial_analyst"}]''';

      final response = await getChatCompletion(
        'OPEN_AI',
        'gpt-4.1-mini',
        [
          {'role': 'user', 'content': prompt},
        ],
        parameters: {'max_completion_tokens': 800},
      );

      final content =
          response['choices']?[0]?['message']?['content'] as String? ?? '[]';
      return _parseInsightsJson(content);
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseInsightsJson(String json) {
    try {
      final startIdx = json.indexOf('[');
      final endIdx = json.lastIndexOf(']');
      if (startIdx < 0 || endIdx <= startIdx) return [];
      final cleanJson = json.substring(startIdx, endIdx + 1);
      final insights = <Map<String, dynamic>>[];
      final pattern = RegExp(r'\{[^}]+\}');
      for (final match in pattern.allMatches(cleanJson)) {
        final obj = match.group(0) ?? '';
        final insight = <String, dynamic>{};
        final kvPattern = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
        for (final kv in kvPattern.allMatches(obj)) {
          insight[kv.group(1)!] = kv.group(2)!;
        }
        if (insight.isNotEmpty) insights.add(insight);
      }
      return insights;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final result = await _client
          .from('ai_actions')
          .select('*')
          .eq('user_id', _currentUserId)
          .eq('completed', false)
          .eq('rejected', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<void> approveAction(String id) async {
    try {
      await _client
          .from('ai_actions')
          .update({'approved': true, 'completed': true})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (_) {}
  }

  Future<void> rejectAction(String id) async {
    try {
      await _client
          .from('ai_actions')
          .update({'rejected': true})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (_) {}
  }

  // ============================================================
  // MEMORY MANAGEMENT
  // ============================================================

  Future<List<Map<String, dynamic>>> getMemory() async {
    try {
      final result = await _client
          .from('ai_memory')
          .select('*')
          .eq('user_id', _currentUserId)
          .eq('is_active', true)
          .order('importance_score', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await _client
          .from('ai_memory')
          .update({'is_active': false})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (_) {}
  }

  Future<void> clearAllMemory() async {
    try {
      await _client
          .from('ai_memory')
          .update({'is_active': false})
          .eq('user_id', _currentUserId);
    } catch (_) {}
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _fmt(dynamic value) {
    final numValue = (value as num?)?.toDouble() ?? 0;
    return 'TZS ${_formatNumber(numValue)}';
  }

  String _formatNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}