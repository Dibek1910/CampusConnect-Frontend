import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/config/theme.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.requestLoginOtp(_emailController.text);

      if (success) {
        setState(() {
          _otpSent = true;
        });
        _showSnackBar('OTP sent to your email');
      } else {
        _showSnackBar(authProvider.error ?? 'Failed to send OTP');
      }
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyLoginOtp(
        _emailController.text,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.capitalize()} Login'),
        elevation: 4,
      ),
      body: SafeArea(
        child:
            authProvider.isLoading
                ? const LoadingIndicator(message: 'Processing...')
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Center(
                            child: Hero(
                              tag: 'role-icon',
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.role == 'student'
                                      ? Icons.school
                                      : Icons.person,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome Back!',
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
                            'Login to your account',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondaryColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          InputField(
                            label: 'Email',
                            hint:
                                widget.role == 'student'
                                    ? 'Enter your email (e.g., student@muj.manipal.edu)'
                                    : 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              if (widget.role == 'student' &&
                                  !value.endsWith('@muj.manipal.edu')) {
                                return 'Student email must end with @muj.manipal.edu';
                              }
                              return null;
                            },
                            readOnly: _otpSent,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          const SizedBox(height: 24),
                          if (_otpSent) ...[
                            InputField(
                              label: 'OTP',
                              hint: 'Enter OTP sent to your email',
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter OTP';
                                }
                                if (value.length < 6) {
                                  return 'OTP must be 6 digits';
                                }
                                return null;
                              },
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      authProvider.isLoading
                                          ? null
                                          : _requestOtp,
                                  child: const Text('Resend OTP'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: _otpSent ? 'Login' : 'Send OTP',
                            onPressed:
                                _otpSent ? _verifyOtpAndLogin : _requestOtp,
                            isLoading: authProvider.isLoading,
                            width: double.infinity,
                            icon: _otpSent ? Icons.login : Icons.send,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.registerRoute,
                                    arguments: {'role': widget.role},
                                  );
                                },
                                child: const Text('Register'),
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
