import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/site_content.dart';
import '../theme.dart';
import 'info_screens.dart';
import 'profile_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// The side bar: About, FAQ, privacy and ways to reach the team. Shown on Home and on the
/// sign in page, so someone who has only downloaded the app can read it too ([user] null).
class AppDrawer extends StatelessWidget {
  final AppUser? user;
  const AppDrawer({super.key, this.user});

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _link(BuildContext context, String url) {
    Navigator.pop(context);
    openLink(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kCream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: Row(
                children: [
                  const BrandEmblem(size: 48),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Hamari Virasat', style: display(22))),
                ],
              ),
            ),
            _item(context, Icons.spa_outlined, 'About Hamari Virasat', () => _open(context, InfoHubScreen(user: user))),
            _item(context, Icons.route_outlined, 'How it works', () => _open(context, const HowItWorksScreen())),
            _item(context, Icons.sell_outlined, 'Pricing', () => _open(context, PricingScreen(user: user))),
            _item(context, Icons.quiz_outlined, 'FAQ', () => _open(context, const FaqScreen())),
            _item(context, Icons.shield_outlined, 'Privacy & permissions', () => _open(context, const PrivacyScreen())),
            _item(context, Icons.help_outline, 'Help for elders', () => _open(context, const HelpScreen())),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: kLine)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text('ANY DOUBT? WE ARE HERE', style: eyebrow()),
            ),
            _item(context, Icons.mail_outline, 'Mail us', () => _link(context, kSupportMailUrl), detail: kSupportEmail),
            _item(context, Icons.chat_outlined, 'WhatsApp us', () => _link(context, kWhatsAppUrl)),
            const SizedBox(height: 18),
            Center(child: Text('HAMARI VIRASAT • Version 1.0', style: body(11.5, color: kMuted))),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, VoidCallback onTap, {String? detail}) {
    return ListTile(
      leading: Icon(icon, color: kMaroon),
      title: Text(label, style: body(15, weight: 600)),
      subtitle: detail == null ? null : Text(detail, style: body(12.5, color: kMuted)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
