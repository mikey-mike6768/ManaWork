import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || publishableKey.isEmpty) {
    runApp(const MissingConfigurationApp());
    return;
  }
  await Supabase.initialize(url: url, publishableKey: publishableKey);
  runApp(const ManaWorkApp());
}

class MissingConfigurationApp extends StatelessWidget {
  const MissingConfigurationApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ManaWork',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF087E75), useMaterial3: true),
    home: const Scaffold(body: Center(child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY using --dart-define.', textAlign: TextAlign.center),
    ))),
  );
}
