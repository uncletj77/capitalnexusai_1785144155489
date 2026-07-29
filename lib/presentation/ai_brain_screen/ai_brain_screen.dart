import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_brain_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/cna_shared_components.dart';
import './widgets/ai_action_panel_widget.dart';
import './widgets/ai_insight_dashboard_widget.dart';
import './widgets/ai_memory_panel_widget.dart';

class AiBrainScreen extends ConsumerStatefulWidget {
  const AiBrainScreen({super.key});

  @override
  ConsumerState<AiBrainScreen> createState() => _AiBrainScreenState();
}

class _AiBrainScreenState extends ConsumerState<AiBrainScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _brainService = AiBrainService.instance;

  late TabController _tabController;

  String? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _pendingActions = [];
  bool _isLoading = false;
  bool _showSuggestions = true;
  bool _isInitializing = true;
  String _streamingBuffer = '';
  bool _isStreaming = false;
  String? _lastFailedMessage;

  final List<Map<String, dynamic>> _suggestedQuestions = [
    {
      'text': 'How is my financial situation?',
      'icon': 'favorite',
      'color': const Color(0xFF10B981),
      'agent': 'Financial Analyst',
    },
    {
      'text': 'Should I buy another vehicle?',
      'icon': 'directions_bus',
      'color': const Color(0xFF2D9CDB),
      'agent': 'Asset Intelligence',
    },
    {
      'text': 'How can I reach TZS 1 billion?',
      'icon': 'timeline',
      'color': const Color(0xFF8B5CF6),
      'agent': 'Planning Agent',
    },
    {
      'text': 'Which business gives highest return?',
      'icon': 'business_center',
      'color': const Color(0xFF059669),
      'agent': 'Business Advisor',
    },
    {
      'text': 'Where am I losing money?',
      'icon': 'money_off',
      'color': const Color(0xFFEF4444),
      'agent': 'Financial Analyst',
    },
    {
      'text': 'Analyze my loan situation',
      'icon': 'credit_score',
      'color': const Color(0xFFF59E0B),
      'agent': 'Debt Advisor',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final conversations = await _brainService.getConversations();
      if (conversations.isNotEmpty) {
        _conversationId = conversations.first['id'] as String;
        final msgs = await _brainService.getMessages(_conversationId!);
        if (mounted) {
          setState(() {
            _messages = msgs;
            _showSuggestions = msgs.isEmpty;
          });
        }
      } else {
        _conversationId = await _brainService.createConversation(
          'CNA AI Brain Session',
        );
      }

      final actions = await _brainService.getPendingActions();
      if (mounted) {
        setState(() {
          _pendingActions = actions;
          _isInitializing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _isStreaming) return;
    if (_conversationId == null) return;

    final userMsg = {
      'role': 'user',
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _isStreaming = false;
      _streamingBuffer = '';
      _showSuggestions = false;
      _lastFailedMessage = null;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      // Add placeholder for streaming response
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '',
          'created_at': DateTime.now().toIso8601String(),
          'streaming': true,
        });
        _isLoading = false;
        _isStreaming = true;
      });

      final history = _messages
          .where(
            (m) =>
                m['role'] != null &&
                m['streaming'] != true &&
                m['content'] != text,
          )
          .map(
            (m) => {
              'role': m['role'] as String,
              'content': m['content'] as String,
            },
          )
          .toList();

      await _brainService.chatStreaming(
        conversationId: _conversationId!,
        messageHistory: history,
        userMessage: text,
        onChunk: (token) {
          if (mounted) {
            setState(() {
              _streamingBuffer += token;
              // Update the last message (streaming placeholder)
              if (_messages.isNotEmpty && _messages.last['streaming'] == true) {
                _messages[_messages.length - 1] = {
                  'role': 'assistant',
                  'content': _streamingBuffer,
                  'created_at': DateTime.now().toIso8601String(),
                  'streaming': true,
                };
              }
            });
            _scrollToBottom();
          }
        },
        onComplete: (fullResponse) {
          if (mounted) {
            setState(() {
              // Finalize the streaming message
              if (_messages.isNotEmpty && _messages.last['streaming'] == true) {
                _messages[_messages.length - 1] = {
                  'role': 'assistant',
                  'content': fullResponse,
                  'created_at': DateTime.now().toIso8601String(),
                };
              }
              _isStreaming = false;
              _streamingBuffer = '';
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          if (mounted) {
            // Remove streaming placeholder
            setState(() {
              if (_messages.isNotEmpty && _messages.last['streaming'] == true) {
                _messages.removeLast();
              }
              _isStreaming = false;
              _isLoading = false;
              _lastFailedMessage = text;
            });
            Fluttertoast.showToast(
              msg: 'AI is temporarily unavailable. Tap retry to try again.',
              backgroundColor: Colors.red,
              toastLength: Toast.LENGTH_LONG,
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last['streaming'] == true) {
            _messages.removeLast();
          }
          _isLoading = false;
          _isStreaming = false;
          _lastFailedMessage = text;
        });
        Fluttertoast.showToast(
          msg: 'Connection error. Please check your internet and try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _retryLastMessage() {
    if (_lastFailedMessage != null) {
      _sendMessage(_lastFailedMessage!);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _newConversation() async {
    try {
      final id = await _brainService.createConversation(
        'Conversation ${DateTime.now().day}/${DateTime.now().month}',
      );
      if (mounted) {
        setState(() {
          _conversationId = id;
          _messages = [];
          _showSuggestions = true;
          _lastFailedMessage = null;
        });
      }
    } catch (_) {}
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(
      msg: 'Message copied to clipboard',
      backgroundColor: const Color(0xFF10B981),
    );
  }

  void _exportConversation() {
    if (_messages.isEmpty) {
      Fluttertoast.showToast(msg: 'No conversation to export');
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('CNA AI Brain — Conversation Export');
    buffer.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    for (final msg in _messages) {
      final role = msg['role'] == 'user' ? 'YOU' : 'CNA AI';
      final content = msg['content'] as String? ?? '';
      buffer.writeln('[$role]');
      buffer.writeln(content);
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Fluttertoast.showToast(
      msg: 'Conversation copied to clipboard',
      backgroundColor: const Color(0xFF10B981),
    );
  }

  void _showConversationHistory() async {
    final conversations = await _brainService.getConversations();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildHistorySheet(conversations),
    );
  }

  Widget _buildHistorySheet(List<Map<String, dynamic>> conversations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.outlineLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Conversation History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.mutedLight,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        if (conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No conversation history yet.',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.mutedLight,
                fontSize: 13,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: conversations.length,
              itemBuilder: (ctx, i) {
                final conv = conversations[i];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5F7A).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'chat',
                        color: const Color(0xFF1A5F7A),
                        size: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    conv['title'] as String? ?? 'Conversation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  subtitle: Text(
                    conv['created_at'] != null
                        ? _formatDate(conv['created_at'] as String)
                        : '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.mutedLight,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final id = conv['id'] as String;
                    final msgs = await _brainService.getMessages(id);
                    if (mounted) {
                      setState(() {
                        _conversationId = id;
                        _messages = msgs;
                        _showSuggestions = msgs.isEmpty;
                      });
                    }
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isInitializing
                  ? const CnaLoadingState(message: 'Initializing CNA Brain...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChatTab(),
                        const AiInsightDashboardWidget(),
                        _buildActionsTab(),
                        _buildMemoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
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
                  'CNA Brain',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Personal CFO · Finance Engine Connected',
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
          // History button
          GestureDetector(
            onTap: _showConversationHistory,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'history',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ),
            ),
          ),
          // Export button
          GestureDetector(
            onTap: _exportConversation,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'ios_share',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ),
            ),
          ),
          // New conversation button
          GestureDetector(
            onTap: _newConversation,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.outlineLight.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'add_comment',
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        labelColor: const Color(0xFF1A5F7A),
        unselectedLabelColor: AppTheme.mutedLight,
        indicatorColor: const Color(0xFF1A5F7A),
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'Chat'),
          Tab(text: 'Insights'),
          Tab(text: 'Actions'),
          Tab(text: 'Memory'),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _focusNode.unfocus(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount:
                  _messages.length +
                  (_showSuggestions && _messages.isEmpty ? 1 : 0) +
                  (_lastFailedMessage != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (_showSuggestions && _messages.isEmpty && index == 0) {
                  return _buildWelcomeAndSuggestions();
                }
                final offset = (_showSuggestions && _messages.isEmpty) ? 1 : 0;
                final msgIndex = index - offset;

                if (msgIndex < _messages.length) {
                  return _buildMessageBubble(_messages[msgIndex]);
                }

                // Retry banner
                if (_lastFailedMessage != null) {
                  return _buildRetryBanner();
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildRetryBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(50)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: const Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Message failed to send.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
          GestureDetector(
            onTap: _retryLastMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAndSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CNA Brain — Your Personal CFO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'I\'m connected to your Finance Engine — assets, loans, businesses, investments, and goals. Ask me anything about your financial world.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white.withAlpha(220),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildAgentChip('Financial Analyst', '💰'),
                  _buildAgentChip('Asset Intelligence', '🏗️'),
                  _buildAgentChip('Business Advisor', '📊'),
                  _buildAgentChip('Investment Analyst', '📈'),
                  _buildAgentChip('Debt Advisor', '💳'),
                  _buildAgentChip('Risk Guardian', '🛡️'),
                ],
              ),
            ],
          ),
        ),
        Text(
          'Try asking:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 10),
        ..._suggestedQuestions.map(
          (q) => GestureDetector(
            onTap: () => _sendMessage(q['text'] as String),
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
                      color: (q['color'] as Color).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: q['icon'] as String,
                        color: q['color'] as Color,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['text'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        Text(
                          q['agent'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: q['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.mutedLight,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAgentChip(String label, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Text(
        '$emoji $label',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final content = msg['content'] as String? ?? '';
    final isStreamingMsg = msg['streaming'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
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
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF1A5F7A)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.outlineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.isEmpty && isStreamingMsg)
                        _buildTypingDots()
                      else
                        Text(
                          content,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isUser
                                ? Colors.white
                                : AppTheme.onSurfaceLight,
                            height: 1.5,
                          ),
                        ),
                      if (isStreamingMsg && content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDot(0),
                              const SizedBox(width: 3),
                              _buildDot(150),
                              const SizedBox(width: 3),
                              _buildDot(300),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Copy button for AI messages
                if (!isUser && !isStreamingMsg && content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: GestureDetector(
                      onTap: () => _copyMessage(content),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'content_copy',
                            color: AppTheme.mutedLight,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Copy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(150),
        const SizedBox(width: 4),
        _buildDot(300),
      ],
    );
  }

  Widget _buildDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF2D9CDB),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final canSend = !_isLoading && !_isStreaming;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canSend
                      ? AppTheme.outlineLight
                      : AppTheme.outlineLight.withAlpha(100),
                ),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                enabled: canSend,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.onSurfaceLight,
                ),
                decoration: InputDecoration(
                  hintText: canSend
                      ? 'Ask your Personal CFO anything...'
                      : 'AI is thinking...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.mutedLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: canSend ? _sendMessage : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: canSend && _inputController.text.trim().isNotEmpty
                ? () => _sendMessage(_inputController.text)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: canSend && _inputController.text.trim().isNotEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                      )
                    : LinearGradient(
                        colors: [AppTheme.outlineLight, AppTheme.outlineLight],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isStreaming || _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'send',
                        color:
                            canSend && _inputController.text.trim().isNotEmpty
                            ? Colors.white
                            : AppTheme.mutedLight,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'auto_fix_high',
                    color: const Color(0xFF8B5CF6),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Action Center',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Review and approve AI-suggested actions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AiActionPanelWidget(
            actions: _pendingActions,
            onApprove: (id) async {
              await _brainService.approveAction(id);
              final actions = await _brainService.getPendingActions();
              if (mounted) setState(() => _pendingActions = actions);
              Fluttertoast.showToast(
                msg: 'Action approved',
                backgroundColor: const Color(0xFF10B981),
              );
            },
            onReject: (id) async {
              await _brainService.rejectAction(id);
              final actions = await _brainService.getPendingActions();
              if (mounted) setState(() => _pendingActions = actions);
              Fluttertoast.showToast(
                msg: 'Action rejected',
                backgroundColor: Colors.grey,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9CDB).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'memory',
                    color: const Color(0xFF2D9CDB),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Memory System',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Long-term preferences & patterns',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        'Clear AI Memory',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        'This will remove all stored preferences and patterns. Are you sure?',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _brainService.clearAllMemory();
                    Fluttertoast.showToast(
                      msg: 'AI memory cleared',
                      backgroundColor: const Color(0xFF10B981),
                    );
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AiMemoryPanelWidget(),
        ],
      ),
    );
  }
}
