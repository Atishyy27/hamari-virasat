import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

class _Page {
  final String image;
  final String eyebrow;
  final String title;
  final String text;
  const _Page(this.image, this.eyebrow, this.title, this.text);
}

// Order and titles from the client's 16 Oct review: traditions, then memories, then family.
const _pages = [
  _Page(
    'assets/images/onboard_traditions.png',
    'OUR TRADITIONS',
    'Pass down what makes you, YOU',
    'Preserve treasured rituals, festivals and the recipes that go with them in one beautiful family home.',
  ),
  _Page(
    'assets/images/onboard_memories.png',
    'OUR MEMORIES',
    'Keep every voice and story close',
    'Safely collect photographs, videos, handwritten notes and the voices you never want to forget.',
  ),
  _Page(
    'assets/images/onboard_roots.png',
    'OUR ROOTS',
    'See what binds you as a family',
    'Bring your whole family into one home and help every generation know where they come from.',
  ),
];

/// Three intro pages shown once, before the first sign in. They turn on their own (or by
/// swiping), and "Begin Your Family Story" is on every page, so one tap leads to sign in.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _autoAdvance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Moves to the next page every few seconds, looping. A swipe restarts the wait.
  void _autoAdvance() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % _pages.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _autoAdvance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _OnboardPage(page: _pages[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 8),
                          width: i == _index ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index ? kMaroon : const Color(0xFFE2D2CB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: widget.onDone,
                    child: const Text('Begin Your Family Story'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _Page page;
  const _OnboardPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height * 0.5,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: Image.asset(page.image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.eyebrow, style: eyebrow()),
                const SizedBox(height: 14),
                Text(page.title, style: display(30)),
                const SizedBox(height: 14),
                Text(page.text, style: body(15.5, color: kMuted).copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
