import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_loading.dart';
import 'package:ai_vehicle_counter/ui/widgets/app_error.dart';
import 'package:ai_vehicle_counter/ui/widgets/pulsing_dot.dart';
import 'package:ai_vehicle_counter/services/vehicle_api_service.dart';

/// HomeScreen canlı araç sayısını ve son güncellenme zamanını gösteren ana ekrandır.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _vehicleCount = 0;
  DateTime? _lastUpdate;
  bool _loading = false;
  bool _polling = false;
  String? _errorKey; // internal: non-user-facing sentinel
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCount();

    // Home ekranında periyodik otomatik güncelleme (0.5 saniyede bir).
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _pollCount();
    });
  }

  /// Araç sayısını GET endpoint'inden yükler, loading ve hata durumlarını yönetir.
  Future<void> _loadCount() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final vc = await fetchLatestVehicleCount();
      if (!mounted) return;
      setState(() {
        _vehicleCount = vc.count;
        _lastUpdate = vc.timestamp;
        _errorKey = null;
      });
    } catch (e) {
      if (!mounted) return;
      // UI'yı error'a boğmamak için: sadece ilk hatada error state'ine geç.
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

  /// Arka planda sayıyı periyodik olarak çeker.
  ///
  /// - Loading state'i değiştirmez (UI flicker olmasın)
  /// - Hata olduğunda UI'ı sürekli error state'ine taşımamak için sadece ilk hatayı gösterir
  /// - Başarıda error'ı temizler, sayı değişmişse count + lastUpdate günceller
  Future<void> _pollCount() async {
    if (_loading || _polling) return;
    _polling = true;
    try {
      final vc = await fetchLatestVehicleCount();
      if (!mounted) return;

      final bool shouldClearError = _errorKey != null;
      final bool shouldUpdateCount = vc.count != _vehicleCount;
      final bool shouldUpdateTimestamp = vc.timestamp != _lastUpdate;

      if (shouldClearError || shouldUpdateCount || shouldUpdateTimestamp) {
        setState(() {
          if (shouldUpdateCount) {
            _vehicleCount = vc.count;
          }
          if (shouldUpdateTimestamp) {
            _lastUpdate = vc.timestamp;
          }
          if (shouldClearError) {
            _errorKey = null;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      // UI'yı error'a boğmamak için: sadece ilk hatada error state'ine geç.
      if (_errorKey == null) {
        setState(() {
          _errorKey = 'generic';
        });
      }
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--:--';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.home_outlined),
        title: Text(l10n.home),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_errorKey != null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: AppError(
                      message: l10n.genericError,
                      onRetry: _loading ? null : _loadCount,
                    ),
                  ),
                )
              else
                Material(
                  elevation: 10,
                  shadowColor: scheme.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.55, 1.0],
                        colors: isDark
                            ? const [
                                Color(0xFF1B2A55), // slate/indigo
                                Color(0xFF2F80ED), // electric blue
                                Color(0xFF00D1B2), // teal
                              ]
                            : [
                                const Color(0xFF2F80ED), // electric blue
                                Color.lerp(
                                      scheme.primary,
                                      scheme.secondary,
                                      0.55,
                                    )!
                                    .withValues(alpha: 0.96),
                                const Color(0xFF14B8A6), // softer teal
                              ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const PulsingDot(),
                            const SizedBox(width: 10),
                            Text(
                              l10n.vehicleCount,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(child: AppLoading(size: 44)),
                          )
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                _vehicleCount.toString(),
                                key: ValueKey<int>(_vehicleCount),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 64,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            '${l10n.lastUpdate}: ${_formatTime(_lastUpdate)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _loadCount,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                    backgroundColor: scheme.surface.withValues(alpha: 0.65),
                    foregroundColor: scheme.onSurface,
                    elevation: 8,
                    shadowColor: scheme.primary.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


