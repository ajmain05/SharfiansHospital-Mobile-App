import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../models/support_message.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../providers/support_provider.dart';
import 'support_list_screen.dart';

String _timeAgo(WidgetRef ref, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return t(ref, 'justNow');
  if (diff.inHours < 1) return t(ref, 'minutesAgo', params: {'count': '${diff.inMinutes}'});
  if (diff.inDays < 1) return t(ref, 'hoursAgo', params: {'count': '${diff.inHours}'});
  return t(ref, 'daysAgo', params: {'count': '${diff.inDays}'});
}

class SupportThreadScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const SupportThreadScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends ConsumerState<SupportThreadScreen> {
  final _replyCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  // Messages come back oldest-first, so the newest reply is the last item —
  // without tracking this, the list opens (and stays, after sending) at the
  // top instead of showing the most recent message.
  int _lastMessageCount = -1;

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markRead() async {
    final investorId = ref.read(investorSessionProvider).activeAccount?.id;
    if (investorId == null) return;
    // Fire-and-forget, same "viewing is the read action, fire on leave" idiom
    // as notifications_screen.dart — no need to block navigation on it.
    ref.read(supportRepositoryProvider).markRead(investorId, widget.ticketId);
    ref.invalidate(supportTicketsProvider);
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    final investorId = ref.read(investorSessionProvider).activeAccount?.id;
    if (investorId == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).postMessage(
            investorId: investorId,
            ticketId: widget.ticketId,
            message: text,
          );
      _replyCtrl.clear();
      ref.invalidate(supportTicketThreadProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(supportTicketThreadProvider(widget.ticketId));

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _markRead();
      },
      child: Scaffold(
        backgroundColor: context.bgFill,
        appBar: AppBar(
          backgroundColor: context.cardFill,
          elevation: 0,
          leading: BackButton(color: context.textHigh, onPressed: () => context.pop()),
          title: threadAsync.maybeWhen(
            data: (ticket) => Text(
              ticket.subject?.trim().isNotEmpty == true ? ticket.subject! : supportCategoryLabel(ref, ticket.category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: context.textHigh),
            ),
            orElse: () => Text(t(ref, 'myQueries'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: context.textHigh)),
          ),
        ),
        body: threadAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary700)),
          error: (err, _) => ErrorRetryView(
            message: t(ref, 'supportThreadLoadFailed'),
            onRetry: () => ref.invalidate(supportTicketThreadProvider(widget.ticketId)),
          ),
          data: (ticket) {
            final messages = ticket.messages ?? const <SupportMessage>[];
            final isOpenForReply = ticket.status != 'CLOSED';
            if (messages.length != _lastMessageCount) {
              _lastMessageCount = messages.length;
              _scrollToBottom();
            }
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: supportStatusColor(ticket.status).withValues(alpha: context.isDark ? 0.14 : 0.08),
                  child: Text(
                    supportStatusLabel(ref, ticket.status),
                    style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w800, color: supportStatusColor(ticket.status)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: messages[index]),
                  ),
                ),
                if (isOpenForReply)
                  Container(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + (MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : MediaQuery.of(context).padding.bottom)),
                    decoration: BoxDecoration(
                      color: context.cardFill,
                      border: Border(top: BorderSide(color: context.borderFill)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            minLines: 1,
                            maxLines: 4,
                            style: GoogleFonts.publicSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: t(ref, 'supportReplyHint'),
                              hintStyle: GoogleFonts.publicSans(color: context.textLow),
                              filled: true,
                              fillColor: context.cardFill3,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(backgroundColor: AppColors.primary700),
                          icon: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final SupportMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromAdmin = message.isFromAdmin;
    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fromAdmin ? context.cardFill3 : AppColors.primary700,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fromAdmin && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName!,
                  style: GoogleFonts.publicSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary700),
                ),
              ),
            Text(
              message.message,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fromAdmin ? context.textHigh : Colors.white,
                height: 1.35,
              ),
            ),
            if (message.attachmentUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () {
                    final uri = Uri.tryParse(message.attachmentUrl!);
                    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file_rounded, size: 14, color: fromAdmin ? AppColors.primary700 : Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        t(ref, 'supportViewAttachment'),
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          color: fromAdmin ? AppColors.primary700 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _timeAgo(ref, message.createdAt),
              style: GoogleFonts.publicSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: fromAdmin ? context.textLow : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
