import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';
import 'super_admin_screen.dart';
import 'ui.dart';

const _onboardedKey = 'hv_onboarded';

/// Entry point: splash, then onboarding on the first run, then the auth gate that
/// decides which screen the signed-in (or signed-out) user lands on.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _splash = true;
  bool _onboarded = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<AppUser?> _loadUser() async {
    try {
      return await repo.currentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> _start() async {
    // The splash stays up for about a second and a half, or until the session is known.
    final results = await Future.wait<Object?>([
      _loadUser(),
      SharedPreferences.getInstance().then((p) => p.getBool(_onboardedKey) ?? false),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;
    setState(() {
      _user = results[0] as AppUser?;
      _onboarded = results[1] as bool;
      _splash = false;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
    if (mounted) setState(() => _onboarded = true);
  }

  Future<void> _refresh() async {
    final user = await _loadUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _signOut() async {
    await guardOk(context, () => repo.signOut());
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    final user = _user;
    if (_splash) {
      page = const SplashScreen(key: ValueKey('splash'));
    } else if (user == null && !_onboarded) {
      page = OnboardingScreen(key: const ValueKey('onboarding'), onDone: _finishOnboarding);
    } else if (user == null) {
      page = LoginScreen(key: const ValueKey('login'), onSignedIn: _refresh);
    } else if (user.role == Role.superAdmin) {
      page = SuperAdminScreen(key: const ValueKey('super'), onSignOut: _signOut);
    } else {
      page = HomeScreen(key: ValueKey('home-${user.id}'), user: user, onSignOut: _signOut);
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: page);
  }
}
