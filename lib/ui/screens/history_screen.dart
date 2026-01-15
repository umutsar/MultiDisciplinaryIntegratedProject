import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_loading.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_error.dart';
import 'package:ai_vehicle_counter/ui/widgets/history_mini_chart.dart';
import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/services/vehicle_api_service.dart';

enum _HistoryDateFilter { today, yesterday }

/// HistoryScreen saatlik geçmiş araç sayısı verilerini listeleyen ekrandır.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<_HistoryDateFilter> _dateOptions = <_HistoryDateFilter>[
    _HistoryDateFilter.today,
    _HistoryDateFilter.yesterday,
  ];
  _HistoryDateFilter _selectedDate = _HistoryDateFilter.today;

  bool _loading = false;
  bool _polling = false;
  List<HistoryItem> _items = <HistoryItem>[];
  String? _errorKey; // internal: non-user-facing sentinel
  Timer? _timer;

  List<HistoryItem> get _filteredItems {
    if (_items.isEmpty) return _items;

    final now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime targetDay =
        _selectedDate == _HistoryDateFilter.yesterday ? today.subtract(const Duration(days: 1)) : today;

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return _items.where((e) => isSameDay(e.timestamp, targetDay)).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();

    // Periyodik arka plan yenileme (UI flicker olmasın diye loading state'i kullanmaz)
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _pollHistory();
    });
  }

  /// Mock API'den tarihsel veriyi çeker, loading ve hata durumlarını yönetir.
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final List<HistoryItem> data = await fetchHistory(limit: 100);
      if (!mounted) return;
      setState(() {
        _items = data;
        _errorKey = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_errorKey == null) {
        setState(() {
          _errorKey = 'generic';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollHistory() async {
    if (_loading || _polling) return;
    _polling = true;
    try {
      final List<HistoryItem> data = await fetchHistory(limit: 100);
      if (!mounted) return;

      final bool shouldClearError = _errorKey != null;
      final bool shouldUpdate = !_listEquals(_items, data);

      if (shouldClearError || shouldUpdate) {
        setState(() {
          if (shouldUpdate) _items = data;
          if (shouldClearError) _errorKey = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (_errorKey == null) {
        setState(() {
          _errorKey = 'generic';
        });
      }
    } finally {
      _polling = false;
    }
  }

  bool _listEquals(List<HistoryItem> a, List<HistoryItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].count != b[i].count ||
          a[i].time != b[i].time ||
          a[i].timestamp.millisecondsSinceEpoch != b[i].timestamp.millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  }

  Future<void> _confirmAndClearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHistory),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await clearHistory();
      if (!mounted) return;
      setState(() {
        _items = <HistoryItem>[];
        _errorKey = null;
      });
      // Silme sonrası tekrar çekelim (DB temiz mi doğrulansın)
      _loadHistory();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyDeleteFailed)),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.history_outlined),
        title: Text(l10n.history),
        actions: [
          IconButton(
            tooltip: l10n.deleteHistory,
            icon: const Icon(Icons.delete_outline),
            onPressed: _loading ? null : _confirmAndClearHistory,
          ),
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '${l10n.date}:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<_HistoryDateFilter>(
                  value: _selectedDate,
                  items: _dateOptions
                      .map(
                        (o) => DropdownMenuItem<_HistoryDateFilter>(
                          value: o,
                          child: Text(
                            o == _HistoryDateFilter.yesterday
                                ? l10n.yesterday
                                : l10n.today,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedDate = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _loading
                  ? const SizedBox(height: 140, child: Center(child: AppLoading()))
                  : _errorKey != null
                      ? const SizedBox(height: 140)
                      : HistoryMiniChart(items: _filteredItems, height: 140),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoading())
                  : _errorKey != null
                      ? Center(
                          child: AppError(
                            message: l10n.genericError,
                            onRetry: _loadHistory,
                          ),
                        )
                      : _filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noData,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final HistoryItem item = _filteredItems[index];
                                final String time = item.time;
                                final int count = item.count;
                                return Card(
                                  elevation: 6,
                                  shadowColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 0,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.secondary
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          time,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          count.toString(),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}


