import 'package:flutter/material.dart';

import '../theme.dart';

class _Page {
  final String image;
  final String eyebrow;
  final String title;
  final String text;
  const _Page(this.image, this.eyebrow, this.title, this.text);
}

// Page 1 no longer promises a family tree: the client replaced it with a member list.
const _pages = [
  _Page(
    'assets/images/onboard_roots.png',
    'OUR ROOTS',
    'See every member of your family',
    'Bring your whole family into one home and help every generation know where they come from.',
  ),
  _Page(
    'assets/images/onboard_memories.png',
    'OUR MEMORIES',
    'Keep every voice and story close',
    'Safely collect photographs, videos, handwritten notes and the voices you never want to forget.',
  ),
  _Page(
    'assets/images/onboard_traditions.png',
    'OUR TRADITIONS',
    'Pass down what makes you, you',
    'Preserve treasured recipes, rituals and festivals in one beautiful family home.',
  ),
];

/// Three intro pages shown once, before the first sign in.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: kCream,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _OnboardPage(page: _pages[i], onSkip: widget.onDone),
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
                    onPressed: _next,
                    child: Text(last ? 'Begin Your Family Story' : 'Continue'),
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
  final VoidCallback onSkip;
  const _OnboardPage({required this.page, required this.onSkip});

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: Image.asset(page.image, fit: BoxFit.cover),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 10,
                  right: 16,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSkip,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Skip', style: body(14, weight: 600, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
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
