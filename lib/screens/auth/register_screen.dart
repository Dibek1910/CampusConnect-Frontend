import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/services/api_service.dart';
import 'package:campus_connect/config/theme.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _courseController = TextEditingController(text: "B.Tech");
  String? _selectedBranch;
  String? _selectedDepartment;
  final _otpController = TextEditingController();

  final List<int> _yearOptions = [1, 2, 3, 4];
  List<int> _semesterOptions = [1, 2];
  int _selectedYear = 1;
  int _selectedSemester = 1;

  bool _otpSent = false;
  String? _email;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _branchOptions = [];
  List<String> _departmentOptions = [];
  bool _isLoading = true;
  String? _fetchError;

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
    _loadOptions();
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _registrationNumberController.dispose();
    _courseController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      if (widget.role == 'student') {
        final response = await ApiService.get('/auth/branches');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _branchOptions = List<String>.from(response.data['data']);
          });
        } else {
          setState(() {
            _fetchError = response.error ?? 'Failed to load branch options';
          });
        }
      } else {
        final response = await ApiService.get('/auth/departments');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _departmentOptions = List<String>.from(response.data['data']);
          });
        } else {
          setState(() {
            _fetchError = response.error ?? 'Failed to load department options';
          });
        }
      }
    } catch (e) {
      setState(() {
        _fetchError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSemesterOptions(int year) {
    setState(() {
      switch (year) {
        case 1:
          _semesterOptions = [1, 2];
          break;
        case 2:
          _semesterOptions = [3, 4];
          break;
        case 3:
          _semesterOptions = [5, 6];
          break;
        case 4:
          _semesterOptions = [7, 8];
          break;
        default:
          _semesterOptions = [1, 2];
      }
      _selectedSemester = _semesterOptions[0];
    });
  }

  void _extractRegistrationNumber(String email) {
    if (email.contains('@muj.manipal.edu')) {
      final parts = email.split('@')[0].split('.');
      if (parts.length > 1) {
        setState(() {
          _registrationNumberController.text = parts[1];
        });
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      if (widget.role == 'student') {
        userData.addAll({
          'registrationNumber': _registrationNumberController.text,
          'course': _courseController.text,
          'branch': _selectedBranch,
          'currentYear': _selectedYear,
          'currentSemester': _selectedSemester,
        });
      } else {
        userData.addAll({'department': _selectedDepartment});
      }

      dynamic result;
      if (widget.role == 'student') {
        result = await authProvider.registerStudent(userData);
      } else {
        result = await authProvider.registerFaculty(userData);
      }

      if (result != null) {
        setState(() {
          _otpSent = true;
          _email = _emailController.text;
        });
        _showSnackBar('OTP sent to your email');
      } else {
        _showSnackBar(authProvider.error ?? 'Registration failed');
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyRegistrationOtp(
        _email!,
        _otpController.text,
      );

      if (success) {
        if (widget.role == 'student') {
          Navigator.of(
            context,
          ).pushReplacementNamed(AppRouter.studentHomeRoute);
        } else {
          Navigator.of(
            context,
          ).pushReplacementNamed(AppRouter.facultyDashboardRoute);
        }
      } else {
        _showSnackBar(authProvider.error ?? 'Invalid OTP');
      }
    }
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

  Widget _buildResponsiveDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required Function(String?) validator,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                value: value,
                validator: (val) => validator(val),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: MediaQuery.of(context).size.height * 0.5,
                items:
                    items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Tooltip(
                          message: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.capitalize()} Registration'),
        elevation: 4,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const LoadingIndicator(message: 'Loading options...')
                : _fetchError != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Error: $_fetchError',
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOptions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.05,
                      vertical: 24.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_otpSent) ...[
                            Text(
                              'Create Account',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please fill in the details below',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
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
                                      label: 'Full Name',
                                      hint: 'Enter your full name',
                                      controller: _nameController,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Email',
                                      hint:
                                          widget.role == 'student'
                                              ? 'Enter your email (e.g., student@muj.manipal.edu)'
                                              : 'Enter your email',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        if (widget.role == 'student' &&
                                            !value.endsWith(
                                              '@muj.manipal.edu',
                                            )) {
                                          return 'Student email must end with @muj.manipal.edu';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (widget.role == 'student') {
                                          _extractRegistrationNumber(value);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    InputField(
                                      label: 'Phone Number',
                                      hint: 'Enter your 10-digit phone number',
                                      controller: _phoneNumberController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (value.length != 10 ||
                                            !RegExp(
                                              r'^\d{10}$',
                                            ).hasMatch(value)) {
                                          return 'Please enter a valid 10-digit phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (widget.role == 'student') ...[
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Academic Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      InputField(
                                        label: 'Registration Number',
                                        hint: 'Registration Number',
                                        controller:
                                            _registrationNumberController,
                                        prefixIcon: const Icon(
                                          Icons.badge_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your registration number';
                                          }
                                          return null;
                                        },
                                        readOnly: true,
                                        enabled: false,
                                      ),
                                      const SizedBox(height: 16),
                                      InputField(
                                        label: 'Course',
                                        hint:
                                            'Enter your course (e.g., B.Tech)',
                                        controller: _courseController,
                                        prefixIcon: const Icon(
                                          Icons.school_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your course';
                                          }
                                          return null;
                                        },
                                        readOnly: true,
                                        enabled: false,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildResponsiveDropdown(
                                        label: 'Branch',
                                        hint: 'Select your branch',
                                        items: _branchOptions,
                                        value: _selectedBranch,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedBranch = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select your branch';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Current Year',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16,
                                                    color:
                                                        AppTheme
                                                            .textPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    color: Colors.white,
                                                  ),
                                                  child: DropdownButtonFormField<
                                                    int
                                                  >(
                                                    decoration:
                                                        const InputDecoration(
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                    value: _selectedYear,
                                                    items:
                                                        _yearOptions.map((
                                                          year,
                                                        ) {
                                                          return DropdownMenuItem<
                                                            int
                                                          >(
                                                            value: year,
                                                            child: Text(
                                                              year.toString(),
                                                            ),
                                                          );
                                                        }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        _updateSemesterOptions(
                                                          value,
                                                        );
                                                      }
                                                    },
                                                    validator: (value) {
                                                      if (value == null) {
                                                        return 'Required';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Current Semester',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16,
                                                    color:
                                                        AppTheme
                                                            .textPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    color: Colors.white,
                                                  ),
                                                  child: DropdownButtonFormField<
                                                    int
                                                  >(
                                                    decoration:
                                                        const InputDecoration(
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                    value: _selectedSemester,
                                                    items:
                                                        _semesterOptions.map((
                                                          semester,
                                                        ) {
                                                          return DropdownMenuItem<
                                                            int
                                                          >(
                                                            value: semester,
                                                            child: Text(
                                                              semester
                                                                  .toString(),
                                                            ),
                                                          );
                                                        }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          _selectedSemester =
                                                              value;
                                                        });
                                                      }
                                                    },
                                                    validator: (value) {
                                                      if (value == null) {
                                                        return 'Required';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Department Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildResponsiveDropdown(
                                        label: 'Department',
                                        hint: 'Select your department',
                                        items: _departmentOptions,
                                        value: _selectedDepartment,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedDepartment = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select your department';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Verify OTP',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the OTP sent to your email',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
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
                                    InputField(
                                      label: 'OTP',
                                      hint: 'Enter OTP',
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter OTP';
                                        }
                                        if (value.length < 6) {
                                          return 'OTP must be 6 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              authProvider.isLoading
                                                  ? null
                                                  : _register,
                                          child: const Text('Resend OTP'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: _otpSent ? 'Verify & Register' : 'Register',
                            onPressed: _otpSent ? _verifyOtp : _register,
                            isLoading: authProvider.isLoading,
                            width: double.infinity,
                            icon:
                                _otpSent
                                    ? Icons.check_circle_outline
                                    : Icons.app_registration,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.loginRoute,
                                    arguments: {'role': widget.role},
                                  );
                                },
                                child: const Text('Login'),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
