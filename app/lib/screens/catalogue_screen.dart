import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';
import '../theme.dart';
import 'ritual_form_screen.dart';
import 'site_ui.dart';
import 'ui.dart';

/// Riti Riwaj: the website's catalogue of rituals. Pick one or many, then pay.
class CatalogueScreen extends StatefulWidget {
  final AppUser user;
  const CatalogueScreen({super.key, required this.user});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final Set<String> _selected = {};
  final Set<String> _expanded = {};
  Set<String> _waitlisted = {};
  String? _joining;

  @override
  void initState() {
    super.initState();
    _loadWaitlist();
  }

  Future<void> _loadWaitlist() async {
    try {
      final entries = await repo.listWaitlist();
      if (mounted) setState(() => _waitlisted = {for (final e in entries) e.ritualKey});
    } catch (_) {
      // The waitlist marks are a nicety; the catalogue works without them.
    }
  }

  Future<void> _notifyMe(ComingSoon item) async {
    setState(() => _joining = item.key);
    final ok = await guardOk(context, () => repo.joinWaitlist(item.key));
    if (!mounted) return;
    setState(() {
      _joining = null;
      if (ok) _waitlisted.add(item.key);
    });
    if (ok) showInfo(context, 'You are on the waitlist for ${item.title}');
  }

  Future<void> _checkout() async {
    final chosen = [
      for (final t in kCatalogue)
        if (_selected.contains(t.key)) t,
    ];
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(user: widget.user, rituals: chosen)),
    );
    // The confirmation screen leads on from here, so this page has done its job.
    if (paid == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final total = _selected.length * kPricePerRitual;
    return Scaffold(
      backgroundColor: kCream,
      bottomNavigationBar: _selected.isEmpty
          ? null
          : PinnedBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plural(_selected.length, 'ritual selected', 'rituals selected'),
                            style: body(12.5, color: kMuted)),
                        Text(rupees(total), style: display(22)),
                      ],
                    ),
                  ),
                  FilledButton(onPressed: _checkout, child: const Text('Proceed to Payment')),
                ],
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Riti Riwaj', back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                children: [
                  MaroonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHOOSE FROM OUR COLLECTION', style: eyebrow()),
                        const SizedBox(height: 8),
                        Text('Pick one or many.', style: display(24, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text(
                          '₹299 per ritual, flat rate. One-time payment. No hidden costs.',
                          style: body(14, weight: 500, color: Colors.white).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How to get started', style: display(18)),
                        Text('3 simple steps', style: body(12.5, color: kMuted)),
                        const SizedBox(height: 10),
                        for (var i = 0; i < kHowToStart.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: kBlush, shape: BoxShape.circle),
                                  child: Text('${i + 1}', style: body(12, weight: 700, color: kMaroon)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(kHowToStart[i], style: body(14).copyWith(height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final stage in kStages) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                      child: Text(stage.toUpperCase(), style: eyebrow()),
                    ),
                    for (final t in kCatalogue.where((t) => t.stage == stage)) _ritualCard(t),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 2),
                    child: Text('COMING SOON', style: eyebrow()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                    child: Text('More rituals are on their way', style: display(22)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      'Join the waitlist for any upcoming ritual and be the first to know when it launches — at a reserved early-access price.',
                      style: body(13.5, color: kMuted).copyWith(height: 1.45),
                    ),
                  ),
                  for (final item in kComingSoon) _comingSoonCard(item),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Text(
                      'Have a ritual not on this list? Choose "DIY: Custom Family Ritual" and we will document it too.',
                      textAlign: TextAlign.center,
                      style: body(13, color: kMuted).copyWith(height: 1.45),
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

  Widget _ritualCard(RitualTemplate t) {
    final selected = _selected.contains(t.key);
    final open = _expanded.contains(t.key);
    final subs = t.subSections;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? kMaroon : Colors.transparent, width: 1.6),
        boxShadow: kCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(t.title, style: display(19))),
              const SizedBox(width: 10),
              Pill('+ ${rupees(kPricePerRitual)}', strong: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.description, style: body(13.5, color: kMuted).copyWith(height: 1.5)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => open ? _expanded.remove(t.key) : _expanded.add(t.key)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    open ? 'Hide sub-sections' : 'See all ${subs.length} sub-sections',
                    style: body(13.5, weight: 600, color: kMaroon),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: kMaroon, size: 20),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final s in subs) Pill(s.name)],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: selected
                ? FilledButton.icon(
                    onPressed: () => setState(() => _selected.remove(t.key)),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Selected'),
                  )
                : OutlinedButton.icon(
                    onPressed: () => setState(() => _selected.add(t.key)),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Select this ritual'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoonCard(ComingSoon item) {
    final joined = _waitlisted.contains(item.key);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.stage.toUpperCase(), style: eyebrow(size: 10)),
          const SizedBox(height: 4),
          Text(item.title, style: display(18)),
          const SizedBox(height: 6),
          Text(item.description, style: body(13.5, color: kMuted).copyWith(height: 1.5)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: joined || _joining == item.key ? null : () => _notifyMe(item),
            icon: Icon(joined ? Icons.notifications_active_outlined : Icons.notifications_none, size: 18),
            label: Text(joined ? 'On the waitlist' : 'Notify me when available'),
          ),
        ],
      ),
    );
  }
}

/// Order summary and payment. Payment is a stand-in until Razorpay is connected.
class CheckoutScreen extends StatefulWidget {
  final AppUser user;
  final List<RitualTemplate> rituals;
  const CheckoutScreen({super.key, required this.user, required this.rituals});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _returning = false;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<RitualOrder> orders = const [];
    try {
      orders = await repo.listOrders();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _returning = orders.any((o) => o.status == 'paid');
      _loading = false;
    });
  }

  int get _gross => widget.rituals.length * kPricePerRitual;
  int get _discount => _returning ? (_gross * 0.10).round() : 0;
  int get _total => _gross - _discount;

  Future<void> _pay() async {
    setState(() => _paying = true);
    final order = await guard(
      context,
      () => repo.createOrder([for (final t in widget.rituals) t.key], pricePerRitual: kPricePerRitual),
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (order == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmedScreen(user: widget.user, order: order, rituals: widget.rituals),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      bottomNavigationBar: PinnedBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _paying || _loading ? null : _pay,
                child: _paying ? const ButtonSpinner() : Text('Pay ${rupees(_total)}'),
              ),
            ),
            if (kDemoMode) ...[
              const SizedBox(height: 8),
              const DemoNote('Demo mode: no money is charged'),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Checkout', back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                children: [
                  SectionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Your rituals',
                    child: Column(
                      children: [
                        for (final t in widget.rituals)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(t.title, style: body(14.5, weight: 500))),
                                Text(rupees(kPricePerRitual), style: body(14.5, weight: 600)),
                              ],
                            ),
                          ),
                        const Divider(color: kLine, height: 22),
                        if (_discount > 0) ...[
                          _amountRow('Subtotal', rupees(_gross)),
                          _amountRow('10% returning family discount', '- ${rupees(_discount)}', color: kMaroon),
                        ],
                        Row(
                          children: [
                            Expanded(child: Text('Total', style: display(18))),
                            Text(rupees(_total), style: display(22)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'One-time payment · No subscription · No hidden costs',
                            style: body(12.5, color: kMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    icon: Icons.card_giftcard_outlined,
                    title: "Everything that's included",
                    child: Column(children: [for (final line in kIncluded) TickLine(line)]),
                  ),
                  SoftCard(
                    child: Row(
                      children: [
                        const IconBadge(Icons.verified_user_outlined, size: 44, circle: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('7-day satisfaction guarantee', style: body(15, weight: 600)),
                              const SizedBox(height: 3),
                              Text(
                                'Payments processed securely via Razorpay · UPI, cards & net banking accepted',
                                style: body(12.5, color: kMuted).copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => openLink(context, kRefundUrl),
                      child: const Text('Read the refund policy'),
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

  Widget _amountRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: body(13.5, color: color ?? kMuted))),
          Text(value, style: body(13.5, weight: 600, color: color ?? kInk)),
        ],
      ),
    );
  }
}

/// Shown after payment: what was bought and the way into each personalised form.
class OrderConfirmedScreen extends StatelessWidget {
  final AppUser user;
  final RitualOrder order;
  final List<RitualTemplate> rituals;
  const OrderConfirmedScreen({super.key, required this.user, required this.order, required this.rituals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      bottomNavigationBar: PinnedBar(
        child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 36, bottom: 24),
          children: [
            const Center(child: IconBadge(Icons.check_circle_outline, size: 76, circle: true)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('Payment received', textAlign: TextAlign.center, style: display(28)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '${rupees(order.amount)} paid on ${formatDate(order.createdAt)}. '
                'Your personalised forms are ready. Fill them at your own pace: no rush, no deadline.',
                textAlign: TextAlign.center,
                style: body(14, color: kMuted).copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            for (final t in rituals)
              SoftCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.stage.toUpperCase(), style: eyebrow(size: 10)),
                          const SizedBox(height: 3),
                          Text(t.title, style: display(17)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RitualFormScreen(user: user, templateKey: t.key)),
                      ),
                      child: const Text('Start form'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 14, 32, 0),
              child: Text(
                'After you submit a form we prepare a draft for your approval, then the final PDF heirloom document.',
                textAlign: TextAlign.center,
                style: body(13, color: kMuted).copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
