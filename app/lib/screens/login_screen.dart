import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'app_drawer.dart';
import 'ui.dart';

/// DEMO STAND-IN, to be replaced by real OTP verification with an SMS provider.
/// Until then no code is sent: the phone number is mapped to a fixed backend account
/// so the real database, with its per-family access rules, still sits behind the login.
({String email, String password}) demoCredentialsForPhone(String digits) =>
    (email: 'p$digits@example.com', password: 'Hv!$digits#otp');

enum _Stage { phone, setup, email }

/// Auth entry, laid out as the Figma OTP screen, with a single Login button. The person
/// says whether they log in as a Family Admin (the one who paid) or a Family Member
/// (invited by an admin). Signing in with a number that has no account yet leads to one
/// extra "Set up your family" step, shaped by that choice.
/// Super admins have no button here: they sign in with email, reached by long-pressing
/// the emblem.

/// Password shared by the three seeded demo accounts.
const kDemoPassword = 'Virasat@2026';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const LoginScreen({super.key, required this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();
  final _name = TextEditingController();
  final _familyName = TextEditingController();
  final _inviteCode = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  _Stage _stage = _Stage.phone;
  bool _asAdmin = true; // Login as Family Admin, or as Family Member
  bool _busy = false;
  bool _showPassword = false;
  Timer? _timer;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    _otpFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_phone, _otp, _name, _familyName, _inviteCode, _email, _password]) {
      c.dispose();
    }
    _otpFocus.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _phoneOk => RegExp(r'^[6-9]\d{9}$').hasMatch(_digits);
  bool get _otpOk => _otp.text.length == 6;

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  void _onPhoneChanged(String _) {
    setState(() {});
    // The "code" goes out as soon as the number is complete.
    if (_phoneOk && _timer == null) {
      _startCountdown();
      _otpFocus.requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (!_phoneOk) return showError(context, 'Enter a valid 10-digit mobile number');
    if (!_otpOk) return showError(context, 'Enter the 6-digit code');
    FocusScope.of(context).unfocus();
    final creds = demoCredentialsForPhone(_digits);
    setState(() => _busy = true);
    try {
      final user = await repo.signIn(email: creds.email, password: creds.password);
      if (!mounted) return;
      // One account belongs to one family, so the account decides the role. Say so if
      // it differs from the choice made on this page.
      final isAdmin = user.role == Role.familyAdmin;
      if (user.role != Role.superAdmin && isAdmin != _asAdmin) {
        showInfo(context, 'This number is registered as a ${isAdmin ? 'Family Admin' : 'Family Member'}');
      }
      widget.onSignedIn();
    } catch (e) {
      if (!mounted) return;
      // No account for this number yet: ask for the family details and create one.
      if (friendlyError(e) == 'The email or password is not correct.') {
        setState(() => _stage = _Stage.setup);
      } else {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setUp() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final creds = demoCredentialsForPhone(_digits);
    setState(() => _busy = true);
    final user = await guard(
      context,
      () => repo.signUp(
        name: _name.text.trim(),
        email: creds.email,
        password: creds.password,
        familyName: _asAdmin ? _familyName.text.trim() : null,
        inviteCode: _asAdmin ? null : _inviteCode.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) widget.onSignedIn();
  }

  Future<void> _emailSignIn() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final user = await guard(
      context,
      () => repo.signIn(email: _email.text.trim(), password: _password.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) widget.onSignedIn();
  }

  String? _required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final String button;
    final VoidCallback action;
    switch (_stage) {
      case _Stage.phone:
        button = 'Login';
        action = _verify;
      case _Stage.setup:
        button = 'Begin Your Family Story';
        action = _setUp;
      case _Stage.email:
        button = 'Sign in';
        action = _emailSignIn;
    }
    return Scaffold(
      backgroundColor: kCream,
      endDrawer: const AppDrawer(),
      bottomNavigationBar: PinnedBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _busy ? null : action,
              child: _busy ? const ButtonSpinner() : Text(button),
            ),
            const SizedBox(height: 12),
            Text(
              'By continuing, you agree to our Terms & Privacy Policy',
              textAlign: TextAlign.center,
              style: body(11.5, color: kMuted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_stage != _Stage.phone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _busy ? null : () => setState(() => _stage = _Stage.phone),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 18, color: kMaroon),
                            const SizedBox(width: 6),
                            Text('Back', style: body(14, weight: 600, color: kMaroon)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Long press: the email sign in used by the Hamari Virasat team.
                    GestureDetector(
                      onLongPress: _busy ? null : () => setState(() => _stage = _Stage.email),
                      child: const BrandEmblem(size: 72),
                    ),
                    const Spacer(),
                    Builder(
                      builder: (context) => IconButton(
                        tooltip: 'About, FAQ and help',
                        icon: const Icon(Icons.menu, color: kInk),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ...switch (_stage) {
                  _Stage.phone => _phoneStage(),
                  _Stage.setup => _setupStage(),
                  _Stage.email => _emailStage(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _heading(String title, String text) => [
        Text(title, style: display(34)),
        const SizedBox(height: 12),
        Text(text, style: body(16, color: kMuted).copyWith(height: 1.5)),
        const SizedBox(height: 26),
      ];

  // ---- stage 1: the Figma OTP screen ----

  List<Widget> _phoneStage() {
    final mm = (_resendIn ~/ 60).toString().padLeft(2, '0');
    final ss = (_resendIn % 60).toString().padLeft(2, '0');
    return [
      ..._heading('Welcome to your legacy', "Enter your mobile number. We'll send a secure code to verify it."),
      const FieldLabel('Login as'),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Family Admin'), icon: Icon(Icons.workspace_premium_outlined)),
            ButtonSegment(value: false, label: Text('Family Member'), icon: Icon(Icons.people_outline)),
          ],
          selected: {_asAdmin},
          showSelectedIcon: false,
          onSelectionChanged: _busy ? null : (v) => setState(() => _asAdmin = v.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: kSurface,
            selectedBackgroundColor: kBlush,
            selectedForegroundColor: kMaroon,
            foregroundColor: kMuted,
            side: const BorderSide(color: kLine),
            textStyle: body(13.5, weight: 600),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _asAdmin
            ? 'The family admin is the one who paid. They invite the rest of the family.'
            : 'Invited by your family admin? Log in here as a member.',
        style: body(12.5, color: kMuted).copyWith(height: 1.4),
      ),
      const SizedBox(height: 22),
      const FieldLabel('Mobile number'),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        style: body(17, weight: 500).copyWith(letterSpacing: 0.6),
        onChanged: _onPhoneChanged,
        onSubmitted: (_) => _otpFocus.requestFocus(),
        decoration: InputDecoration(
          hintText: '98765 43210',
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
            child: Center(widthFactor: 1, child: Text('+91', style: body(17, weight: 500))),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const FieldLabel('Enter 6-digit OTP'),
      _otpBoxes(),
      const SizedBox(height: 14),
      Center(
        child: !_phoneOk
            ? Text('Enter your number to receive a code', style: body(13, color: kMuted))
            : _resendIn > 0
                ? Text('Resend code in $mm:$ss', style: body(13, color: kMuted))
                : TextButton(
                    onPressed: () {
                      _startCountdown();
                      showInfo(context, 'A new code is on its way');
                    },
                    child: const Text('Resend code'),
                  ),
      ),
      if (kDemoMode) ...[
        const SizedBox(height: 6),
        Center(
          child: Text('Demo mode: any 6-digit code works', style: body(12, color: const Color(0xFFA89C94))),
        ),
      ],
    ];
  }

  /// Six boxes drawn from one invisible text field, so paste and backspace just work.
  Widget _otpBoxes() {
    final code = _otp.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _otpFocus.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _otpFocus.hasFocus && i == code.length.clamp(0, 5) ? kMaroon : kLine,
                        width: _otpFocus.hasFocus && i == code.length.clamp(0, 5) ? 1.8 : 1,
                      ),
                    ),
                    child: Text(i < code.length ? code[i] : '', style: body(22, weight: 500)),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otp,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- stage 2: first time with this number ----

  List<Widget> _setupStage() {
    return [
      ..._heading(
        'Set up your family',
        _asAdmin
            ? 'This number is new here. Tell us who you are and name your family.'
            : 'This number is new here. Tell us who you are and enter the invite code from your family admin.',
      ),
      const FieldLabel('Your name'),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        decoration: const InputDecoration(hintText: 'e.g. Ananya Sharma'),
        validator: (v) => _required(v, 'Enter your name'),
      ),
      const SizedBox(height: 22),
      FieldLabel(_asAdmin ? 'Your family' : 'Join your family'),
      if (_asAdmin)
        TextFormField(
          key: const ValueKey('family-name'),
          controller: _familyName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _setUp(),
          decoration: const InputDecoration(
            hintText: 'Family name, e.g. Sharma',
            helperText: 'You will be the admin of this family.',
          ),
          validator: (v) => _required(v, 'Enter the family name'),
        )
      else
        TextFormField(
          key: const ValueKey('invite-code'),
          controller: _inviteCode,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _setUp(),
          decoration: const InputDecoration(
            hintText: 'Invite code',
            helperText: 'Ask your family admin for the code.',
          ),
          validator: (v) => _required(v, 'Enter the invite code'),
        ),
    ];
  }

  // ---- email sign in, for accounts made before phone login ----

  List<Widget> _emailStage() {
    return [
      ..._heading('Sign in with email', 'For the Hamari Virasat team and accounts created with an email address.'),
      const FieldLabel('Email'),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: 'you@example.com'),
        validator: (v) {
          final email = (v ?? '').trim();
          if (email.isEmpty) return 'Enter your email';
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email address';
          return null;
        },
      ),
      const SizedBox(height: 22),
      const FieldLabel('Password'),
      TextFormField(
        controller: _password,
        obscureText: !_showPassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onFieldSubmitted: (_) => _emailSignIn(),
        decoration: InputDecoration(
          hintText: 'Your password',
          suffixIcon: IconButton(
            tooltip: _showPassword ? 'Hide password' : 'Show password',
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
      ),
    ];
  }
}
