import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<Prescription> _prescriptionsList = [];
  bool _isLoading = true;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getPrescriptions();
      setState(() {
        _prescriptionsList = list;
      });
    } catch (e) {
      debugPrint("Error loading prescriptions: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        await _processImage(pickedFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _processImage(XFile pickedFile) async {
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final detailsEntered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
            side: BorderSide(color: context.colors.dividerColor, width: 0.8),
          ),
          title: Text('Prescription Details', style: context.titleLarge),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: doctorController,
                  style: context.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  style: context.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Save', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (detailsEntered != true) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String origName = pickedFile.name;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'prescription_${timestamp}_$origName';
      final File localImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      final prescription = Prescription(
        imagePath: localImage.path,
        doctorName: doctorController.text.trim().isNotEmpty ? doctorController.text.trim() : 'Unknown Doctor',
        visitDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );

      await DatabaseHelper.instance.insertPrescription(prescription);
      _loadPrescriptions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription stored successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error storing prescription: $e");
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _prescriptionsList.isNotEmpty;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Prescriptions', style: context.titleLarge),
        actions: const [
          SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _prescriptionsList.length,
                  itemBuilder: (context, index) {
                    final prescription = _prescriptionsList[index];
                    return _buildPrescriptionCard(prescription, index);
                  },
                ),
      floatingActionButton: _buildCustomSpeedDial(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: context.colors.textHint,
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'No prescriptions stored yet',
              style: context.titleLarge.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'Tap the add button to take a photo or upload a file.',
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription p, int index) {
    final file = File(p.imagePath);
    final hasLocalFile = file.existsSync();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionFullViewer(
                prescription: p,
                onDelete: _loadPrescriptions,
              ),
            ),
          );
        },
        splashColor: context.colors.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: hasLocalFile
                  ? Image.file(file, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: context.colors.primaryLight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 40, color: context.colors.primary),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to View',
                            style: context.labelSmall.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.doctorName ?? 'Unknown Doctor',
                          style: context.bodySmall.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(p.visitDate),
                          style: context.labelSmall,
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: context.colors.errorSos),
                            onPressed: () async {
                              final confirm = await showConfirmDeleteDialog(
                                context,
                                title: 'Delete Prescription',
                                content: 'Are you sure you want to delete this prescription image?',
                              );
                              if (confirm == true && p.id != null) {
                                await DatabaseHelper.instance.deletePrescription(p.id!);
                                try {
                                  if (file.existsSync()) {
                                    await file.delete();
                                  }
                                } catch (_) {}
                                _loadPrescriptions();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: context.colors.card,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text('Take Photo', style: context.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'camera_fab',
                backgroundColor: context.colors.primaryLight,
                foregroundColor: context.colors.primary,
                onPressed: () {
                  _toggleSpeedDial();
                  _pickImage(ImageSource.camera);
                },
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: context.colors.card,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text('Upload File', style: context.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'upload_fab',
                backgroundColor: context.colors.primaryLight,
                foregroundColor: context.colors.primary,
                onPressed: () {
                  _toggleSpeedDial();
                  _pickImage(ImageSource.gallery);
                },
                child: const Icon(Icons.folder_open),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: context.colors.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: _toggleSpeedDial,
          child: Icon(_isSpeedDialOpen ? Icons.close : Icons.add_photo_alternate),
        ),
      ],
    );
  }
}

class PrescriptionFullViewer extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onDelete;

  const PrescriptionFullViewer({
    super.key,
    required this.prescription,
    required this.onDelete,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(prescription.imagePath);
    final hasFile = file.existsSync();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Prescription', style: context.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.errorSos),
            onPressed: () async {
              final confirm = await showConfirmDeleteDialog(
                context,
                title: 'Delete Prescription',
                content: 'Are you sure you want to delete this prescription?',
              );
              if (confirm == true && prescription.id != null) {
                await DatabaseHelper.instance.deletePrescription(prescription.id!);
                try {
                  if (file.existsSync()) {
                    await file.delete();
                  }
                } catch (_) {}
                onDelete();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: hasFile
              ? Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.shadowColor,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                    child: Image.file(file),
                  ),
                )
              : AspectRatio(
                  aspectRatio: 0.7,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: context.colors.dividerColor, width: 0.8),
                      borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.shadowColor,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.local_hospital, size: 40, color: context.colors.primary),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(prescription.doctorName ?? 'Unknown Doctor', style: context.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                  Text('General Medical Practitioner', style: context.labelSmall),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32, thickness: 2),
                          Text('Date: ${_formatDate(prescription.visitDate)}', style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 24),
                          Text('Rx:', style: context.displayLarge.copyWith(fontSize: 24, fontStyle: FontStyle.italic, color: context.colors.primary)),
                          const SizedBox(height: 12),
                          if (prescription.notes != null)
                            Text(prescription.notes!, style: context.bodyMedium.copyWith(height: 1.5))
                          else ...[
                            Text('1. Amoxicillin 500mg\n   Take 1 capsule three times daily for 7 days.', style: context.bodyMedium.copyWith(height: 1.5)),
                            const SizedBox(height: 16),
                            Text('2. Paracetamol 500mg\n   Take 1 tablet every 6 hours as needed for pain.', style: context.bodyMedium.copyWith(height: 1.5)),
                          ],
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  height: 40,
                                  child: Placeholder(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text('Doctor Signature', style: context.labelSmall),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
