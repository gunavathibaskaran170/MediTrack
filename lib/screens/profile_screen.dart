import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/user_provider.dart';
import '../providers/vitals_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/analytics_provider.dart';
import '../core/database_helper.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _medicineReminders = true;
  bool _followUpReminders = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _medicineReminders = prefs.getBool('settings_medicine_reminders') ?? true;
      _followUpReminders = prefs.getBool('settings_followup_reminders') ?? true;
    });
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    }
  }

  void _toggleMedicineReminders(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_medicine_reminders', val);
    setState(() {
      _medicineReminders = val;
    });
  }

  void _toggleFollowUpReminders(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_followup_reminders', val);
    setState(() {
      _followUpReminders = val;
    });
  }

  Future<void> _clearAllData() async {
    await DatabaseHelper.instance.purgeAllData();
    await NotificationService().cancelAllNotifications();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (appDir.existsSync()) {
        final List<FileSystemEntity> entities = appDir.listSync();
        for (var entity in entities) {
          if (entity is File && path.basename(entity.path).startsWith('prescription_')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint("Error clearing documents: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
      Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully.')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'JD';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    final name = user?.name ?? 'John Doe';
    final age = user?.age != null ? '${user!.age} years old' : '--';
    final bloodGroup = user?.bloodGroup ?? '--';
    final initials = _getInitials(name);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Profile', style: context.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(context, name, age, bloodGroup, initials),
            const SizedBox(height: 24),
            const Divider(),

            _buildSectionHeader(context, 'Health Profile'),
            ListTile(
              leading: Icon(Icons.medical_information, color: context.colors.primary),
              title: Text('My Conditions', style: context.bodyMedium),
              subtitle: Text(user?.conditions ?? 'None entered', style: context.bodySmall),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textSecondary),
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            ListTile(
              leading: Icon(Icons.warning_amber_outlined, color: context.colors.primary),
              title: Text('Allergies', style: context.bodyMedium),
              subtitle: Text(user?.allergies ?? 'None entered', style: context.bodySmall),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textSecondary),
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            ListTile(
              leading: Icon(Icons.contact_emergency, color: context.colors.primary),
              title: Text('Emergency Contact', style: context.bodyMedium),
              subtitle: Text(user?.ecName != null ? '${user!.ecName} (${user.ecPhone ?? ""})' : 'None entered', style: context.bodySmall),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textSecondary),
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            const Divider(),

            _buildSectionHeader(context, 'Notifications'),
            SwitchListTile(
              value: _medicineReminders,
              onChanged: _toggleMedicineReminders,
              secondary: Icon(Icons.medication, color: context.colors.primary),
              title: Text('Medicine Reminders', style: context.bodyMedium),
            ),
            SwitchListTile(
              value: _followUpReminders,
              onChanged: _toggleFollowUpReminders,
              secondary: Icon(Icons.upcoming, color: context.colors.primary),
              title: Text('Follow-up Reminders', style: context.bodyMedium),
            ),
            const Divider(),

            _buildSectionHeader(context, 'Data Management'),
            ListTile(
              leading: Icon(Icons.delete_forever, color: context.colors.errorSos),
              title: Text('Clear All Data', style: context.bodyMedium.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.errorSos),
              onTap: () async {
                final confirm = await showConfirmDeleteDialog(
                  context,
                  title: 'Clear All Data',
                  content: 'Are you sure you want to delete all offline data from this device? This action is permanent and cannot be undone.',
                );
                if (confirm == true) {
                  await _clearAllData();
                }
              },
            ),
            const Divider(),

            _buildSectionHeader(context, 'About'),
            ListTile(
              leading: Icon(Icons.gavel, color: context.colors.primary),
              title: Text('Licenses', style: context.bodyMedium),
              onTap: () {
                showLicensePage(context: context);
              },
            ),
            ListTile(
              leading: Icon(Icons.verified, color: context.colors.primary),
              title: Text('Version 1.0.0', style: context.bodyMedium),
              trailing: Text('1.0.0', style: context.bodySmall),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String age, String bloodGroup, String initials) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: context.colors.primaryLight,
            child: Text(
              initials,
              style: context.displayLarge.copyWith(
                fontSize: 24,
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: context.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '$age  |  $bloodGroup Blood Group',
            style: context.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: context.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
