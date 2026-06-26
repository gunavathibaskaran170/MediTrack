import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/models.dart';
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
import 'sos_history.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _medicineReminders = true;
  bool _followUpReminders = true;
  int _sosCount = 0;

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
      _loadSosCount();
    }
  }

  void _loadSosCount() async {
    try {
      final logs = await DatabaseHelper.instance.getSosLogs();
      setState(() {
        _sosCount = logs.length;
      });
    } catch (_) {}
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

  Future<void> _handleLogout() async {
    final confirm = await showConfirmDeleteDialog(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout from your profile? You will need to sign in again.',
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
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

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showChangeHospitalDialog(User? user, UserProvider provider) {
    final hospitals = ['Apollo Hospital', 'Fortis Medical Center', 'Max Healthcare', 'General Clinic'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Connected Hospital'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: hospitals.map((h) {
              return ListTile(
                title: Text(h),
                leading: Icon(Icons.local_hospital_outlined, color: context.colors.primary),
                onTap: () async {
                  if (user != null) {
                    final updatedUser = User(
                      id: user.id,
                      name: user.name,
                      age: user.age,
                      gender: user.gender,
                      bloodGroup: user.bloodGroup,
                      conditions: user.conditions,
                      allergies: user.allergies,
                      ecName: user.ecName,
                      ecPhone: user.ecPhone,
                      hospitalPhone: user.hospitalPhone,
                      createdAt: user.createdAt,
                      profession: user.profession,
                      organization: user.organization,
                      workEmail: user.workEmail,
                      workPhone: user.workPhone,
                      bio: user.bio,
                      connectedHospital: h,
                    );
                    await provider.updateUser(updatedUser);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Connected to $h successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
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
    final medProvider = Provider.of<MedicineProvider>(context);
    final user = userProvider.currentUser;

    final name = user?.name ?? 'Rajan Kumar';
    final profession = user?.profession ?? 'Senior Software Engineer';
    final organization = user?.organization ?? 'Apollo Hospitals Group';
    final workEmail = user?.workEmail ?? 'rajan.kumar@apollo.com';
    final workPhone = user?.workPhone ?? '+91-98765-99999';
    final bio = user?.bio ?? 'Passionate about healthcare tech and patient monitoring systems.';
    
    final age = user?.age != null ? '${user!.age} years old' : '58 years old';
    final bloodGroup = user?.bloodGroup ?? 'O+';
    final gender = user?.gender ?? 'Male';
    final initials = _getInitials(name);

    final activeMedicinesCount = medProvider.medicines.where((m) => m.isActive).length;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Professional Profile', style: context.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colors.textPrimary),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile/edit').then((_) => _loadSettings()),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: context.colors.errorSos),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Professional Avatar and Bio Card
            Card(
              elevation: 4,
              shadowColor: context.colors.shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.bottomSheets),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: context.colors.primary.withOpacity(0.1),
                          child: Text(
                            initials,
                            style: context.displayLarge.copyWith(
                              fontSize: 24,
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$profession at',
                                style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                              ),
                              Text(
                                organization,
                                style: context.bodyMedium.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.primaryLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(MediTrackRadius.inputFields),
                          border: Border.all(color: context.colors.primaryLight),
                        ),
                        child: Text(
                          bio,
                          style: context.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Grid (Apollo-style cards)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.medication,
                    value: '$activeMedicinesCount',
                    label: 'Active Meds',
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.trending_up,
                    value: '${(medProvider.weeklyAdherence * 100).toInt()}%',
                    label: 'Adherence',
                    color: context.colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.sos,
                    value: '$_sosCount',
                    label: 'SOS Alerts',
                    color: context.colors.errorSos,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SosHistoryScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabs / Card Content
            Text(
              'Professional Contact & ID',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildDetailTile(Icons.work_outline, 'Designation', profession),
                  _buildDetailTile(Icons.corporate_fare, 'Organization', organization),
                  _buildDetailTile(Icons.email_outlined, 'Work Email', workEmail),
                  _buildDetailTile(Icons.phone_android, 'Work Phone', workPhone),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Health Card details',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildDetailTile(Icons.cake_outlined, 'Age & Gender', '$age  |  $gender'),
                  _buildDetailTile(Icons.water_drop_outlined, 'Blood Group', '$bloodGroup Blood Group'),
                  _buildDetailTile(
                    Icons.medical_information,
                    'Conditions',
                    user?.conditions ?? 'Diabetes, Hypertension',
                    onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                  ),
                  _buildDetailTile(
                    Icons.warning_amber_outlined,
                    'Allergies',
                    user?.allergies ?? 'Penicillin',
                    onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                  ),
                  _buildDetailTile(
                    Icons.contact_emergency,
                    'Emergency Contact',
                    user?.ecName != null ? '${user!.ecName} (${user.ecPhone ?? ""})' : 'Priya Kumar (+91-98765-43210)',
                    onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                  ),
                  _buildDetailTile(
                    Icons.local_hospital,
                    'Primary Care Hospital',
                    user?.hospitalPhone ?? '+91-11-2345-6789',
                    onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Hospital Connection Sync',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.colors.primary.withOpacity(0.1),
                      child: Icon(Icons.local_hospital, color: context.colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.connectedHospital ?? 'Apollo Hospital',
                            style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connected & Syncing',
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showChangeHospitalDialog(user, userProvider),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Profile Health QR Code',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Scan to Share Health Profile',
                      style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Affiliated doctors can scan this code to load your history instantly.',
                      textAlign: TextAlign.center,
                      style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: QrImageView(
                        data: jsonEncode({
                          'name': name,
                          'age': user?.age ?? 58,
                          'gender': gender,
                          'bloodGroup': bloodGroup,
                          'hospital': user?.connectedHospital ?? 'Apollo Hospital',
                          'conditions': user?.conditions ?? 'Diabetes,Hypertension',
                          'allergies': user?.allergies ?? 'Penicillin',
                          'emergency': (user != null && user.ecName != null) ? '${user.ecName} (${user.ecPhone ?? ""})' : 'Priya Kumar (+91-98765-43210)',
                        }),
                        version: QrVersions.auto,
                        size: 160.0,
                        foregroundColor: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'App & Reminders Settings',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Security & System',
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: context.colors.errorSos),
                    title: Text(
                      'Clear Offline Data',
                      style: context.bodyMedium.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
                  ListTile(
                    leading: Icon(Icons.gavel, color: context.colors.primary),
                    title: Text('Licenses & Disclaimers', style: context.bodyMedium),
                    onTap: () => showLicensePage(context: context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Red Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out from Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.errorSos,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MediTrackRadius.cards),
      child: Card(
        color: context.colors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          side: BorderSide(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: context.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.labelSmall.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.colors.primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: context.colors.primary, size: 18),
      ),
      title: Text(title, style: context.labelSmall.copyWith(color: context.colors.textSecondary)),
      subtitle: Text(
        subtitle,
        style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: context.colors.textPrimary),
      ),
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios, size: 12, color: context.colors.textSecondary) : null,
      onTap: onTap,
    );
  }
}
