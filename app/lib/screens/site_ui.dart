import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../theme.dart';
import 'ui.dart';

/// Opens a web page, WhatsApp chat or booking link outside the app.
Future<void> openLink(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showError(context, 'Could not open the link');
  } catch (_) {
    if (context.mounted) showError(context, 'Could not open the link');
  }
}

String rupees(int amount) => '₹$amount';

String statusLabel(String status) {
  switch (status) {
    case kStatusDraft:
      return 'Draft';
    case kStatusSubmitted:
      return 'Submitted';
    case kStatusDraftReady:
      return 'Draft ready';
    default:
      return 'Approved';
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case kStatusDraft:
      return Icons.edit_note_outlined;
    case kStatusSubmitted:
      return Icons.hourglass_top_outlined;
    case kStatusDraftReady:
      return Icons.mark_email_unread_outlined;
    default:
      return Icons.verified_outlined;
  }
}

/// Small chip showing where a ritual stands: Draft, Submitted, Draft ready, Approved.
class StatusChip extends StatelessWidget {
  final String status;
  final bool onDark;
  const StatusChip(this.status, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Pill(
      statusLabel(status),
      icon: statusIcon(status),
      strong: status != kStatusApproved,
      onDark: onDark,
    );
  }
}

/// A gold tick followed by a line of text, for "what is included" lists.
class TickLine extends StatelessWidget {
  final String text;
  final Color? color;
  const TickLine(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 17, color: kGold),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: body(14, color: color ?? kInk).copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

/// The small muted line that marks a stand-in for a service that is not connected yet.
class DemoNote extends StatelessWidget {
  final String text;
  const DemoNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: TextAlign.center, style: body(12, color: kMuted));
  }
}

/// A row that opens something: icon, title, optional detail, chevron.
class LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;
  const LinkRow({super.key, required this.icon, required this.title, this.detail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: kMaroon),
      title: Text(title, style: body(15, weight: 600)),
      subtitle: detail == null ? null : Text(detail!, style: body(12.5, color: kMuted)),
      trailing: const Icon(Icons.chevron_right, color: kMuted),
      onTap: onTap,
    );
  }
}
