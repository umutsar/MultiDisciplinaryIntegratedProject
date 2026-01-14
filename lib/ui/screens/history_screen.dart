import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_loading.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_error.dart';
import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/services/vehicle_api_service.dart';

/// HistoryScreen saatlik geçmiş araç sayısı verilerini listeleyen ekrandır.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> _dateOptions = <String>['Today', 'Yesterday'];
  String _selectedDate = 'Today';

  bool _loading = false;
  List<HistoryItem> _items = <HistoryItem>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Mock API'den tarihsel veriyi çeker, loading ve hata durumlarını yönetir.
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<HistoryItem> data = await fetchHistory(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bir şeyler ters gitti, lütfen tekrar deneyin.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
                  'Date:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedDate,
                  items: _dateOptions
                      .map(
                        (o) => DropdownMenuItem<String>(
                          value: o,
                          child: Text(o),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedDate = val;
                    });
                    // Mock için veri aynı; seçim değiştiğinde yine de yenileyelim
                    _loadHistory();
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
              child: Container(
                height: 140,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Graph Placeholder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoading())
                  : _error != null
                      ? Center(
                          child: AppError(
                            message: _error!,
                            onRetry: _loadHistory,
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Text(
                                'No data',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final HistoryItem item = _items[index];
                                final String time = item.time;
                                final int count = item.count;
                                return ListTile(
                                  title: Text(
                                    time,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  trailing: Text(
                                    count.toString(),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  visualDensity: VisualDensity.compact,
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


