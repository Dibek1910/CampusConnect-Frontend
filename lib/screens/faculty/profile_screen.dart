import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/models/profile_model.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/otp_verification_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/config/theme.dart';

class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late ProfileModel _profile;
  bool _isEditing = false;
  bool _isVerifyingOtp = false;
  String? _verificationEmail;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String departmentName = authProvider.facultyProfile!.getDepartmentName();

    _profile = ProfileModel(
      id: authProvider.facultyProfile!.id,
      name: authProvider.facultyProfile!.name,
      email: authProvider.user!.email,
      phoneNumber: authProvider.facultyProfile!.phoneNumber,
      department: departmentName,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(String otp) async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final otpVerified = await authProvider.verifyOtp(_profile.email, otp);

    if (otpVerified) {
      final updated = await authProvider.updateFacultyProfile(_profile, otp);

      if (updated) {
        setState(() {
          _isVerifyingOtp = false;
          _isEditing = false;
        });
        _showSnackBar('Profile updated successfully');
      } else {
        _showSnackBar(authProvider.error ?? 'Failed to update profile');
      }
    } else {
      _showSnackBar(authProvider.error ?? 'Invalid OTP');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _isVerifyingOtp = false;
                }
              });
            },
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
          ),
        ],
        elevation: 4,
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Updating profile...')
              : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Hero(
                                tag: 'profile-avatar',
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    _profile.name.isNotEmpty
                                        ? _profile.name[0].toUpperCase()
                                        : 'F',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Personal Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Name',
                                      hint: 'Enter your name',
                                      controller: TextEditingController(
                                        text: _profile.name,
                                      ),
                                      enabled: _isEditing,
                                      onChanged:
                                          (value) =>
                                              _profile = ProfileModel(
                                                id: _profile.id,
                                                name: value,
                                                email: _profile.email,
                                                phoneNumber:
                                                    _profile.phoneNumber,
                                                department: _profile.department,
                                              ),
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Email',
                                      hint: 'Enter your email',
                                      controller: TextEditingController(
                                        text: _profile.email,
                                      ),
                                      enabled: false,
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Phone Number',
                                      hint: 'Enter your phone number',
                                      controller: TextEditingController(
                                        text: _profile.phoneNumber,
                                      ),
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.phone,
                                      onChanged:
                                          (value) =>
                                              _profile = ProfileModel(
                                                id: _profile.id,
                                                name: _profile.name,
                                                email: _profile.email,
                                                phoneNumber: value,
                                                department: _profile.department,
                                              ),
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Department',
                                      hint: 'Department',
                                      controller: TextEditingController(
                                        text: _profile.department ?? '',
                                      ),
                                      enabled: false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (_isEditing && !_isVerifyingOtp)
                              ButtonWidget(
                                text: 'Update Profile',
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isVerifyingOtp = true;
                                      _verificationEmail = _profile.email;
                                    });

                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    authProvider.generateOtp(_profile.email);
                                  }
                                },
                                width: double.infinity,
                              ),
                            if (_isVerifyingOtp)
                              OtpVerificationWidget(
                                email: _verificationEmail!,
                                onVerified: _updateProfile,
                                onCancel: () {
                                  setState(() {
                                    _isVerifyingOtp = false;
                                    _verificationEmail = null;
                                  });
                                },
                              ),
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
