import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../theme/meditrack_theme.dart';
import '../core/models.dart';
import '../providers/user_provider.dart';
import '../widgets/floating_nodes_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _orgController = TextEditingController();
  final _workEmailController = TextEditingController();
  final _workPhoneController = TextEditingController();
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _hospitalPhoneController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'O+';
  String _selectedHospital = 'Apollo Hospital';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _hospitals = ['Apollo Hospital', 'Fortis Medical Center', 'Max Healthcare', 'General Clinic'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _orgController.dispose();
    _workEmailController.dispose();
    _workPhoneController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    _bioController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    _hospitalPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay for a premium experience
    await Future.delayed(const Duration(milliseconds: 1500));

    final newUser = User(
      id: 1, // Hardcoded for single-user profile sync
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 35,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      connectedHospital: _selectedHospital,
      conditions: _conditionsController.text.isNotEmpty ? _conditionsController.text.trim() : 'None',
      allergies: _allergiesController.text.isNotEmpty ? _allergiesController.text.trim() : 'None',
      ecName: _ecNameController.text.trim(),
      ecPhone: _ecPhoneController.text.trim(),
      hospitalPhone: _hospitalPhoneController.text.isNotEmpty ? _hospitalPhoneController.text.trim() : '+91-11-2345-6789',
      profession: _professionController.text.trim(),
      organization: _orgController.text.trim(),
      workEmail: _workEmailController.text.trim(),
      workPhone: _workPhoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUser(newUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Account created successfully for ${newUser.name}!'),
              ],
            ),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingNodesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Create Account', style: context.titleLarge),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Premium Beating Heart Animation
                  SizedBox(
                    height: 100,
                    child: Lottie.network(
                      'https://lottie.host/8cd87532-68c3-4d43-a616-24e6503c1535/vA8T3iJplD.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.monitor_heart,
                        size: 64,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join MediTrack',
                    style: context.displayLarge.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Setup your digital patient medical profile in seconds.',
                    textAlign: TextAlign.center,
                    style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Scrollable input card
                  Card(
                    elevation: 8,
                    shadowColor: context.colors.shadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MediTrackRadius.bottomSheets),
                      side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionTitle('Account Details'),
                          TextFormField(
                            controller: _nameController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            style: context.bodyMedium,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) => (val == null || !val.contains('@')) ? 'Please enter a valid email' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            style: context.bodyMedium,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) => (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Personal & Health details'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  style: context.bodyMedium,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                    prefixIcon: Icon(Icons.calendar_today_outlined),
                                  ),
                                  validator: (val) => (val == null || int.tryParse(val) == null) ? 'Invalid' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  style: context.bodyMedium,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  ),
                                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  onChanged: (val) => setState(() => _selectedGender = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedBloodGroup,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Blood Group',
                              prefixIcon: Icon(Icons.water_drop_outlined),
                            ),
                            items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                            onChanged: (val) => setState(() => _selectedBloodGroup = val!),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _conditionsController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Chronic Conditions (e.g. Asthma, Diabetes)',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _allergiesController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Known Allergies (e.g. Peanuts, Penicillin)',
                              prefixIcon: Icon(Icons.warning_amber_outlined),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Hospital Sync Connection'),
                          DropdownButtonFormField<String>(
                            value: _selectedHospital,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Affiliated Hospital',
                              prefixIcon: Icon(Icons.local_hospital_outlined),
                            ),
                            items: _hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            onChanged: (val) => setState(() => _selectedHospital = val!),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _hospitalPhoneController,
                            style: context.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Hospital Helpline Phone',
                              prefixIcon: Icon(Icons.phone_in_talk_outlined),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Professional profile Details'),
                          TextFormField(
                            controller: _professionController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Profession / Designation',
                              prefixIcon: Icon(Icons.work_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _orgController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Organization / Company',
                              prefixIcon: Icon(Icons.corporate_fare_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _workEmailController,
                            style: context.bodyMedium,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Work Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _workPhoneController,
                            style: context.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Work Phone Number',
                              prefixIcon: Icon(Icons.phone_android_outlined),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Emergency Contacts & Bio'),
                          TextFormField(
                            controller: _ecNameController,
                            style: context.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Contact Name',
                              prefixIcon: Icon(Icons.contact_emergency_outlined),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _ecPhoneController,
                            style: context.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Contact Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bioController,
                            style: context.bodyMedium,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Short Bio summary',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Sign Up & Create Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: context.bodySmall),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Sign In', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.bodyMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Divider(thickness: 0.8),
        ],
      ),
    );
  }
}
