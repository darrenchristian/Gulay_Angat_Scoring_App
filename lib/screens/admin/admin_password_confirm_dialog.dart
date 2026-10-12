import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Shows a confirmation dialog requiring the currently signed-in admin's password
/// before executing [onAuthorizedReset].
Future<bool> showAdminPasswordResetDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onAuthorizedReset,
}) async {
  final passwordCtrl = TextEditingController();
  bool obscurePassword = true;
  bool isSubmitting = false;
  String? errorText;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> handleSubmit() async {
          final password = passwordCtrl.text;
          if (password.isEmpty) {
            setState(() => errorText = 'Please enter your admin password.');
            return;
          }

          setState(() {
            isSubmitting = true;
            errorText = null;
          });

          final authProvider = context.read<AppAuthProvider>();
          final verifyError = await authProvider.verifyAdminPassword(password);
          if (verifyError != null) {
            if (ctx.mounted) {
              setState(() {
                isSubmitting = false;
                errorText = verifyError;
              });
            }
            return;
          }

          try {
            await onAuthorizedReset();
            if (ctx.mounted) {
              Navigator.of(ctx).pop(true);
            }
          } catch (e) {
            if (ctx.mounted) {
              setState(() {
                isSubmitting = false;
                errorText = 'Failed to reset scores: $e';
              });
            }
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  enabled: !isSubmitting,
                  autofocus: true,
                  onSubmitted: (_) => handleSubmit(),
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    hintText: 'Enter your admin password to confirm',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    errorText: errorText,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(130, 40),
              ),
              onPressed: isSubmitting ? null : handleSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(isSubmitting ? 'Verifying...' : 'Reset Scores'),
            ),
          ],
        );
      },
    ),
  );

  return result == true;
}
