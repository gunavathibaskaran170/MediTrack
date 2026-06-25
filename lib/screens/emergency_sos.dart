import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/meditrack_theme.dart';
import '../providers/user_provider.dart';
import '../providers/medicine_provider.dart';
import '../services/sos_service.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isTriggering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);

    final user = userProvider.currentUser;
    final medicines = medProvider.medicines;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Emergency', style: context.titleLarge.copyWith(color: context.colors.errorSos)),
        backgroundColor: context.colors.errorLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSOSButtonSection(context, user, medicines),
            const SizedBox(height: 40),
            _buildMedicalProfileCard(context, user, medicines),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final ecName = user?.ecName ?? 'Sarah Doe (Wife)';
                final ecPhone = user?.ecPhone ?? '+1 (555) 019-2834';
                final dummyUser = user ?? User(name: 'Rajan Kumar', ecName: ecName, ecPhone: ecPhone);
                await SosService.shareMedicalProfile(context, dummyUser, medicines);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Medical Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 24),
            _buildDisclaimer(context),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSosAlert(User? user, List<Medicine> medicines) async {
    if (user == null || user.ecPhone == null || user.ecPhone!.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Contact Set'),
          content: const Text('Please add an emergency contact in your Profile before triggering SOS.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Trigger SOS Alert?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will:\n'
          '1. Log this emergency offline.\n'
          '2. Simulate sending emergency SMS alerts to ${user.ecName} (${user.ecPhone})'
          '${user.hospitalPhone != null ? ' and your Hospital (${user.hospitalPhone})' : ''}.\n'
          '3. Open the phone dialer to call ${user.ecName}.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trigger Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isTriggering = true;
    });

    try {
      // Simulate SMS alert broadcast delay
      await Future.delayed(const Duration(milliseconds: 1500));

      final todayStr = DateTime.now().toIso8601String();
      final contactsText = '${user.ecName} (${user.ecPhone})'
          '${user.hospitalPhone != null ? ', Hospital (${user.hospitalPhone})' : ''}';

      final log = SosLog(
        timestamp: todayStr,
        contactNotified: contactsText,
        smsSent: true,
        callInitiated: true,
        notes: 'SOS triggered from dashboard. Medical profile shared: name: ${user.name}, blood: ${user.bloodGroup ?? "O+"}.',
      );

      // Insert log
      await DatabaseHelper.instance.insertSosLog(log);

      // Dial contact
      final cleanPhone = user.ecPhone!.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        throw 'Could not open phone dialer';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ SOS Alert dispatched and logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error executing SOS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering dialer: $e. SOS was logged.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTriggering = false;
        });
      }
    }
  }

  Widget _buildSOSButtonSection(BuildContext context, User? user, List<Medicine> medicines) {
    final displayName = user?.ecName ?? 'Emergency Contact';
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double scale = 1.0 + (_pulseController.value * 0.25);
              double opacity = 1.0 - _pulseController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: context.colors.errorSos.withOpacity(0.2 * opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isTriggering ? null : () => _triggerSosAlert(user, medicines),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: context.colors.errorSos,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.errorSos.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isTriggering)
                            const CircularProgressIndicator(color: Colors.white)
                          else ...[
                            const Icon(Icons.phone_in_talk, size: 48, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              'SOS',
                              style: context.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isTriggering ? 'Dispatching alert...' : 'Tap to call $displayName',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalProfileCard(BuildContext context, User? user, List<Medicine> medicines) {
    final List<String> conditions = user?.conditions
            ?.split(',')
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        ['Hypertension', 'Asthma'];

    final List<String> allergies = user?.allergies
            ?.split(',')
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        ['Penicillin'];

    final activeMeds = medicines.where((m) => m.isActive).toList();

    final ecName = user?.ecName ?? 'Sarah Doe (Wife)';
    final ecPhone = user?.ecPhone ?? '+1 (555) 019-2834';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MediTrackSpacing.cardInternalPaddingHorizontal,
          vertical: MediTrackSpacing.cardInternalPaddingVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Medical Profile',
                  style: context.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context: context,
              icon: Icons.person,
              label: 'Name',
              content: Text(user?.name ?? 'John Doe', style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.water_drop,
              label: 'Blood Type',
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.errorLight,
                  borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
                ),
                child: Text(
                  user?.bloodGroup ?? 'O+',
                  style: context.displayLarge.copyWith(
                    color: context.colors.errorSos,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.medical_information,
              label: 'Conditions',
              content: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: conditions
                    .map((c) => _buildMedicalChip(context, c, context.colors.primaryLight, context.colors.primary))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.medication,
              label: 'Medications',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activeMeds.isEmpty
                    ? [Text('No active medications', style: context.bodyMedium)]
                    : activeMeds
                        .map((m) => Text('• ${m.name} ${m.dosage?.toStringAsFixed(0) ?? ""} ${m.unit ?? ""}', style: context.bodyMedium))
                        .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.warning_amber,
              label: 'Allergies',
              content: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: allergies
                    .map((a) => _buildMedicalChip(context, a, context.colors.errorLight, context.colors.errorSos))
                    .toList(),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ecName,
                        style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ecPhone,
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: context.colors.success),
                  onPressed: () async {
                    await SosService.callEmergencyContact(context, ecName, ecPhone);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalChip(BuildContext context, String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
      ),
      child: Text(
        text,
        style: context.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: context.bodySmall,
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: context.colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'MediTrack is not a diagnostic tool. In emergencies call 112 / 108 / 911.',
            style: context.labelSmall.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
