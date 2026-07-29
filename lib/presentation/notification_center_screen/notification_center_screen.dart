import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/automation_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/cna_shared_components.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'value': 'all', 'icon': 'notifications'},
    {'label': 'Finance', 'value': 'finance', 'icon': 'account_balance_wallet'},
    {'label': 'Business', 'value': 'business', 'icon': 'business_center'},
    {'label': 'Loans', 'value': 'loan', 'icon': 'account_balance'},
    {'label': 'Assets', 'value': 'asset', 'icon': 'real_estate_agent'},
    {'label': 'Invest', 'value': 'investment', 'icon': 'trending_up'},
    {'label': 'AI', 'value': 'ai', 'icon': 'psychology'},
    {'label': 'Auto', 'value': 'automation', 'icon': 'bolt'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    // Try ESE notifications table first, fall back to automation service
    final eseNotifs = await _loadEseNotifications();
    final automationNotifs = await AutomationService.instance.getNotifications(
      filterType: _selectedCategory == 'all' ? null : _selectedCategory,
      filterStatus: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    // Merge and deduplicate by id
    final merged = <String, Map<String, dynamic>>{};
    for (final n in [...eseNotifs, ...automationNotifs]) {
      final id = n['id'] as String? ?? '';
      if (id.isNotEmpty) merged[id] = n;
    }

    if (mounted) {
      setState(() {
        _notifications = merged.values.toList()
          ..sort((a, b) {
            final aTime = a['created_at'] as String? ?? '';
            final bTime = b['created_at'] as String? ?? '';
            return bTime.compareTo(aTime);
          });
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadEseNotifications() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = client.from('notifications').select().eq('user_id', userId);

      if (_selectedCategory != 'all') {
        query = query.eq('notification_type', _selectedCategory);
      }
      if (_selectedStatus == 'unread') {
        query = query.eq('is_read', false);
      } else if (_selectedStatus == 'read') {
        query = query.eq('is_read', true);
      }

      final result = await query
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(result)
          .map(
            (n) => {
              ...n,
              'status': (n['is_read'] as bool? ?? false) ? 'read' : 'unread',
              'priority': n['priority'] ?? 'normal',
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (_) {}
    await AutomationService.instance.markNotificationRead(id);
    _loadNotifications();
  }

  Future<void> _markAllRead() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('is_read', false);
      }
    } catch (_) {}
    await AutomationService.instance.markAllNotificationsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await SupabaseService.client.from('notifications').delete().eq('id', id);
    } catch (_) {}
    await AutomationService.instance.deleteNotification(id);
    _loadNotifications();
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'normal':
        return const Color(0xFF2D9CDB);
      default:
        return AppTheme.mutedLight;
    }
  }

  Color _getCategoryColor(String? type) {
    switch (type) {
      case 'finance':
        return const Color(0xFF10B981);
      case 'business':
        return const Color(0xFF059669);
      case 'loan':
        return const Color(0xFF1A5F7A);
      case 'asset':
        return const Color(0xFF2D9CDB);
      case 'investment':
        return const Color(0xFF8B5CF6);
      case 'ai':
        return const Color(0xFF1A5F7A);
      case 'automation':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.mutedLight;
    }
  }

  String _getCategoryIcon(String? type) {
    switch (type) {
      case 'finance':
        return 'account_balance_wallet';
      case 'business':
        return 'business_center';
      case 'loan':
        return 'account_balance';
      case 'asset':
        return 'real_estate_agent';
      case 'investment':
        return 'trending_up';
      case 'ai':
        return 'psychology';
      case 'automation':
        return 'bolt';
      default:
        return 'notifications';
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_searchQuery.isEmpty) return _notifications;
    return _notifications.where((n) {
      final title = (n['title'] as String? ?? '').toLowerCase();
      final message = (n['message'] as String? ?? '').toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          message.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int get _unreadCount =>
      _notifications.where((n) => n['status'] == 'unread').length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A5F7A),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.outlineLight),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedLight,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.mutedLight,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: AppTheme.mutedLight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A5F7A)),
                ),
              ),
            ),
          ),
          // Category filter
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(
                        () => _selectedCategory = cat['value'] as String,
                      );
                      _loadNotifications();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A5F7A)
                            : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A5F7A)
                              : AppTheme.outlineLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: cat['icon'] as String,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.mutedLight,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Status filter
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildStatusFilter('All', 'all'),
                const SizedBox(width: 8),
                _buildStatusFilter('Unread', 'unread'),
                const SizedBox(width: 8),
                _buildStatusFilter('Read', 'read'),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.outlineLight),
          // Notifications list
          Expanded(
            child: _isLoading
                ? const CnaLoadingState(message: 'Loading notifications...')
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: AppTheme.mutedLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final notif = filtered[i];
                      final isUnread = notif['status'] == 'unread';
                      final catColor = _getCategoryColor(
                        notif['notification_type'] as String?,
                      );
                      final priorityColor = _getPriorityColor(
                        notif['priority'] as String?,
                      );

                      return Dismissible(
                        key: Key(notif['id'] as String),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        onDismissed: (_) =>
                            _deleteNotification(notif['id'] as String),
                        child: GestureDetector(
                          onTap: () => isUnread
                              ? _markRead(notif['id'] as String)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? catColor.withAlpha(8)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isUnread
                                    ? catColor.withAlpha(40)
                                    : AppTheme.outlineLight,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: _getCategoryIcon(
                                        notif['notification_type'] as String?,
                                      ),
                                      color: catColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'] as String? ?? '',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: isUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color:
                                                        AppTheme.onSurfaceLight,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: priorityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'] as String? ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.mutedLight,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: catColor.withAlpha(15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (notif['notification_type']
                                                          as String? ??
                                                      'general')
                                                  .toUpperCase(),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: catColor,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTime(
                                              notif['created_at'] as String?,
                                            ),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(String label, String value) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = value);
        _loadNotifications();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A5F7A).withAlpha(15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A5F7A) : AppTheme.outlineLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF1A5F7A) : AppTheme.mutedLight,
          ),
        ),
      ),
    );
  }
}
