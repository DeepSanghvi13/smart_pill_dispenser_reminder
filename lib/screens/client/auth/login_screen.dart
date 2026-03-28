import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      emailController.text = widget.prefilledEmail!;
    }
  }

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final horizontalPadding = isLandscape ? 20.0 : 12.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 12, horizontalPadding, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isLandscape ? 760 : 520),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isLandscape ? 20 : 24),
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

                          const SizedBox(height: 22),

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

                          const SizedBox(height: 20),

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
                                final auth = context.read<AuthService>();
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter email and password'),
                                    ),
                                  );
                                  return;
                                }

                                // Attempt login
                                final success =
                                    await auth.login(email, password);

                                if (!context.mounted) return;

                                if (success) {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        auth.isAdmin
                                            ? 'Admin login successful!'
                                            : 'Login successful!',
                                      ),
                                      duration:
                                          const Duration(milliseconds: 900),
                                    ),
                                  );

                                  if (auth.isAdmin) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.adminHome,
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.userHome,
                                      (route) => false,
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Invalid credentials. Register first, then login.',
                                      ),
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

                          const SizedBox(height: 16),

                          // Navigate to Register page
                          TextButton(
                            onPressed: () async {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                            child: const Text('New user? Create an account'),
                          ),

                          const SizedBox(height: 8),

                          TextButton.icon(
                            onPressed: _isGoogleLoading
                                ? null
                                : () async {
                                    setState(() => _isGoogleLoading = true);

                                    final success = await context
                                        .read<AuthService>()
                                        .loginWithGoogle();

                                    if (!context.mounted) return;

                                    setState(() => _isGoogleLoading = false);

                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Google login successful!'),
                                          duration: Duration(milliseconds: 900),
                                        ),
                                      );
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        AppRoutes.userHome,
                                        (route) => false,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Google login failed. Try again.'),
                                        ),
                                      );
                                    }
                                  },
                            icon: _isGoogleLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login, color: Colors.blue),
                            label: const Text(
                              'Previously logged in with Google+? Continue',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
