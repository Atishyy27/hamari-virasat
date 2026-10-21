import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/local_repository.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'ui.dart';

/// DEMO STAND-IN, to be replaced by real OTP verification with an SMS provider.
/// Until then no code is sent: the phone number is mapped to a fixed backend account
/// so the real database, with its per-family access rules, still sits behind the login.
({String email, String password}) demoCredentialsForPhone(String digits) =>
    (email: 'p$digits@example.com', password: 'Hv!$digits#otp');

enum _Stage { phone, setup, email }

/// Auth entry, laid out as the Figma OTP screen. Signing in with a number that has no
/// account yet leads to one extra "Set up your family" step.
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
  bool _newFamily = true;
  bool _busy = false;
  String? _demoEmail; // demo account being signed in to, for its spinner
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
      await repo.signIn(email: creds.email, password: creds.password);
      if (mounted) widget.onSignedIn();
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
        familyName: _newFamily ? _familyName.text.trim() : null,
        inviteCode: _newFamily ? null : _inviteCode.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) widget.onSignedIn();
  }

  /// One-tap sign in to a seeded demo account. Only built while kDemoMode is on.
  Future<void> _demoSignIn(String email) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _demoEmail = email;
    });
    final user = await guard(context, () => repo.signIn(email: email, password: kDemoPassword));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _demoEmail = null;
    });
    if (user != null) widget.onSignedIn();
  }

  Widget _demoButton(String label, String email) {
    return OutlinedButton(
      onPressed: _busy ? null : () => _demoSignIn(email),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
        textStyle: body(12.5, weight: 600),
      ),
      child: _demoEmail == email
          ? const SizedBox(width: 16, height: 16, child: ButtonSpinner(color: kMaroon))
          : Text(label),
    );
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
        button = 'Verify & Continue';
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
                const BrandEmblem(size: 72),
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
      const SizedBox(height: 6),
      if (kDemoMode) ...[
        Center(
          child: Text('Demo mode: any 6-digit code works', style: body(12, color: const Color(0xFFA89C94))),
        ),
        const SizedBox(height: 18),
        Center(child: Text('Try a demo account', style: body(12.5, weight: 600, color: kMuted))),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _demoButton('Family admin', 'demo@example.com'),
            _demoButton('Member', 'member@example.com'),
            _demoButton('Super admin', 'super@example.com'),
          ],
        ),
      ],
      const SizedBox(height: 20),
      Center(
        child: TextButton(
          onPressed: _busy ? null : () => setState(() => _stage = _Stage.email),
          style: TextButton.styleFrom(foregroundColor: kMuted, textStyle: body(12.5, weight: 500)),
          child: const Text('Sign in with email'),
        ),
      ),
      if (repo is LocalRepository)
        Center(
          child: Text(
            'On-device demo: admin@demo.in, member@demo.in, super@demo.in / demo123',
            textAlign: TextAlign.center,
            style: body(11, color: const Color(0xFFA89C94)),
          ),
        ),
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
      ..._heading('Set up your family', 'This number is new here. Tell us who you are and which family you belong to.'),
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
      const FieldLabel('Your family'),
      Row(
        children: [
          Expanded(child: _choice('Start a new family', Icons.home_outlined, _newFamily, true)),
          const SizedBox(width: 12),
          Expanded(child: _choice('Join with invite code', Icons.key_outlined, !_newFamily, false)),
        ],
      ),
      const SizedBox(height: 16),
      if (_newFamily)
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

  Widget _choice(String label, IconData icon, bool selected, bool value) {
    return Material(
      color: selected ? kBlush : kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? kMaroon : kLine, width: selected ? 1.6 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _newFamily = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: selected ? kMaroon : kMuted, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: body(12.5, weight: 600, color: selected ? kMaroon : kInk),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- email sign in, for accounts made before phone login ----

  List<Widget> _emailStage() {
    return [
      ..._heading('Sign in with email', 'For accounts that were created with an email address.'),
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
