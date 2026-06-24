import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';

class SosService {
  /// Steps 1 & 2: Show confirmation dialog and initiate phone call
  static Future<void> callEmergencyContact(BuildContext context, String ecName, String ecPhone) async {
    final cleanPhone = ecPhone.replaceAll(RegExp(r'[^\d+]'), '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Emergency Contact?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text('This will initiate a phone call to $ecName at $ecPhone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
      try {
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling $ecName...')),
            );
          }
        } else {
          throw 'Could not launch dialer';
        }
      } catch (e) {
        debugPrint("Error launching dialer: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer. Please call manually.')),
          );
        }
      }
    }
  }

  /// Builds a string and copies it to the clipboard
  static Future<void> shareMedicalProfile(BuildContext context, User user, List<Medicine> medicines) async {
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final activeMeds = medicines.where((m) => m.isActive).toList();
    final medLines = activeMeds.isNotEmpty
        ? activeMeds.map((m) => "• ${m.name} ${m.dosage ?? ''}${m.unit ?? ''} (${m.frequency ?? ''})").join('\n')
        : "None";

    final profileText = """
--- MediTrack Emergency Profile ---
Name: ${user.name}, Age: ${user.age ?? 'N/A'}
Blood Group: ${user.bloodGroup ?? 'N/A'}
Conditions: ${user.conditions ?? 'None'}
Current Medications:
$medLines
Allergies: ${user.allergies ?? 'None'}
Emergency Contact: ${user.ecName ?? 'N/A'} — ${user.ecPhone ?? 'N/A'}
Generated: $nowStr
--- Not a diagnostic tool ---""";

    try {
      await Clipboard.setData(ClipboardData(text: profileText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical profile copied to clipboard')),
        );
      }
    } catch (e) {
      debugPrint("Error copying emergency profile: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy profile. Try again.')),
        );
      }
    }
  }
}
