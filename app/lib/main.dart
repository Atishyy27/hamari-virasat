import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/local_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'screens/root_screen.dart';
import 'theme.dart';

// Passed at build time with --dart-define. Empty means: run on on-device demo data.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await _initSupabase();
    repo = SupabaseRepository();
  } else {
    final local = LocalRepository();
    await local.init();
    repo = local;
  }
  runApp(const HamariVirasatApp());
}

/// The key parameter was renamed from anonKey to publishableKey (supabase-flutter MIGRATION.md),
/// and the build script takes whichever version pub resolves. Try the new name, fall back to
/// the old one. The key value itself is the same either way.
Future<void> _initSupabase() async {
  const Function init = Supabase.initialize;
  try {
    await Function.apply(init, const [], {#url: _supabaseUrl, #publishableKey: _supabaseAnonKey});
  } on NoSuchMethodError {
    await Function.apply(init, const [], {#url: _supabaseUrl, #anonKey: _supabaseAnonKey});
  }
}

class HamariVirasatApp extends StatelessWidget {
  const HamariVirasatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamari Virasat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootScreen(),
    );
  }
}
