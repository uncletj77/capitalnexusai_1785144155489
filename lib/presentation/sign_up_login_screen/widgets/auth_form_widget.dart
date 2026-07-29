import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class AuthFormWidget extends StatefulWidget {
  final bool isSignUp;
  final bool isLoading;
  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function(String email, String password, String fullName)
  onSignUp;
  final Future<void> Function(String email) onForgotPassword;

  const AuthFormWidget({
    required this.isSignUp,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgotPassword,
    super.key,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'amina.hassan@capitalnexus.ai',
  );
  final _passwordController = TextEditingController(text: 'Nexus@2026');
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.isSignUp) {
      widget.onSignUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      widget.onSignIn(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isSignUp) ...[
            _buildLabel('Full Name', theme),
            const SizedBox(height: 4),
            _buildUnderlineField(
              controller: _nameController,
              hint: 'Amina Hassan',
              iconName: 'person_outline',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 24),
          ],
          _buildLabel('Email Address', theme),
          const SizedBox(height: 4),
          _buildUnderlineField(
            controller: _emailController,
            hint: 'your@email.com',
            iconName: 'mail_outline',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildLabel('Password', theme),
          const SizedBox(height: 4),
          _buildPasswordField(theme),
          if (!widget.isSignUp) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppTheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: _rememberMe
                                ? AppTheme.primary
                                : AppTheme.mutedLight,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      widget.onForgotPassword(_emailController.text.trim()),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Forgot password?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submit,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isSignUp ? 'Create Account' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (widget.isSignUp) ...[
            const SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'By signing up, you agree to our ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedLight,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppTheme.mutedLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String hint,
    required String iconName,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppTheme.onSurfaceLight,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.mutedLight,
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Minimum 6 characters';
        return null;
      },
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppTheme.onSurfaceLight,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: '••••••••',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CustomIconWidget(
            iconName: 'lock_outline',
            color: AppTheme.mutedLight,
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: CustomIconWidget(
            iconName: _obscurePassword
                ? 'visibility_outlined'
                : 'visibility_off_outlined',
            color: AppTheme.mutedLight,
            size: 18,
          ),
        ),
      ),
    );
  }
}
