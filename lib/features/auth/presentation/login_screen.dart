import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../cubit/admin_auth_cubit.dart';
import '../cubit/admin_auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Reset password', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(),
          decoration: const InputDecoration(hintText: 'Admin email'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    if (email != null && email.isNotEmpty && context.mounted) {
      context.read<AdminAuthCubit>().sendPasswordReset(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminAuthCubit, AdminAuthState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
        context.read<AdminAuthCubit>().clearError();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.4,
              colors: [AppColors.navyPanel2, AppColors.navyDeep],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Expeditioneer',
                      style: AppTypography.display(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs6),
                    Text(
                      'ADMIN CONSOLE',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg32),
                    TextField(
                      controller: _emailController,
                      style: AppTypography.body(),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: AppSpacing.sm16),
                    TextField(
                      controller: _passwordController,
                      style: AppTypography.body(),
                      obscureText: true,
                      onSubmitted: (_) => _submit(context),
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: AppSpacing.md20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _submit(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                        ),
                        child: const Text('Sign in'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm12),
                    TextButton(
                      onPressed: () => _forgotPassword(context),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.body(color: AppColors.creamDim),
                      ),
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

  void _submit(BuildContext context) {
    context.read<AdminAuthCubit>().signIn(_emailController.text, _passwordController.text);
  }
}
