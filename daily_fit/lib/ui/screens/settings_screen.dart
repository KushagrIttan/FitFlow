import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/user_profile_service.dart';
import '../../data/database_provider.dart';
import '../../data/backup_service.dart';
import '../../data/notification_service.dart';
import '../../data/theme_mode_provider.dart';
import '../../data/api_key_service.dart';
import '../../data/recommendation_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _styleNotesController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isSaving = false;

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isExporting = false;

  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isVerifying = false;
  bool? _verifyResult; // null = not tried, true = key works, false = failed

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileServiceProvider);
    _heightController.text = profile.height;
    _weightController.text = profile.weight;
    _styleNotesController.text = profile.styleNotes;
    _locationController.text = profile.defaultLocation;

    _reminderEnabled = profile.reminderEnabled;
    final reminder = profile.reminderTime;
    if (reminder != null) _reminderTime = reminder;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _styleNotesController.dispose();
    _locationController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await ref.read(userProfileServiceProvider).saveProfile(
          height: _heightController.text,
          weight: _weightController.text,
          styleNotes: _styleNotesController.text,
          defaultLocation: _locationController.text,
        );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    setState(() => _reminderEnabled = enabled);
    final profile = ref.read(userProfileServiceProvider);
    await profile.setReminderEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      final profile = ref.read(userProfileServiceProvider);
      await profile.setReminderTime(picked);
      if (_reminderEnabled) {
        await NotificationService.instance.scheduleDailyReminder(picked);
      }
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your Gemini API key first')),
      );
      return;
    }
    await ref.read(geminiApiKeyProvider.notifier).setKey(key);
    _apiKeyController.clear();
    if (mounted) {
      setState(() => _verifyResult = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved securely on this device')),
      );
    }
  }

  Future<void> _verifyApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your Gemini API key first')),
      );
      return;
    }
    setState(() {
      _isVerifying = true;
      _verifyResult = null;
    });
    final service = ref.read(recommendationServiceProvider);
    final ok = await service.verifyApiKey(key);
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _verifyResult = ok;
      });
    }
  }

  Future<void> _clearApiKey() async {
    await ref.read(geminiApiKeyProvider.notifier).clear();
    _apiKeyController.clear();
    if (mounted) {
      setState(() => _verifyResult = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key removed — AI styling is off')),
      );
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final db = ref.read(databaseProvider);
      final file = await BackupService(db).exportToJson();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Daily Fit backup',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profile', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildField('Height (e.g. 180cm, 5\'11")', _heightController),
                  const SizedBox(height: 12),
                  _buildField('Weight (optional)', _weightController),
                  const SizedBox(height: 12),
                  _buildField('Style Notes (e.g. Minimalist, Streetwear)', _styleNotesController, maxLines: 3),
                  const SizedBox(height: 12),
                  _buildField('Default City (e.g. New York)', _locationController),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('AI Stylist', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status row.
                  Row(
                    children: [
                      Icon(
                        ref.watch(geminiApiKeyProvider) != null
                            ? Icons.auto_awesome
                            : Icons.auto_awesome_outlined,
                        size: 20,
                        color: ref.watch(geminiApiKeyProvider) != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ref.watch(geminiApiKeyProvider) != null
                            ? 'AI styling: ON'
                            : 'AI styling: OFF (local mode)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ref.watch(geminiApiKeyProvider) != null
                        ? 'A Gemini key is saved on this device.'
                        : 'Add a Gemini API key to get AI outfit styling. '
                            'Without it, recommendations stay local.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Gemini API key',
                      hintText: 'Paste your key (AIza…)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveApiKey,
                          child: const Text('Save Key'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isVerifying ? null : _verifyApiKey,
                          icon: _isVerifying
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline,
                                  size: 18),
                          label: Text(_isVerifying ? 'Testing…' : 'Verify'),
                        ),
                      ),
                    ],
                  ),
                  if (_verifyResult != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _verifyResult!
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 18,
                          color: _verifyResult!
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _verifyResult!
                                ? 'Key works — Gemini responded successfully.'
                                : 'Verification failed. Check the key is complete '
                                    'and valid at aistudio.google.com/apikey.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (ref.watch(geminiApiKeyProvider) != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _clearApiKey,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove key'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Security notice — required with credential forms.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your key is encrypted on this device (Android '
                            'Keystore) and sent only to Google\'s Gemini API. '
                            'It never appears in backups or in the app bundle.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {ref.watch(themeModeProvider)},
                    onSelectionChanged: (selection) =>
                        ref.read(themeModeProvider.notifier).set(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Reminders', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily outfit reminder'),
                  subtitle: const Text('A local nudge to pick today\'s outfit'),
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                ),
                if (_reminderEnabled)
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Reminder time'),
                    subtitle: Text(
                        '${_reminderTime.hour.toString().padLeft(2, '0')}:'
                        '${_reminderTime.minute.toString().padLeft(2, '0')}'),
                    onTap: _pickReminderTime,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Outfit Plan'),
                  subtitle: const Text('Plan a week or a trip without repeats'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/plan'),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Outfit History'),
                  subtitle: const Text('Everything you\'ve worn'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/history'),
                ),
                ListTile(
                  leading: _isExporting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share),
                  title: const Text('Export backup (JSON)'),
                  subtitle: const Text('Your wardrobe lives only on this device — back it up'),
                  onTap: _isExporting ? null : _exportBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Local-first & private'),
              subtitle: Text('Your wardrobe, photos and outfit history never leave this device.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
