import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_loading.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_error.dart';
import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/services/vehicle_api_service.dart';

/// HomeScreen canlı araç sayısını ve son güncellenme zamanını gösteren ana ekrandır.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _vehicleCount = 0;
  DateTime _lastUpdate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  /// Mock API'den araç sayısını yükler, loading ve hata durumlarını yönetir.
  Future<void> _loadCount() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final VehicleCount result = await fetchLatestVehicleCount();
      if (!mounted) return;
      setState(() {
        _vehicleCount = result.count;
        _lastUpdate = result.timestamp;
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

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadCount,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_error != null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: AppError(
                      message: _error!,
                      onRetry: _loading ? null : _loadCount,
                    ),
                  ),
                )
              else
                Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_loading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AppLoading(size: 40),
                        )
                      else
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.98, end: 1.0)
                                    .animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _vehicleCount.toString(),
                            key: ValueKey<int>(_vehicleCount),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Last update: ${_formatTime(_lastUpdate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _loadCount,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


