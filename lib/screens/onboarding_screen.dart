import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/meditrack_theme.dart';
import '../core/models.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _profileFormKey = GlobalKey<FormState>();
  final _medicalFormKey = GlobalKey<FormState>();

  // Profile Form Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;

  // Medical Setup Controllers
  final _allergiesController = TextEditingController();
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();

  final List<String> _conditions = [
    'Diabetes', 'Hypertension', 'Heart Disease',
    'Asthma', 'Post-Surgery', 'Kidney Disease', 'Other'
  ];
  final List<String> _selectedConditions = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _submitProfileForm() {
    if (_profileFormKey.currentState!.validate()) {
      _nextPage();
    }
  }

  Future<void> _completeSetup() async {
    // 1. Conditions chip warning (non-blocking warning)
    if (_selectedConditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: Proceeding without selecting any existing health conditions.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (_medicalFormKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final user = User(
        id: 1, // Scope of this single-patient app
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        conditions: _selectedConditions.join(','),
        allergies: _allergiesController.text.trim().isEmpty ? 'None' : _allergiesController.text.trim(),
        ecName: _ecNameController.text.trim(),
        ecPhone: _ecPhoneController.text.trim(),
      );

      // Save User Profile
      await userProvider.saveUser(user);

      // Mark onboarding complete in Preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStep1Welcome(),
        _buildStep2Profile(),
        _buildStep3Medical(),
      ],
    );
  }

  // STEP 1: Welcome Page
  Widget _buildStep1Welcome() {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.monitor_heart,
                size: 80,
                color: context.colors.primary,
              ),
              const SizedBox(height: MediTrackSpacing.large),
              Text(
                'MediTrack',
                style: context.displayLarge,
              ),
              const SizedBox(height: MediTrackSpacing.titleToContentGap),
              Text(
                'Your health, tracked with care.',
                style: context.bodySmall,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: MediTrackSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: Personal Profile
  Widget _buildStep2Profile() {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('About You', style: context.titleLarge),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 0.33,
            backgroundColor: context.colors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: context.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MediTrackSpacing.formFieldGap),
                    TextFormField(
                      controller: _ageController,
                      style: context.bodyMedium,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Age is required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) {
                          return 'Please enter a valid age between 1 and 120';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MediTrackSpacing.formFieldGap),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
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
                      onChanged: (val) => setState(() => _selectedGender = val),
                      validator: (value) => value == null ? 'Gender is required' : null,
                    ),
                    const SizedBox(height: MediTrackSpacing.formFieldGap),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
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
                      onChanged: (val) => setState(() => _selectedBloodGroup = val),
                      validator: (value) => value == null ? 'Blood group is required' : null,
                    ),
                    const SizedBox(height: MediTrackSpacing.xl),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitProfileForm,
                        child: const Text('Next →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Medical Setup
  Widget _buildStep3Medical() {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Medical Profile', style: context.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousPage,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 0.66,
            backgroundColor: context.colors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
              child: Form(
                key: _medicalFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Existing Conditions',
                      style: context.titleMedium,
                    ),
                    const SizedBox(height: MediTrackSpacing.titleToContentGap),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _conditions.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return FilterChip(
                          label: Text(condition),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedConditions.add(condition);
                              } else {
                                _selectedConditions.remove(condition);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: MediTrackSpacing.large),
                    Text(
                      'Known Allergies',
                      style: context.titleMedium,
                    ),
                    const SizedBox(height: MediTrackSpacing.titleToContentGap),
                    TextFormField(
                      controller: _allergiesController,
                      style: context.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'e.g. Penicillin, Pollen',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                    ),
                    const SizedBox(height: MediTrackSpacing.large),
                    Text(
                      'Emergency Contact',
                      style: context.titleMedium,
                    ),
                    const SizedBox(height: MediTrackSpacing.titleToContentGap),
                    TextFormField(
                      controller: _ecNameController,
                      style: context.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final phone = _ecPhoneController.text.trim();
                        if (phone.isNotEmpty && (value == null || value.trim().isEmpty)) {
                          return 'Contact name is required if phone is filled';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MediTrackSpacing.formFieldGap),
                    TextFormField(
                      controller: _ecPhoneController,
                      style: context.bodyMedium,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final name = _ecNameController.text.trim();
                        if (name.isNotEmpty && (value == null || value.trim().isEmpty)) {
                          return 'Phone number is required if name is filled';
                        }
                        if (value != null && value.trim().isNotEmpty) {
                          // Validate EC phone formats
                          final pattern = RegExp(r'^(\+[\d-]+|\d{10})$');
                          if (!pattern.hasMatch(value.trim())) {
                            return 'Enter 10-digit number or start with + for international';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MediTrackSpacing.xl),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _completeSetup,
                        child: const Text('Complete Setup ✓'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
