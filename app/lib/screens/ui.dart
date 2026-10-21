import 'dart:io';

import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme.dart';

/// Runs a repository call. On failure shows a SnackBar and returns null instead of throwing.
Future<T?> guard<T>(BuildContext context, Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
}

/// Same as [guard] for calls that return nothing. True when the call succeeded.
Future<bool> guardOk(BuildContext context, Future<void> Function() fn) async {
  try {
    await fn();
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

/// Turns any thrown error into one clean sentence a family member can read.
String friendlyError(Object e) {
  var text = e.toString().trim();

  // AuthException(message: Invalid login credentials, statusCode: 400, ...) and friends.
  final wrapped = RegExp(r'^\w*(Exception|Error)\(message:\s*(.*?)(,\s*\w+:.*)?\)$', dotAll: true)
      .firstMatch(text);
  if (wrapped != null) text = wrapped.group(2) ?? text;

  // "Bad state: ", "Exception: ", "FormatException: " and the like, possibly stacked.
  final prefix = RegExp(r'^(Bad state|Invalid argument\(s\)|\w*Exception|\w*Error)\s*:\s*');
  while (prefix.hasMatch(text)) {
    text = text.replaceFirst(prefix, '');
  }

  final low = text.toLowerCase();
  if (low.contains('socketexception') ||
      low.contains('failed host lookup') ||
      low.contains('network is unreachable') ||
      low.contains('connection refused') ||
      low.contains('connection closed') ||
      low.contains('clientexception') ||
      low.contains('timed out')) {
    return 'No internet connection. Check your network and try again.';
  }
  if (low.contains('invalid login credentials') || low.contains('wrong email or password')) {
    return 'The email or password is not correct.';
  }
  if (low.contains('already registered') || low.contains('already exists') || low.contains('already been registered')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (low.contains('invite') && (low.contains('not found') || low.contains('invalid') || low.contains('no family'))) {
    return 'That invite code was not found. Check it with your family admin.';
  }
  if (low.contains('email') && low.contains('invalid')) {
    return 'That email address does not look right.';
  }
  if (low.contains('password') && (low.contains('at least') || low.contains('weak') || low.contains('short'))) {
    return 'Choose a password with at least 6 characters.';
  }
  if (low.contains('email confirmation') || low.contains('email not confirmed')) {
    return 'This account is waiting for email confirmation.';
  }
  if (low.contains('row-level security') || low.contains('permission denied') || low.contains('not allowed')) {
    return 'You do not have permission to do that.';
  }
  if (low.contains('rate limit') || low.contains('too many requests')) {
    return 'Too many attempts. Please wait a minute and try again.';
  }
  if (low.contains('jwt') || low.contains('session') && low.contains('expired')) {
    return 'Your session has ended. Please sign in again.';
  }
  if (text.isEmpty) return 'Something went wrong. Please try again.';

  text = text[0].toUpperCase() + text.substring(1);
  if (text.length > 160) text = '${text.substring(0, 157)}...';
  return text;
}

void showError(BuildContext context, Object e) {
  if (!context.mounted) return;
  _snack(context, friendlyError(e), Icons.error_outline);
}

void showInfo(BuildContext context, String message) {
  if (!context.mounted) return;
  _snack(context, message, Icons.check_circle_outline);
}

void _snack(BuildContext context, String message, IconData icon) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: kGold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String question, {
  String title = 'Please confirm',
  String yes = 'Yes',
  String no = 'Cancel',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(question),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(no)),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => Navigator.pop(c, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks before signing out, then runs [signOut].
Future<void> confirmSignOut(BuildContext context, Future<void> Function() signOut) async {
  final ok = await confirm(
    context,
    'You will need your email and password to come back in.',
    title: 'Sign out?',
    yes: 'Sign out',
  );
  if (ok) await signOut();
}

/// "9 Oct 2026"
String formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final l = d.toLocal();
  return '${l.day} ${months[l.month - 1]} ${l.year}';
}

/// "just now", "3 hours ago", "2 days ago", then the date.
String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
  if (diff.inDays < 30) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  return formatDate(d);
}

/// "today", "yesterday", or the date. For the Heritage Book cover.
String updatedWhen(DateTime? d) {
  if (d == null) return 'Just begun';
  final days = DateTime.now().difference(d.toLocal()).inDays;
  if (days < 1) return 'Updated today';
  if (days < 2) return 'Updated yesterday';
  return 'Updated ${formatDate(d)}';
}

String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// A thin-line icon for a ritual category; custom categories get the default.
IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('birth') || c.contains('chatti') || c.contains('janm')) return Icons.child_friendly_outlined;
  if (c.contains('annaprasan') || c.contains('food')) return Icons.rice_bowl_outlined;
  if (c.contains('mundan')) return Icons.content_cut_outlined;
  if (c.contains('vidya') || c.contains('school')) return Icons.school_outlined;
  if (c.contains('puberty') || c.contains('age')) return Icons.spa_outlined;
  if (c.contains('wedding') || c.contains('vivah') || c.contains('shaadi')) return Icons.favorite_border;
  if (c.contains('death') || c.contains('antyesti')) return Icons.local_fire_department_outlined;
  return Icons.auto_awesome_outlined;
}

/// The icon for a memory kind.
IconData memoryIcon(String kind) {
  switch (kind) {
    case 'photo':
      return Icons.photo_camera_outlined;
    case 'video':
      return Icons.videocam_outlined;
    case 'voice':
      return Icons.mic_none_outlined;
    default:
      return Icons.auto_stories_outlined;
  }
}

String memoryKindLabel(String kind) {
  switch (kind) {
    case 'photo':
      return 'Photo';
    case 'video':
      return 'Video';
    case 'voice':
      return 'Voice';
    default:
      return 'Story';
  }
}

/// Fades and slides a list item in; [index] staggers the start a little.
class FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const FadeSlideIn({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 0.08;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (delay * 1000).round()),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        final v = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
        );
      },
    );
  }
}

/// Cross-fades between a loading state and content. Children need distinct keys.
class SoftSwitcher extends StatelessWidget {
  final Widget child;
  const SoftSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child);
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: kMaroon, strokeWidth: 3));
}

/// Small spinner for inside a button.
class ButtonSpinner extends StatelessWidget {
  final Color color;
  const ButtonSpinner({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
}

/// The brand mark: a cream circle with a gold ring and a line leaf.
class BrandEmblem extends StatelessWidget {
  final double size;

  /// On the maroon splash the circle is cream with a gold ring; on cream pages it is blush.
  final bool onDark;
  const BrandEmblem({super.key, this.size = 72, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? kCream : kBlush,
        shape: BoxShape.circle,
        border: onDark ? Border.all(color: kGold, width: 1.2) : null,
        boxShadow: onDark
            ? null
            : [BoxShadow(color: kMaroon.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      alignment: Alignment.center,
      child: onDark
          ? Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGold, width: 1.6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.spa_outlined, color: kGold, size: size * 0.34),
            )
          : Icon(Icons.spa_outlined, color: kMaroon, size: size * 0.42),
    );
  }
}

/// Screen title row used at the top of every tab: Playfair title, optional action, hairline.
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool back;
  const ScreenHeader({super.key, required this.title, this.trailing, this.back = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(back ? 8 : 24, 14, 12, 12),
          child: Row(
            children: [
              if (back)
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back, color: kInk),
                  onPressed: () => Navigator.maybePop(context),
                ),
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(24)),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 4),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: kLine),
      ],
    );
  }
}

/// White rounded card with the soft shadow used across the app.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(color: kSurface, borderRadius: r, boxShadow: kCardShadow),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Maroon card for banners and covers, with a thin gold edge.
class MaroonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  const MaroonCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: kMaroon,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGold.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(color: kMaroon.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// A thin-line maroon icon on a soft blush circle or rounded square.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool circle;
  final Color background;
  final Color color;
  const IconBadge(
    this.icon, {
    super.key,
    this.size = 44,
    this.circle = false,
    this.background = kBlush,
    this.color = kMaroon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.26),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Initial inside a soft circle, used for members and family accounts.
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool muted;
  const InitialAvatar(this.name, {super.key, this.size = 46, this.muted = false});

  static const _fills = [
    Color(0xFFF3E3E1),
    Color(0xFFF1E4CC),
    Color(0xFFE2E9DC),
    Color(0xFFE9E0D6),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final fill = muted ? const Color(0xFFEDE8E2) : _fills[trimmed.hashCode.abs() % _fills.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      alignment: Alignment.center,
      child: Text(initial, style: display(size * 0.42, color: muted ? kMuted : kMaroon)),
    );
  }
}

/// Titled white card: line icon, Playfair title, optional trailing action, then the body.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, size: 38),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: display(18))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Warm empty state: a line icon, a Playfair line and one sentence.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String line;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.line, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon, size: 76, circle: true),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: display(22)),
          const SizedBox(height: 8),
          Text(line, textAlign: TextAlign.center, style: body(14.5, color: kMuted).copyWith(height: 1.5)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Muted "Not added yet" line for an empty section.
class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote([this.text = 'Not added yet', Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: body(14, color: const Color(0xFFA89C94)).copyWith(height: 1.4));
  }
}

/// Multi-line text as bullets or numbered lines; a single line stays a plain paragraph.
class LinesText extends StatelessWidget {
  final String text;
  final bool numbered;
  const LinesText(this.text, {super.key, this.numbered = false});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return const EmptyNote();
    if (lines.length == 1) {
      return Text(lines.first, style: body(15).copyWith(height: 1.5));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (numbered)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(color: kBlush, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: body(12, weight: 600, color: kMaroon)),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.fromLTRB(4, 8, 14, 0),
                    decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                  ),
                Expanded(child: Text(lines[i], style: body(15).copyWith(height: 1.45))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small rounded label. [strong] is the blush and maroon version.
class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool strong;
  final bool onDark;
  const Pill(this.text, {super.key, this.icon, this.strong = false, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : (strong ? kMaroon : kMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.14) : (strong ? kBlush : kCream),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.3) : (strong ? kMaroon.withValues(alpha: 0.35) : kLine),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(text, style: body(12, weight: 600, color: fg)),
        ],
      ),
    );
  }
}

/// Uppercase field label above an input, as on the Figma forms.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: eyebrow(color: const Color(0xFF6B5A50))),
    );
  }
}

/// A button bar pinned to the bottom that lifts itself above the keyboard.
class PinnedBar extends StatelessWidget {
  final Widget child;
  const PinnedBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      color: kCream,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(24, 10, 24, 14), child: child),
      ),
    );
  }
}

/// Shows one stored media path as an image: an `asset:` path, a local file, or a
/// storage path that the repository turns into a URL. Non-images get an icon tile.
class MediaImage extends StatefulWidget {
  final String path;
  final String kind; // memory kind, decides the fallback icon
  final BoxFit fit;

  /// Decode width in pixels. Thumbnails pass about 400 so full-size photos are not decoded.
  final int? cacheWidth;
  const MediaImage(this.path, {super.key, this.kind = 'photo', this.fit = BoxFit.cover, this.cacheWidth});

  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  Future<String>? _url;

  static const _imageExt = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.heic'];

  bool get _isImage {
    final p = widget.path.toLowerCase();
    return _imageExt.any(p.endsWith);
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(MediaImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _resolve();
  }

  void _resolve() {
    _url = (_isImage && !widget.path.startsWith('asset:')) ? repo.mediaUrl(widget.path) : null;
  }

  Widget _fallback() => Container(
        color: kBlush,
        alignment: Alignment.center,
        child: Icon(memoryIcon(widget.kind), color: kMaroon, size: 28),
      );

  @override
  Widget build(BuildContext context) {
    if (!_isImage) return _fallback();
    if (widget.path.startsWith('asset:')) {
      return Image.asset(
        widget.path.substring(6),
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: (_, e, s) => _fallback(),
      );
    }
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        final url = snap.data;
        if (snap.hasError) return _fallback();
        if (url == null) return Container(color: kBlush);
        if (url.startsWith('http')) {
          return Image.network(
            url,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            errorBuilder: (_, e, s) => _fallback(),
            loadingBuilder: (c, child, progress) => progress == null ? child : Container(color: kBlush),
          );
        }
        return Image.file(File(url), fit: widget.fit, cacheWidth: widget.cacheWidth, errorBuilder: (_, e, s) => _fallback());
      },
    );
  }
}
