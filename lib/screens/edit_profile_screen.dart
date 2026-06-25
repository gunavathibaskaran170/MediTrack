import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../providers/user_provider.dart';
import '../core/models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();
  final _hospitalPhoneController = TextEditingController();

  String? _gender = 'Male';
  String? _bloodGroup = 'O+';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _ageController.text = user.age?.toString() ?? '';
      _gender = user.gender ?? 'Male';
      _bloodGroup = user.bloodGroup ?? 'O+';
      _conditionsController.text = user.conditions ?? '';
      _allergiesController.text = user.allergies ?? '';
      _ecNameController.text = user.ecName ?? '';
      _ecPhoneController.text = user.ecPhone ?? '';
      _hospitalPhoneController.text = user.hospitalPhone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    _hospitalPhoneController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    final updated = User(
      id: user?.id ?? 1,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      bloodGroup: _bloodGroup,
      conditions: _conditionsController.text.trim().isNotEmpty ? _conditionsController.text.trim() : null,
      allergies: _allergiesController.text.trim().isNotEmpty ? _allergiesController.text.trim() : null,
      ecName: _ecNameController.text.trim().isNotEmpty ? _ecNameController.text.trim() : null,
      ecPhone: _ecPhoneController.text.trim().isNotEmpty ? _ecPhoneController.text.trim() : null,
      hospitalPhone: _hospitalPhoneController.text.trim().isNotEmpty ? _hospitalPhoneController.text.trim() : null,
      createdAt: user?.createdAt,
    );

    await userProvider.updateUser(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile changes saved successfully!')),
      );
      Navigator.pop(context);
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
    final initials = _getInitials(_nameController.text);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Profile', style: context.titleLarge),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: context.colors.primaryLight,
                      child: Text(
                        initials,
                        style: context.displayLarge.copyWith(
                          fontSize: 28,
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full Name is required';
                  return null;
                },
                onChanged: (text) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final d = int.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Must be a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  setState(() {
                    _gender = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                ],
                onChanged: (val) {
                  setState(() {
                    _bloodGroup = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Conditions (comma-separated)',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ecNameController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.contact_emergency_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ecPhoneController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hospitalPhoneController,
                style: context.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Hospital Phone (optional)',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
