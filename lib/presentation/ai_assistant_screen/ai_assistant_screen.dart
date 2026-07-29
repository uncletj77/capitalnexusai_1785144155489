import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/chat_notifier.dart';
import '../../services/ai_brain_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _typingController;
  late Animation<double> _typingAnim;

  // Conversation history for multi-turn context
  final List<Map<String, dynamic>> _uiMessages = [];
  final List<Map<String, String>> _apiHistory = [];

  bool _showSuggestions = true;
  bool _contextLoaded = false;
  String _systemPrompt = '';
  String? _userName;

  static const _config = ChatConfig(
    provider: 'OPEN_AI',
    model: 'gpt-4o',
    streaming: false,
  );

  final List<Map<String, dynamic>> _suggestions = [
    {
      'text': 'How is my financial health?',
      'icon': 'favorite',
      'color': Color(0xFF10B981),
    },
    {
      'text': 'Analyze my cash flow this month',
      'icon': 'waterfall_chart',
      'color': Color(0xFF2D9CDB),
    },
    {
      'text': 'Which of my investments are performing best?',
      'icon': 'show_chart',
      'color': Color(0xFF8B5CF6),
    },
    {
      'text': 'Do I have any overdue loan payments?',
      'icon': 'credit_score',
      'color': Color(0xFFEF4444),
    },
    {
      'text': 'What is my net worth breakdown?',
      'icon': 'account_balance_wallet',
      'color': Color(0xFFF59E0B),
    },
    {
      'text': 'Where am I spending the most money?',
      'icon': 'receipt_long',
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _typingAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
    _loadContext();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      _userName =
          user?.userMetadata?['full_name'] as String? ??
          user?.email?.split('@').first ??
          'there';

      final context = await AiBrainService.instance.buildUserContext();
      _systemPrompt = AiBrainService.instance.buildSystemPromptPublic(context);

      // Add welcome message with real context
      final summary = context['summary'] as String? ?? '';
      final hasData =
          summary.contains('TZS') || summary.contains('N/A') == false;

      final welcomeText = hasData
          ? 'Hello $_userName! 👋 I\'m your Capital NEXUS AI advisor.\n\n'
                'I\'ve analyzed your financial data. Here\'s a quick overview:\n\n'
                '$summary\n\n'
                'How can I help you make better financial decisions today?'
          : 'Hello $_userName! 👋 I\'m your Capital NEXUS AI advisor.\n\n'
                'I\'m ready to help you manage your finances. Start by adding transactions, '
                'assets, or businesses — then I can provide personalized insights.\n\n'
                'What would you like to do today?';

      if (mounted) {
        setState(() {
          _contextLoaded = true;
          _uiMessages.add({
            'role': 'ai',
            'text': welcomeText,
            'time': _timeNow(),
          });
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _contextLoaded = true;
          _uiMessages.add({
            'role': 'ai',
            'text':
                'Hello! I\'m your Capital NEXUS AI advisor. How can I help you today?',
            'time': _timeNow(),
          });
        });
      }
    }
  }

  String _timeNow() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final timeStr = _timeNow();
    setState(() {
      _showSuggestions = false;
      _uiMessages.add({'role': 'user', 'text': trimmed, 'time': timeStr});
    });
    _inputController.clear();
    _scrollToBottom();

    // Build messages for API
    final messages = <Map<String, dynamic>>[];
    if (_systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': _systemPrompt});
    }
    for (final h in _apiHistory) {
      messages.add(h);
    }
    messages.add({'role': 'user', 'content': trimmed});

    // Track in history
    _apiHistory.add({'role': 'user', 'content': trimmed});

    // Send via Lambda
    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(messages, parameters: {'max_completion_tokens': 1500});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearConversation() {
    setState(() {
      _uiMessages.clear();
      _apiHistory.clear();
      _showSuggestions = true;
      _uiMessages.add({
        'role': 'ai',
        'text': 'Conversation cleared. How can I help you?',
        'time': _timeNow(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_config));

    // Listen for AI responses
    ref.listen<ChatState>(chatNotifierProvider(_config), (previous, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: 'AI error: ${next.error}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      // When loading finishes and we have a new response
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.response.isNotEmpty) {
        final aiText = next.response;
        _apiHistory.add({'role': 'assistant', 'content': aiText});
        setState(() {
          _uiMessages.add({'role': 'ai', 'text': aiText, 'time': _timeNow()});
        });
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(chatState),
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: !_contextLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount:
                            _uiMessages.length +
                            (chatState.isLoading ? 1 : 0) +
                            (_showSuggestions ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_showSuggestions && index == _uiMessages.length) {
                            return _buildSuggestions();
                          }
                          if (chatState.isLoading &&
                              index ==
                                  _uiMessages.length +
                                      (_showSuggestions ? 1 : 0)) {
                            return _buildTypingIndicator();
                          }
                          if (index < _uiMessages.length) {
                            return _buildMessage(_uiMessages[index]);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),
            _buildInputBar(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CNA AI Advisor',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: chatState.isLoading
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatState.isLoading
                          ? 'Analyzing your data...'
                          : 'Online · Analyzing your portfolio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearConversation,
            icon: const CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.mutedLight,
              size: 20,
            ),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isAi = msg['role'] == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAi
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAi ? AppTheme.surfaceLight : AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isAi ? 4 : 16),
                      topRight: Radius.circular(isAi ? 16 : 4),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: isAi
                        ? Border.all(color: AppTheme.outlineLight)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageText(msg['text'] as String, isAi),
                ),
                const SizedBox(height: 4),
                Text(
                  msg['time'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          if (!isAi) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  (_userName?.isNotEmpty == true)
                      ? _userName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isAi) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isBold = line.startsWith('**') && line.endsWith('**');
        final displayLine = isBold ? line.replaceAll('**', '') : line;
        return Text(
          displayLine,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isAi ? AppTheme.onSurfaceLight : Colors.white,
            height: 1.5,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
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
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(
                          ((_typingAnim.value - (i * 0.15)).clamp(0.2, 1.0) *
                                  255)
                              .toInt(),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Text(
            'Suggested questions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...List.generate(_suggestions.length, (i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(s['text'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: s['icon'] as String,
                        color: s['color'] as Color,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['text'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ),
                  const CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: AppTheme.mutedLight,
                    size: 12,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInputBar(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          if (!chatState.isLoading) {
                            _sendMessage(_inputController.text);
                          }
                        }
                      },
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        enabled: !chatState.isLoading,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.onSurfaceLight,
                        ),
                        decoration: InputDecoration(
                          hintText: chatState.isLoading
                              ? 'AI is thinking...'
                              : 'Ask your AI advisor...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.mutedLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) {
                          if (!chatState.isLoading) _sendMessage(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: chatState.isLoading
                ? null
                : () => _sendMessage(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: chatState.isLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                      ),
                color: chatState.isLoading ? AppTheme.outlineLight : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: chatState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const CustomIconWidget(
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
