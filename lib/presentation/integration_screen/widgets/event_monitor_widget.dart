import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class EventMonitorWidget extends StatefulWidget {
  const EventMonitorWidget({super.key});

  @override
  State<EventMonitorWidget> createState() => _EventMonitorWidgetState();
}

class _EventMonitorWidgetState extends State<EventMonitorWidget> {
  final List<CnaEvent> _events = [];
  bool _listening = false;

  final _eventTypes = [
    EventBus.financeTransactionCreated,
    EventBus.loanPaymentCompleted,
    EventBus.assetCreated,
    EventBus.businessUpdated,
    EventBus.investmentReturnReceived,
    EventBus.forecastGenerated,
    EventBus.aiRecommendationCreated,
    EventBus.workflowCompleted,
    EventBus.integrationConnected,
    EventBus.webhookReceived,
    EventBus.importCompleted,
    EventBus.exportCompleted,
  ];

  @override
  void initState() {
    super.initState();
    _startListening();
    _publishDemoEvents();
  }

  void _startListening() {
    setState(() => _listening = true);
    EventBus.instance.subscribe('*', _onEvent);
  }

  void _onEvent(CnaEvent event) {
    if (mounted) {
      setState(() {
        _events.insert(0, event);
        if (_events.length > 50) _events.removeLast();
      });
    }
  }

  void _publishDemoEvents() {
    Future.delayed(const Duration(milliseconds: 500), () {
      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.integrationConnected,
          entityType: 'integration',
          payload: {'provider': 'Sample Bank', 'status': 'connected'},
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.webhookReceived,
          entityType: 'webhook_event',
          payload: {
            'provider': 'M-Pesa',
            'event': 'payment.received',
            'amount': 500000,
          },
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      EventBus.instance.publish(
        CnaEvent(
          eventType: EventBus.importCompleted,
          entityType: 'import_job',
          payload: {'file': 'transactions_q1.csv', 'records': 245},
        ),
      );
    });
  }

  @override
  void dispose() {
    EventBus.instance.unsubscribe('*', _onEvent);
    super.dispose();
  }

  Color _eventColor(String eventType) {
    if (eventType.startsWith('Finance')) return const Color(0xFF10B981);
    if (eventType.startsWith('Loan')) return const Color(0xFFEF4444);
    if (eventType.startsWith('Asset')) return const Color(0xFF2D9CDB);
    if (eventType.startsWith('Business')) return const Color(0xFF059669);
    if (eventType.startsWith('Investment')) return const Color(0xFFF59E0B);
    if (eventType.startsWith('AI')) return const Color(0xFF8B5CF6);
    if (eventType.startsWith('Integration')) return const Color(0xFF1A5F7A);
    if (eventType.startsWith('Webhook')) return const Color(0xFFF59E0B);
    if (eventType.startsWith('Import') || eventType.startsWith('Export')) {
      return const Color(0xFF2D9CDB);
    }
    return AppTheme.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Event bus status
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _listening
                        ? const Color(0xFF10B981)
                        : AppTheme.mutedLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CNA Event Bus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      Text(
                        _listening ? 'Listening for events...' : 'Stopped',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_events.length} events',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Event type legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Registered Event Types (${_eventTypes.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _eventTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final et = _eventTypes[i];
              final color = _eventColor(et);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Text(
                  et,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Live Event Stream',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'sensors',
                        color: AppTheme.mutedLight,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting for events...',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final event = _events[i];
                    final color = _eventColor(event.eventType);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.eventType,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  event.payload.entries
                                      .take(2)
                                      .map((e) => '${e.key}: ${e.value}')
                                      .join(' · '),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.mutedLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _timeAgo(event.timestamp),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
