import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/integration_service.dart';

class WebhookMonitorWidget extends StatefulWidget {
  const WebhookMonitorWidget({super.key});

  @override
  State<WebhookMonitorWidget> createState() => _WebhookMonitorWidgetState();
}

class _WebhookMonitorWidgetState extends State<WebhookMonitorWidget> {
  final _service = IntegrationService.instance;
  List<WebhookEvent> _events = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getWebhookEvents();
    if (mounted) {
      setState(() {
        _events = data;
        _loading = false;
      });
    }
  }

  List<WebhookEvent> get _filtered {
    if (_filter == 'pending') {
      return _events.where((e) => !e.processed).toList();
    }
    if (_filter == 'processed') {
      return _events.where((e) => e.processed).toList();
    }
    return _events;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final pending = _events.where((e) => !e.processed).length;

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _statChip(
                'Total',
                _events.length.toString(),
                AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              _statChip('Pending', pending.toString(), const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _statChip(
                'Processed',
                (_events.length - pending).toString(),
                const Color(0xFF10B981),
              ),
            ],
          ),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['all', 'pending', 'processed'].map((f) {
              final sel = _filter == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: EdgeInsets.only(right: f != 'processed' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryLight
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryLight
                            : AppTheme.outlineLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.mutedLight,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'No webhook events',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = _filtered[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: event.processed
                              ? AppTheme.outlineLight
                              : const Color(0xFFF59E0B).withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: event.processed
                                    ? 'check_circle'
                                    : 'pending',
                                color: event.processed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.eventName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                              ),
                              if (!event.processed)
                                GestureDetector(
                                  onTap: () async {
                                    await _service.processWebhookEvent(
                                      event.id,
                                    );
                                    _load();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight.withAlpha(
                                        20,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Process',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryLight,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Provider: ${event.providerName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.payload.entries
                                  .take(3)
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(' · '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.mutedLight,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  Widget _statChip(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
    ),
  );
}
