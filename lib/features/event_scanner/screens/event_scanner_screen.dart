import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../data/scanner_repository.dart';

final scannerRepoProvider = Provider((ref) => ScannerRepository());

class EventScannerScreen extends ConsumerStatefulWidget {
  const EventScannerScreen({super.key});

  @override
  ConsumerState<EventScannerScreen> createState() => _EventScannerScreenState();
}

class _EventScannerScreenState extends ConsumerState<EventScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!;
    // Extract token (either full url or raw 40 char hex)
    String token = rawValue;
    final match = RegExp(r'/events/status/([a-f0-9]{40})').firstMatch(rawValue);
    if (match != null) {
      token = match.group(1)!;
    } else {
      token = rawValue.trim();
    }

    setState(() => _isProcessing = true);
    
    try {
      final repo = ref.read(scannerRepoProvider);
      final result = await repo.scanQrCode(token);
      
      setState(() {});
      _showResultBottomSheet(result);
      
    } catch (e) {
      // General error
      final errResult = {
        'scanResult': 'INVALID',
        'message': e.toString(),
      };
      setState(() {});
      _showResultBottomSheet(errResult);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _openLiveDashboard() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(scannerRepoProvider);
      final activeEvent = await repo.getActiveEvent();
      if (activeEvent != null && activeEvent['id'] != null) {
        if (!mounted) return;
        context.push('/admin/live-dashboard/${activeEvent['id']}');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active event found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResultBottomSheet(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scanResult = result['scanResult'] as String?;
        final message = result['message'] as String?;
        final data = result['data'] as Map<String, dynamic>?;

        final isDark = context.isDark;
        Color bgColor;
        Color iconColor;
        IconData iconData;

        switch (scanResult) {
          case 'SUCCESS':
            bgColor = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
            iconColor = Colors.green;
            iconData = Icons.check_circle;
            break;
          case 'ALREADY_SCANNED':
            bgColor = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
            iconColor = Colors.orange;
            iconData = Icons.warning;
            break;
          case 'NOT_APPROVED':
            bgColor = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
            iconColor = Colors.red;
            iconData = Icons.block;
            break;
          default:
            bgColor = isDark ? Colors.pink.withValues(alpha: 0.15) : Colors.pink.shade50;
            iconColor = Colors.pink;
            iconData = Icons.cancel;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 64, color: iconColor),
              const SizedBox(height: 16),
              Text(
                message ?? 'Unknown result',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withValues(alpha: 0.8),
                ),
              ),
              if (data != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Name', data['name']),
                      const Divider(),
                      _buildDetailRow(context, 'Persons', '${data['personsCount']}'),
                      if (data['event'] != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Event', data['event']['title']),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Re-enable scanning
                    setState(() {});
                  },
                  child: Text(t(ref, 'scanNextTicket'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textMed, fontWeight: FontWeight.w500)),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(t(ref, 'eventScanner')),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: Colors.blueAccent),
            tooltip: t(ref, 'liveDashboard'),
            onPressed: _openLiveDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleScan,
          ),
          
          // Scanner Overlay Mask
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(
                  borderColor: Colors.blueAccent,
                  borderWidth: 4,
                  overlayColor: Colors.black54,
                  borderRadius: 24,
                  borderLength: 40,
                  cutOutSize: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),
          ),
          
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(t(ref, 'verifyingTicket'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final localCutOutSize = cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      width / 2 - localCutOutSize / 2,
      height / 2 - localCutOutSize / 2,
      localCutOutSize,
      localCutOutSize,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Draw borders
    final path = Path();
    
    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.quadraticBezierTo(
      cutOutRect.left, cutOutRect.top, 
      cutOutRect.left + borderLength, cutOutRect.top
    );
    
    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.quadraticBezierTo(
      cutOutRect.right, cutOutRect.top, 
      cutOutRect.right, cutOutRect.top + borderLength
    );
    
    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.quadraticBezierTo(
      cutOutRect.right, cutOutRect.bottom, 
      cutOutRect.right - borderLength, cutOutRect.bottom
    );
    
    // Bottom left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.quadraticBezierTo(
      cutOutRect.left, cutOutRect.bottom, 
      cutOutRect.left, cutOutRect.bottom - borderLength
    );
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
