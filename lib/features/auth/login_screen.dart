import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart'; // Added for admin notifications

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passError;

  Future<void> _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    setState(() {
      _emailError = null;
      _passError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await auth.signIn(emailController.text.trim(), passController.text.trim());

      // Notify admin of user login
      if (!auth.isAdmin) {
        await notificationProvider.sendNotificationToAdmin(
          title: 'User Login',
          body: 'User ${emailController.text.trim()} logged in.',
        );
      }

      // Redirect based on role
      if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      String errorMessage = 'Login failed: ${e.toString()}';
      // Handle Firebase-specific errors
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final formWidth = isWideScreen ? constraints.maxWidth * 0.5 : constraints.maxWidth * 0.9;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWideScreen ? 32 : 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hotel, size: 60, color: Colors.indigo),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome Back!",
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.indigo),
                      ),
                      const SizedBox(height: 30),
                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          errorText: _emailError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter your email";
                          if (!value.contains("@")) return "Enter a valid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password
                      TextFormField(
                        controller: passController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          errorText: _passError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter your password";
                          if (value.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Login", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }
}