// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookings/presentation/authentication/widgets/logo.dart';
import 'package:bookings/presentation/home/widgets/bottom_nav.dart';
import 'package:bookings/providers/auth.dart';

import '../widgets/bg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(      
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const LogoWidget(),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail, color: Color(0xff000000)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Color(0xff000000)),
                      ),
                      obscureText: true,
                    ),
                    
                    TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forget_password');
                          },
                          child: const Text('Forgot Password?'),
                        ),
                    const SizedBox(
                      height: 32,
                      width: double.infinity,), // Increased spacing for better layout
                    ElevatedButton(
                      onPressed: () async {
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();
                        await context
                            .read<AuthProvider>()
                            .signInWithEmailAndPassword(context, email, password);
                        if (context.read<AuthProvider>().user != null) {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => BottomBar()));
                        }
                      },
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin');
                      },
                      child: const Text('Login as admin'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('Don\'t have an account?'),
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
}