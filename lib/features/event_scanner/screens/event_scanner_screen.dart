import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/investor_category.dart';
import '../data/scanner_repository.dart';

final scannerRepoProvider = Provider((ref) => ScannerRepository());

class EventScannerScreen extends ConsumerStatefulWidget {
  const EventScannerScreen({super.key});

  @override
  ConsumerState<EventScannerScreen> createState() => _EventScannerScreenState();
}

class _EventScannerScreenState extends ConsumerState<EventScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late final AnimationController _scanLineController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanLineController.dispose();
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
    // Stop the camera immediately — otherwise it keeps detecting the same
    // still-in-frame code while the result sheet is up and re-triggers this
    // handler several times before the staff can move the phone away.
    await _scannerController.stop();

    try {
      final repo = ref.read(scannerRepoProvider);
      final result = await repo.scanQrCode(token);

      setState(() {});
      _showResultBottomSheet(result);
    } catch (e) {
      // General error
      final errResult = {'scanResult': 'INVALID', 'message': e.toString()};
      setState(() {});
      _showResultBottomSheet(errResult);
    } finally {
      setState(() => _isProcessing = false);
    }
  }


  void _showResultBottomSheet(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ScanResultSheet(
        result: result,
        onScanNext: () {
          Navigator.pop(sheetContext);
          // Resume the camera, stopped in _handleScan while this result was
          // showing.
          _scannerController.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F14),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(
          t(ref, 'eventScanner'),
          style: GoogleFonts.publicSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          _GlassIconButton(
            icon: Icons.flip_camera_ios_rounded,
            onPressed: () => _scannerController.switchCamera(),
          ),
          _GlassIconButton(
            icon: Icons.flash_on_rounded,
            onPressed: () => _scannerController.toggleTorch(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final cutOutSize = w * 0.7;
          final cutOutRect = Rect.fromLTWH(
            (w - cutOutSize) / 2,
            (h - cutOutSize) / 2,
            cutOutSize,
            cutOutSize,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleScan,
              ),

              // Scanner overlay mask
              Positioned.fill(
                child: Container(
                  decoration: ShapeDecoration(
                    shape: _ScannerOverlayShape(
                      borderColor: Colors.white,
                      borderWidth: 4,
                      overlayColor: Colors.black.withValues(alpha: 0.6),
                      borderRadius: 24,
                      borderLength: 36,
                      cutOutSize: cutOutSize,
                    ),
                  ),
                ),
              ),

              // Animated scan line sweeping inside the cutout
              AnimatedBuilder(
                animation: _scanLineController,
                builder: (context, child) {
                  final travel = cutOutRect.height - 4;
                  return Positioned(
                    left: cutOutRect.left + 4,
                    top:
                        cutOutRect.top + 2 + travel * _scanLineController.value,
                    width: cutOutRect.width - 8,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary400,
                            AppColors.accent400,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary400.withValues(alpha: 0.7),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Helper hint below the cutout
              Positioned(
                left: 0,
                right: 0,
                top: cutOutRect.bottom + 24,
                child: Text(
                  t(ref, 'scanPositionHint'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.publicSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),

              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 26,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1F2937,
                          ).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t(ref, 'verifyingTicket'),
                              style: GoogleFonts.publicSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Small frosted-glass circular icon button used in the scanner's AppBar.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final Color? iconColor;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Visual styling for a single scan-result status (color, icon, label).
class _StatusStyle {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String Function(WidgetRef ref) label;

  const _StatusStyle({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
  });
}

_StatusStyle _statusStyleFor(String? scanResult, bool isDark) {
  switch (scanResult) {
    case 'SUCCESS':
      const fg = Color(0xFF0E9E6F);
      return _StatusStyle(
        bg: isDark ? fg.withValues(alpha: 0.18) : const Color(0xFFE5F8F0),
        fg: fg,
        icon: Icons.check_circle_rounded,
        label: (ref) => t(ref, 'scanStatusApproved'),
      );
    case 'ALREADY_SCANNED':
      final fg = isDark ? AppColors.accent400 : AppColors.accent700;
      return _StatusStyle(
        bg: isDark
            ? AppColors.accent700.withValues(alpha: 0.2)
            : const Color(0xFFFEF3C7),
        fg: fg,
        icon: Icons.history_rounded,
        label: (ref) => t(ref, 'scanStatusAlreadyScanned'),
      );
    case 'NOT_APPROVED':
      final fg = isDark ? const Color(0xFFF87171) : AppColors.error;
      return _StatusStyle(
        bg: isDark
            ? AppColors.error.withValues(alpha: 0.18)
            : const Color(0xFFFEF2F2),
        fg: fg,
        icon: Icons.block_rounded,
        label: (ref) => t(ref, 'scanStatusNotApproved'),
      );
    default:
      final fg = isDark ? const Color(0xFFF87171) : AppColors.error;
      return _StatusStyle(
        bg: isDark
            ? AppColors.error.withValues(alpha: 0.18)
            : const Color(0xFFFEF2F2),
        fg: fg,
        icon: Icons.error_rounded,
        label: (ref) => t(ref, 'scanStatusInvalid'),
      );
  }
}

class _ScanResultSheet extends ConsumerWidget {
  final Map<String, dynamic> result;
  final VoidCallback onScanNext;

  const _ScanResultSheet({required this.result, required this.onScanNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanResult = result['scanResult'] as String?;
    final message = result['message'] as String?;
    final data = result['data'] as Map<String, dynamic>?;
    final style = _statusStyleFor(scanResult, context.isDark);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: context.borderFill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: style.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: 42, color: style.fg),
            ),
            const SizedBox(height: 18),
            Text(
              style.label(ref),
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: style.fg,
              ),
            ),
            if (message != null && message.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textMed,
                ),
              ),
            ],
            if (data != null) ...[
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardFill2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (data['name'] != null)
                      _DetailRow(
                        icon: Icons.person_rounded,
                        labelKey: 'scanDetailName',
                        value: data['name'].toString(),
                      ),
                    if (data['investorBadge'] is Map) ...[
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final badge = data['investorBadge'] as Map;
                        final isInvestor = badge['isInvestor'] == true;
                        final tierId = badge['tierId'] as String?;
                        final category = isInvestor
                            ? InvestorCategory.tiers.firstWhere(
                                (c) => c.id == tierId,
                                orElse: () => InvestorCategory.regular,
                              )
                            : InvestorCategory.regular;
                        return _DetailRow(
                          icon: isInvestor
                              ? Icons.workspace_premium_rounded
                              : Icons.person_outline_rounded,
                          labelKey: 'scanDetailInvestorStatus',
                          value: isInvestor
                              ? (badge['tierLabel'] as String? ?? '')
                              : t(ref, 'nonInvestor'),
                          valueColor: isInvestor ? category.color : null,
                        );
                      }),
                    ],
                    if (data['personsCount'] != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.groups_rounded,
                        labelKey: 'scanDetailPersons',
                        value: '${data['personsCount']}',
                      ),
                    ],
                    if (data['event'] is Map &&
                        data['event']['title'] != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.event_rounded,
                        labelKey: 'scanDetailEvent',
                        value: data['event']['title'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.fg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onScanNext,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  t(ref, 'scanNextTicket'),
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends ConsumerWidget {
  final IconData icon;
  final String labelKey;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.labelKey,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textMed),
        const SizedBox(width: 10),
        Text(
          t(ref, labelKey),
          style: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textMed,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.textHigh,
            ),
          ),
        ),
      ],
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
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
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
      cutOutRect.left,
      cutOutRect.top,
      cutOutRect.left + borderLength,
      cutOutRect.top,
    );

    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.quadraticBezierTo(
      cutOutRect.right,
      cutOutRect.top,
      cutOutRect.right,
      cutOutRect.top + borderLength,
    );

    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.quadraticBezierTo(
      cutOutRect.right,
      cutOutRect.bottom,
      cutOutRect.right - borderLength,
      cutOutRect.bottom,
    );

    // Bottom left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.quadraticBezierTo(
      cutOutRect.left,
      cutOutRect.bottom,
      cutOutRect.left,
      cutOutRect.bottom - borderLength,
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
