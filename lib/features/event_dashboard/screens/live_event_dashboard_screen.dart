import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/config/env.dart';
import '../../event_scanner/screens/event_scanner_screen.dart';

class LiveEventDashboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  const LiveEventDashboardScreen({super.key, required this.eventId});

  @override
  ConsumerState<LiveEventDashboardScreen> createState() => _LiveEventDashboardScreenState();
}

class _LiveEventDashboardScreenState extends ConsumerState<LiveEventDashboardScreen> {
  late io.Socket socket;
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _connectSocket();
  }

  Future<void> _fetchStats() async {
    final repo = ref.read(scannerRepoProvider);
    final data = await repo.getLiveStats(widget.eventId);
    if (mounted) {
      setState(() {
        stats = data;
        isLoading = false;
      });
    }
  }

  void _connectSocket() {
    final baseUrl = Env.apiBaseUrl.replaceAll('/api', '');
    
    socket = io.io(baseUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket server');
    });

    socket.on('event_stats_update', (data) {
      if (data != null && data['eventId'] == widget.eventId) {
        _fetchStats();
      }
    });

    socket.onDisconnect((_) => debugPrint('Disconnected from WebSocket server'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB), // gray 50
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t(ref, 'liveDashboard'))),
        body: const Center(child: Text('Failed to load stats')),
      );
    }

    final int expectedCount = stats!['approvedCount'] ?? 0;
    final int arrivedCount = stats!['arrivedCount'] ?? 0;
    final int remainingCount = stats!['expectedRemaining'] ?? 0;
    
    final int attendanceRate = expectedCount > 0 
        ? ((arrivedCount / expectedCount) * 100).round() 
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: Colors.grey.shade800,
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t(ref, 'liveDashboard').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              stats!['eventTitle'] ?? 'Event',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // Progress Bar Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(ref, 'checkInActivity'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(ref, 'eventIsLive'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$arrivedCount / $expectedCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 16,
                      color: Colors.grey.shade100,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: expectedCount > 0 ? (arrivedCount / expectedCount).clamp(0.0, 1.0) : 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.tealAccent, Colors.greenAccent, Colors.green],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stat Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  title: t(ref, 'expected'),
                  value: '$expectedCount',
                  gradient: [Colors.blue.shade50, Colors.transparent],
                  textColor: Colors.blueAccent,
                ),
                _StatCard(
                  title: t(ref, 'arrived'),
                  value: '$arrivedCount',
                  gradient: [Colors.green.shade50, Colors.transparent],
                  textColor: Colors.green,
                ),
                _StatCard(
                  title: t(ref, 'remaining'),
                  value: '$remainingCount',
                  gradient: [Colors.amber.shade50, Colors.transparent],
                  textColor: Colors.amber.shade700,
                ),
                _StatCard(
                  title: t(ref, 'attendanceRate'),
                  value: '$attendanceRate%',
                  gradient: [Colors.purple.shade50, Colors.transparent],
                  textColor: Colors.purpleAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradient;
  final Color textColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.gradient,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
