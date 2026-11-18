import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ManaWorkApp extends StatelessWidget {
  const ManaWorkApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ManaWork',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E75)), useMaterial3: true),
    home: StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) => supabase.auth.currentSession == null ? const SignInScreen() : const HomeScreen(),
    ),
  );
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}
class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _message;
  Future<void> _sendLink() async {
    final email = _email.text.trim();
    if (email.isEmpty) { setState(() => _message = 'Enter your email address.'); return; }
    setState(() { _busy = true; _message = null; });
    try {
      await supabase.auth.signInWithOtp(email: email);
      if (mounted) setState(() => _message = 'Check your email for the sign-in link.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not send sign-in link. Please try again.');
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() { _email.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, size: 42, color: Color(0xFF087E75)),
          const SizedBox(height: 18),
          Text('ManaWork', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Trusted help. Right around the corner.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          FilledButton(onPressed: _busy ? null : _sendLink, child: Text(_busy ? 'Sending…' : 'Continue with email')),
          if (_message != null) ...[const SizedBox(height: 14), Text(_message!)],
        ],
      )),
    ))),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase.from('profiles').select('full_name, active_mode, preferred_language').eq('id', userId).single();
      final categories = await supabase.from('service_categories').select('id, name, description, icon_key').eq('is_active', true).order('sort_order');
      if (!mounted) return;
      setState(() { _profile = profile; _categories = List<Map<String, dynamic>>.from(categories); _loading = false; });
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Unable to load your ManaWork dashboard.'; _loading = false; });
    }
  }

  Future<void> _switchMode() async {
    final current = _profile?['active_mode'] as String? ?? 'customer';
    final next = current == 'customer' ? 'worker' : 'customer';
    try {
      await supabase.from('profiles').update({'active_mode': next}).eq('id', supabase.auth.currentUser!.id);
      if (mounted) setState(() => _profile = {...?_profile, 'active_mode': next});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not change mode.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _profile?['active_mode'] as String? ?? 'customer';
    final fullName = _profile?['full_name'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('ManaWork', style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        TextButton(onPressed: _switchMode, child: Text(mode == 'customer' ? 'Worker mode' : 'Customer mode')),
        IconButton(onPressed: () async => supabase.auth.signOut(), icon: const Icon(Icons.logout)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(fullName == null || fullName.isEmpty ? 'Welcome to ManaWork' : 'Hello, ' + fullName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(mode == 'customer' ? 'What help do you need today?' : 'Your worker workspace'),
          const SizedBox(height: 24),
          if (mode == 'customer') ...[
            Text('Explore services', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._categories.map((category) => Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.home_repair_service_outlined)),
              title: Text(category['name'] as String),
              subtitle: Text((category['description'] as String?) ?? ''),
              trailing: const Icon(Icons.chevron_right),
            ))),
          ] else Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Worker profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Complete your profile, add your skills and service areas, then submit your details for verification.'),
              const SizedBox(height: 12),
              const Chip(label: Text('Verification: pending')),
            ],
          ))),
        ])),
    );
  }
}
