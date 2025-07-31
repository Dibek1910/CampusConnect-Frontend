import 'package:flutter/material.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/config/theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Hero(
                  tag: 'app-logo',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your role to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              AnimatedListItem(
                delay: const Duration(milliseconds: 100),
                child: _buildRoleCard(
                  context,
                  title: 'Student',
                  description: 'Book appointments with faculty members',
                  icon: Icons.school,
                  onTap: () => _navigateToRegister(context, 'student'),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedListItem(
                delay: const Duration(milliseconds: 200),
                child: _buildRoleCard(
                  context,
                  title: 'Faculty',
                  description: 'Manage student appointment requests',
                  icon: Icons.person,
                  onTap: () => _navigateToRegister(context, 'faculty'),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => _buildRoleSelectionDialog(context),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Your Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.school, color: AppTheme.primaryColor),
            title: const Text('Student'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamed(AppRouter.loginRoute, arguments: {'role': 'student'});
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: AppTheme.primaryColor),
            title: const Text('Faculty'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamed(AppRouter.loginRoute, arguments: {'role': 'faculty'});
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _navigateToRegister(BuildContext context, String role) {
    Navigator.of(
      context,
    ).pushNamed(AppRouter.registerRoute, arguments: {'role': role});
  }
}
