import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';
import '../theme.dart';
import 'catalogue_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// Hamari Virasat: everything the website says about the service, plus ways to reach the team.
/// Open before sign in too ([user] null): then the catalogue is left out and "Write to us" is an email.
class InfoHubScreen extends StatelessWidget {
  final AppUser? user;
  const InfoHubScreen({super.key, this.user});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Hamari Virasat', back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                children: [
                  MaroonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LEGACY · PRESERVATION · CONTINUITY', style: eyebrow()),
                        const SizedBox(height: 8),
                        Text("Preserve your family's rituals forever", style: display(23, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          'Leave a lasting footprint for the generations to come.',
                          style: body(13.5, color: Colors.white.withValues(alpha: 0.92)),
                        ),
                        if (user case final user?) ...[
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: () => _push(context, CatalogueScreen(user: user)),
                            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kMaroon),
                            child: const Text('Browse rituals & festivals'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      children: [
                        LinkRow(
                          icon: Icons.auto_stories_outlined,
                          title: 'About us',
                          detail: "The story behind and the founder's note",
                          onTap: () => _push(context, const AboutScreen()),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.hourglass_bottom_outlined,
                          title: 'Why it matters',
                          detail: 'What happens when no one writes it down?',
                          onTap: () => _push(context, const WhyItMattersScreen()),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.route_outlined,
                          title: 'How it works',
                          detail: 'Three steps to a heritage that lasts',
                          onTap: () => _push(context, const HowItWorksScreen()),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.sell_outlined,
                          title: 'Pricing',
                          detail: '₹299 per ritual. Yours forever.',
                          onTap: () => _push(context, PricingScreen(user: user)),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.favorite_border,
                          title: "Families we've helped",
                          detail: 'Stories from families who chose to preserve',
                          onTap: () => _push(context, const TestimonialsScreen()),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.quiz_outlined,
                          title: 'Common questions',
                          detail: 'Everything you need to know',
                          onTap: () => _push(context, const FaqScreen()),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                    child: Text('GET IN TOUCH', style: eyebrow()),
                  ),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      children: [
                        LinkRow(
                          icon: Icons.mail_outline,
                          title: 'Write to us',
                          detail: 'We reply within one business day',
                          onTap: () => switch (user) {
                            final user? => _push(context, ContactScreen(user: user)),
                            null => openLink(context, kSupportMailUrl),
                          },
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.alternate_email,
                          title: 'Mail us',
                          detail: kSupportEmail,
                          onTap: () => openLink(context, kSupportMailUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.chat_outlined,
                          title: 'Chat on WhatsApp',
                          detail: 'Quick questions — we reply fast',
                          onTap: () => openLink(context, kWhatsAppUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.event_available_outlined,
                          title: 'Book a Free 15-min Call',
                          detail: 'Prefer to speak? Schedule a time',
                          onTap: () => _push(context, const BookCallScreen()),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'See a sample document',
                          detail: 'What your family receives',
                          onTap: () => openLink(context, kSamplePdfUrl),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Text(kBusinessHours, style: body(12.5, color: kMuted).copyWith(height: 1.45)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                    child: Text('FOLLOW AND POLICIES', style: eyebrow()),
                  ),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      children: [
                        LinkRow(
                          icon: Icons.camera_alt_outlined,
                          title: 'Instagram',
                          onTap: () => openLink(context, kInstagramUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.thumb_up_alt_outlined,
                          title: 'Facebook',
                          onTap: () => openLink(context, kFacebookUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => openLink(context, kPrivacyUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.description_outlined,
                          title: 'Terms',
                          onTap: () => openLink(context, kTermsUrl),
                        ),
                        const Divider(height: 1, color: kLine),
                        LinkRow(
                          icon: Icons.currency_rupee,
                          title: 'Refund Policy',
                          onTap: () => openLink(context, kRefundUrl),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Text(
                      '10% returning family discount on your next ritual documentation',
                      textAlign: TextAlign.center,
                      style: body(12.5, weight: 600, color: kGold),
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

/// A plain reading page: header, then the given blocks.
class _ReadingPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ReadingPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: title, back: true),
            Expanded(
              child: ListView(padding: const EdgeInsets.only(top: 12, bottom: 28), children: children),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _intro(String eyebrowText, String headline, [String? line]) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrowText.toUpperCase(), style: eyebrow()),
          const SizedBox(height: 8),
          Text(headline, style: display(26)),
          if (line != null) ...[
            const SizedBox(height: 8),
            Text(line, style: body(14, color: kMuted).copyWith(height: 1.5)),
          ],
        ],
      ),
    );

Widget _paragraph(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: Text(text, style: body(14.5).copyWith(height: 1.6)),
    );

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'About us',
      children: [
        _intro('An IIM alumnus on a mission', 'The Story Behind'),
        for (final p in kAboutParagraphs) _paragraph(p),
        SoftCard(
          margin: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("FOUNDER'S NOTE", style: eyebrow()),
              const SizedBox(height: 10),
              Text(kFoundersNote, style: body(14.5).copyWith(height: 1.6, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        MaroonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preserve your roots. Honor your legacy.', style: display(20, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                "Start recording your family's rituals today in a permanent digital heirloom.",
                style: body(13.5, color: Colors.white.withValues(alpha: 0.92)).copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WhyItMattersScreen extends StatelessWidget {
  const WhyItMattersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'Why it matters',
      children: [
        _intro(
          'Why it matters',
          'What happens when no one writes it down?',
          "Most of us assume these traditions are being passed down automatically, but they aren't. While the rituals themselves may survive, the heart - the specific details will quietly fade away.",
        ),
        for (final item in kWhyItMatters)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: display(19)),
                const SizedBox(height: 8),
                Text(item.text, style: body(14, color: kMuted).copyWith(height: 1.55)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(
            'Start documenting before the details are lost to time.',
            textAlign: TextAlign.center,
            style: body(13.5, weight: 600, color: kMaroon),
          ),
        ),
      ],
    );
  }
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'How it works',
      children: [
        _intro(
          'The process',
          'Three steps to a heritage that lasts',
          "No writing skills needed. No historian required. Just your family's stories, and a little time.",
        ),
        for (var i = 0; i < kHowItWorks.length; i++)
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('0${i + 1}', style: display(30, color: kGold)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kHowItWorks[i].title, style: display(18)),
                      const SizedBox(height: 6),
                      Text(kHowItWorks[i].text, style: body(14, color: kMuted).copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.bookmark_border, size: 40, circle: true),
              const SizedBox(width: 14),
              Expanded(child: Text(kSaveAndResume, style: body(13.5).copyWith(height: 1.55))),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => openLink(context, kSamplePdfUrl),
            child: const Text('See a sample document'),
          ),
        ),
      ],
    );
  }
}

class PricingScreen extends StatelessWidget {
  final AppUser? user;
  const PricingScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'Pricing',
      children: [
        _intro(
          'Investment',
          'One price per ritual. Yours forever.',
          'No tiers. No hidden fees. No subscriptions. Pick one or many rituals from our collection — each one documented in full at ₹299.',
        ),
        MaroonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✦ PILOT OFFER', style: eyebrow()),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹299', style: display(40, color: Colors.white)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('/ ritual', style: body(14, color: Colors.white.withValues(alpha: 0.9))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'One-time payment · No subscription · No hidden costs',
                style: body(13, color: Colors.white.withValues(alpha: 0.92)),
              ),
              const SizedBox(height: 4),
              Text('Pilot offer — limited time pricing', style: body(12.5, color: kGold)),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.card_giftcard_outlined,
          title: "Everything that's included",
          child: Column(children: [for (final line in kIncluded) TickLine(line)]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Text(
            'Payments processed securely via Razorpay · UPI, cards & net banking accepted',
            textAlign: TextAlign.center,
            style: body(12.5, color: kMuted).copyWith(height: 1.45),
          ),
        ),
        if (user case final user?)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CatalogueScreen(user: user)),
              ),
              child: const Text('Browse rituals & festivals'),
            ),
          ),
      ],
    );
  }
}

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: "Families we've helped",
      children: [
        _intro("Families we've helped", 'Stories from families who chose to preserve'),
        for (final t in kTestimonials)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: kGold, size: 28),
                const SizedBox(height: 6),
                Text(t.quote, style: body(14.5).copyWith(height: 1.6)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    InitialAvatar(t.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: body(14.5, weight: 600)),
                          Text(t.place, style: body(12.5, color: kMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Pill(t.ritual, strong: true),
              ],
            ),
          ),
      ],
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'Common questions',
      children: [
        _intro('Common questions', 'Everything you need to know'),
        for (final q in kFaq)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: kMaroon,
                collapsedIconColor: kMaroon,
                title: Text(q.title, style: body(14.5, weight: 600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(q.text, style: body(14, color: kMuted).copyWith(height: 1.55))],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
          child: Text('Still have a question?', style: display(20)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Book a free 15-minute call — we'll answer everything",
            style: body(13.5, color: kMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: OutlinedButton(
            onPressed: () => openLink(context, kCalendlyUrl),
            child: const Text('Book a Free 15-min Call'),
          ),
        ),
      ],
    );
  }
}

class BookCallScreen extends StatelessWidget {
  const BookCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadingPage(
      title: 'Book a call',
      children: [
        _intro(
          'Book a free call',
          'Still having doubts? Talk to us.',
          "We know that handing over your family's memories to anyone requires trust. Book a free 15-minute call, ask us everything, and decide when you're ready.",
        ),
        SoftCard(child: Column(children: [for (final line in kCallPoints) TickLine(line)])),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: FilledButton(
            onPressed: () => openLink(context, kCalendlyUrl),
            child: const Text('Schedule a Free Call'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: OutlinedButton.icon(
            onPressed: () => openLink(context, kWhatsAppUrl),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Chat on WhatsApp'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Text(kBusinessHours, textAlign: TextAlign.center, style: body(12.5, color: kMuted)),
        ),
      ],
    );
  }
}

/// The website's "Write to us" form. The message is stored as an enquiry.
class ContactScreen extends StatefulWidget {
  final AppUser user;
  const ContactScreen({super.key, required this.user});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String? _topic;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    // Accounts made through the demo OTP have a stand-in address, so leave those blank.
    final email = widget.user.email;
    _email = TextEditingController(text: email.endsWith('@example.com') ? '' : email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final ok = await guardOk(
      context,
      () => repo.sendEnquiry(
        Enquiry(
          id: newId(),
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          topic: _topic ?? kEnquiryTopics.last,
          message: _message.text.trim(),
          createdAt: DateTime.now(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return _ReadingPage(
        title: 'Write to us',
        children: [
          const SizedBox(height: 30),
          const Center(child: IconBadge(Icons.mark_email_read_outlined, size: 76, circle: true)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text('Message sent', textAlign: TextAlign.center, style: display(26)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You will hear back within 1 business day.',
              textAlign: TextAlign.center,
              style: body(14.5, color: kMuted),
            ),
          ),
          const SizedBox(height: 18),
          for (final item in kAfterYouWrite)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: body(15, weight: 600)),
                  const SizedBox(height: 4),
                  Text(item.text, style: body(13.5, color: kMuted).copyWith(height: 1.45)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: kCream,
      bottomNavigationBar: PinnedBar(
        child: FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending ? const ButtonSpinner() : const Text('Send My Message'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Write to us', back: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    Text('SEND A MESSAGE', style: eyebrow()),
                    const SizedBox(height: 8),
                    Text('Write to us.', style: display(26)),
                    const SizedBox(height: 8),
                    Text(
                      'We read every message personally and reply within one business day. No automated responses — just a real answer from someone who understands what you are trying to preserve.',
                      style: body(13.5, color: kMuted).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const FieldLabel('Your name'),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Tell us your name' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Email address'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                            ? null
                            : 'Enter an email address we can reply to';
                      },
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Phone (optional)'),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('I am asking about'),
                    DropdownButtonFormField<String>(
                      initialValue: _topic,
                      isExpanded: true,
                      hint: const Text('Select a topic'),
                      items: [
                        for (final topic in kEnquiryTopics)
                          DropdownMenuItem(value: topic, child: Text(topic, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _topic = v),
                      validator: (v) => v == null ? 'Select a topic' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Your message'),
                    TextFormField(
                      controller: _message,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v ?? '').trim().length < 10 ? 'Write a few words about your question' : null,
                    ),
                    const SizedBox(height: 18),
                    Text(kBusinessHours, style: body(12.5, color: kMuted).copyWith(height: 1.45)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
