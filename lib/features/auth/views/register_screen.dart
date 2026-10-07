import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _fullNameController.text.trim(),
            role: 'customer',
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: AppColors.ready,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Customer Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rejected.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.rejected.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.rejected),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  label: 'Full Name',
                  hint: 'e.g. Rajesh Patel',
                  controller: _fullNameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email Address',
                  hint: 'e.g. rajesh@gmail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'e.g. 9876543210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New registrations are created as Customer accounts. An administrator can assign staff roles later.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
