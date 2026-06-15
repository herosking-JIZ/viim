import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/section_card.dart';

class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  late bool _notificationsEnabled;
  late String _language;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _language = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveLanguagePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    setState(() => _language = value);
  }

  Future<void> _logout() async {
    if (!mounted) return;

    final router = GoRouter.of(context);

    ref.read(authProvider.notifier).logout();
    router.go('/login');
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: SwitchListTile(
                title: const Text('Activer les notifications'),
                subtitle: const Text('Recevez les mises à jour importantes'),
                onChanged: _saveNotificationPreference,
                value: _notificationsEnabled,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Langue',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: DropdownButtonFormField<String>(
                initialValue: _language,
                onChanged: (value) {
                  if (value != null) {
                    _saveLanguagePreference(value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Légal',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Conditions d\'utilisation'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _launchURL('https://ndjigi.com/cgu'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Politique de confidentialité'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _launchURL('https://ndjigi.com/privacy'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'À propos',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Version'),
                    trailing: const Text('1.0.0'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Se déconnecter'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
