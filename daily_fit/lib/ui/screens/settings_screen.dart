import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/user_profile_service.dart';
import '../../data/database_provider.dart';
import '../../data/backup_service.dart';
import '../../data/notification_service.dart';
import '../../data/theme_mode_provider.dart';

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
