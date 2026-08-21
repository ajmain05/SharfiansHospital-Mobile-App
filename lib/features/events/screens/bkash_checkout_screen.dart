import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// What the bKash checkout resolved to, parsed from the callback URL's query
/// params (`?paymentID=...&status=success|cancel|failure|declined`) — same
/// shape the website's `BkashCallback.jsx` reads.
class BkashCheckoutResult {
  final String paymentID;
  final String status;

  const BkashCheckoutResult({required this.paymentID, required this.status});

  bool get isSuccess => status == 'success';
}

/// Hosts bKash's tokenized checkout page in a webview and intercepts
/// navigation to the backend's callback URL instead of letting it load —
/// the callback page is meant for a browser, not this app, and everything
/// it would do (call `/bkash/execute-payment`) is done natively by the
/// caller once this screen pops with a [BkashCheckoutResult].
class BkashCheckoutScreen extends StatefulWidget {
  final String bkashUrl;
  final String callbackUrlPrefix;

  const BkashCheckoutScreen({
    super.key,
    required this.bkashUrl,
    required this.callbackUrlPrefix,
  });

  @override
  State<BkashCheckoutScreen> createState() => _BkashCheckoutScreenState();
}

class _BkashCheckoutScreenState extends State<BkashCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Only the main-frame load failing should block checkout —
            // a failed subresource (tracking pixel, font, etc.) shouldn't.
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() {
                _loading = false;
                _error = 'পেজ লোড করা যায়নি। ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।';
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.callbackUrlPrefix)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.bkashUrl));
  }

  void _retry() {
    setState(() {
      _error = null;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.bkashUrl));
  }

  void _handleCallback(String url) {
    if (_resolved) return;
    _resolved = true;
    final uri = Uri.parse(url);
    Navigator.of(context).pop(
      BkashCheckoutResult(
        paymentID: uri.queryParameters['paymentID'] ?? '',
        status: uri.queryParameters['status'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বিকাশ পেমেন্ট'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
