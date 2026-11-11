import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notes_provider.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    bool success;
    if (_isSignUp) {
      success = await auth.signUpWithEmail(email, pass);
    } else {
      success = await auth.signInWithEmail(email, pass);
    }

    if (success && mounted) {
      context.read<NotesProvider>().updateUserId(auth.user?.uid);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Thất bại, vui lòng thử lại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AlertDialog(
      title: Text(_isSignUp ? 'Đăng ký tài khoản ${AppStrings.appName}' : 'Đăng nhập ${AppStrings.appName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đăng nhập để đồng bộ ghi chú tự động giữa Android, iOS và Windows thông qua Firebase.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _isSignUp = !_isSignUp);
              },
              child: Text(
                _isSignUp ? 'Đã có tài khoản? Đăng nhập ngay' : 'Chưa có tài khoản? Đăng ký',
              ),
            ),
            const Divider(),
            // Nút dùng thử dạng khách
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Dùng thử không cần tài khoản (Khách)'),
              onPressed: () async {
                await auth.signInAnonymously();
                if (mounted) {
                  context.read<NotesProvider>().updateUserId(auth.user?.uid);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _submit,
          child: auth.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isSignUp ? 'Đăng ký' : 'Đăng nhập'),
        ),
      ],
    );
  }
}
