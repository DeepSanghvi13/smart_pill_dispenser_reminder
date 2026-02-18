import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import 'package:smart_pill_reminder/screens/admin/admin_webpage_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Log in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Login Card
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Email field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Password field
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot your password?'),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ LOGIN BUTTON (WHITE TEXT)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D4F8B),
                          foregroundColor: Colors.white, // 👈 TEXT COLOR
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter email and password'),
                              ),
                            );
                            return;
                          }

                          // Attempt login
                          final success = await authService.login(email, password);

                          if (!context.mounted) return;

                          if (success) {
                            // Check if user is admin
                            if (authService.isAdmin) {
                              // Navigate to admin page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminWebpageScreen(),
                                ),
                              );
                            } else {
                              // Regular user login
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Login successful!'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid email or password'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white, // 👈 DOUBLE SAFE
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Google info text
            const Text(
              'Previously logged in with Google+?',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
