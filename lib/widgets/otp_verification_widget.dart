import 'package:flutter/material.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/config/theme.dart';

class OtpVerificationWidget extends StatefulWidget {
  final String email;
  final Function(String) onVerified;
  final VoidCallback onCancel;

  const OtpVerificationWidget({
    Key? key,
    required this.email,
    required this.onVerified,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify OTP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An OTP has been sent to ${widget.email}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'OTP',
                hint: 'Enter OTP sent to your email',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.lock_outline),
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
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ButtonWidget(
                    text: 'Verify',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onVerified(_otpController.text);
                      }
                    },
                    width: 120,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
