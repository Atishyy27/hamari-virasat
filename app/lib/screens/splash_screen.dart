import 'package:flutter/material.dart';

import '../theme.dart';
import 'ui.dart';

/// First thing on screen: the brand on the maroon gradient.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: kSplashGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const BrandEmblem(size: 112, onDark: true),
              const SizedBox(height: 28),
              Text(
                'HAMARI VIRASAT',
                textAlign: TextAlign.center,
                style: display(32, color: Colors.white).copyWith(letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Text('Preserving Our Legacy', style: body(16, color: Colors.white.withValues(alpha: 0.92))),
              const Spacer(flex: 7),
              Text(
                'Stories that live beyond generations',
                style: body(12.5, color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
