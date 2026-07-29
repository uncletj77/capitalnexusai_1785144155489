import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/integration_service.dart';

class IntegrationLogsWidget extends StatefulWidget {
  const IntegrationLogsWidget({super.key});

  @override
  State<IntegrationLogsWidget> createState() => _IntegrationLogsWidgetState();
}

class _IntegrationLogsWidgetState extends State<IntegrationLogsWidget> {
  final _service = IntegrationService.instance;
  List<IntegrationLog> _logs = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getIntegrationLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _loading = false;
      });
    }
  }

  List<IntegrationLog> get _filtered {
    if (_filter == 'success') {
      return _logs.where((l) => l.status == 'success').toList();
    }
    if (_filter == 'error') {
      return _logs.where((l) => l.status == 'error').toList();
    }
    return _logs;
  }

  Color _statusColor(String status) =>
      status == 'success' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final successCount = _logs.where((l) => l.status == 'success').length;
    final errorCount = _logs.where((l) => l.status == 'error').length;
    final avgDuration = _logs.isEmpty
        ? 0
        : (_logs.map((l) => l.durationMs).reduce((a, b) => a + b) /
                  _logs.length)
              .round();

    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _summaryCard(
                'Success',
                successCount.toString(),
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _summaryCard(
                'Errors',
                errorCount.toString(),
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _summaryCard(
                'Avg ms',
                avgDuration.toString(),
                const Color(0xFF2D9CDB),
              ),
            ],
          ),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['all', 'success', 'error'].map((f) {
              final sel = _filter == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: EdgeInsets.only(right: f != 'error' ? 8 : 0),
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
                    'No logs found',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedLight,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final log = _filtered[i];
                    final statusColor = _statusColor(log.status);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.outlineLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.requestType
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                                if (log.errorMessage != null)
                                  Text(
                                    log.errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: const Color(0xFFEF4444),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${log.responseCode}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                              Text(
                                '${log.durationMs}ms',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppTheme.mutedLight,
                                ),
                              ),
                            ],
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

  Widget _summaryCard(String label, String value, Color color) => Expanded(
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