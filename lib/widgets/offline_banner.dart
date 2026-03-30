import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _sync = SyncService();
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  bool _isOnline = true;
  bool _showSyncedMsg = false;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isConnected;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    if (!_isOnline) _animController.forward();

    _connectivity.connectivityStream.listen((isOnline) async {
      if (!mounted) return;
      setState(() => _isOnline = isOnline);
      if (isOnline) {
        // Show "syncing" briefly then hide
        final synced = await _sync.syncPendingOperations();
        if (synced > 0 && mounted) {
          setState(() => _showSyncedMsg = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _showSyncedMsg = false);
        }
        _animController.reverse();
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        if (_animController.isDismissed && _isOnline && !_showSyncedMsg) {
          return const SizedBox.shrink();
        }
        return FractionalTranslation(
          translation: Offset(0, _slideAnim.value),
          child: _buildBanner(),
        );
      },
    );
  }

  Widget _buildBanner() {
    if (_showSyncedMsg) {
      return _banner(
        color: Colors.green.shade700,
        icon: Icons.cloud_done,
        message: '✅ Data tersinkronisasi!',
      );
    }
    if (!_isOnline) {
      final pending = _sync.pendingCount;
      return _banner(
        color: const Color(0xFFDC2626),
        icon: Icons.wifi_off,
        message: pending > 0
            ? '📴 Offline — $pending perubahan menunggu sinkronisasi'
            : '📴 Tidak ada koneksi internet',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
