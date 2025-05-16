import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final appId = dotenv.env['APP_ID']!;
final restKey = dotenv.env['REST_KEY']!;
final serverUrl = dotenv.env['SERVER_URL']!;

class AuthPage extends StatefulWidget {
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  void toggleMode() => setState(() => isLogin = !isLogin);

  bool validateEmail(String input) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      isLogin ? await _handleLogin() : await _handleSignup();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final id = usernameController.text.trim();
    final password = passwordController.text.trim();
    final body =
        validateEmail(id)
            ? {"email": id, "password": password}
            : {"username": id, "password": password};

    final response = await http.post(
      Uri.parse('$serverUrl/login'),
      headers: _baseHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _navigateToDashboard(data, id);
    } else {
      _handleError(response, "Login failed");
    }
  }

  Future<void> _handleSignup() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final email = emailController.text.trim();

    final response = await http.post(
      Uri.parse('$serverUrl/users'),
      headers: _baseHeaders,
      body: jsonEncode({
        "username": username,
        "password": password,
        "email": email,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _navigateToDashboard(data, username);
    } else {
      _handleError(response, "Signup failed");
    }
  }

  void _navigateToDashboard(Map<String, dynamic> data, String id) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => DashboardPage(
              username: data['username'] ?? id,
              sessionToken: data['sessionToken'],
            ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Error"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  void _handleError(http.Response res, String fallback) {
    final msg = jsonDecode(res.body)['error'] ?? fallback;
    _showError("${res.statusCode}: $msg");
  }

  void _showPasswordResetDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Reset Password"),
            content: TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: "Registered Email"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (!validateEmail(email)) return;
                  Navigator.pop(context);
                  await resetPassword(email);
                },
                child: Text("Send"),
              ),
            ],
          ),
    );
  }

  Future<void> resetPassword(String email) async {
    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('$serverUrl/requestPasswordReset'),
      headers: _baseHeaders,
      body: jsonEncode({"email": email}),
    );
    final msg =
        response.statusCode == 200
            ? "Check your email for reset instructions."
            : "Reset failed. Try again.";

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (mounted) setState(() => isLoading = false);
  }

  Map<String, String> get _baseHeaders => {
    "X-Parse-Application-Id": appId,
    "X-Parse-REST-API-Key": restKey,
    "X-Parse-Revocable-Session": "1",
    "Content-Type": "application/json",
  };

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.indigo.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            color: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.symmetric(horizontal: width > 600 ? 300 : 24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin ? 'Welcome Back 👋' : 'Join Us ✨',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 24),
                    if (!isLogin)
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator:
                            (val) =>
                                validateEmail(val!)
                                    ? null
                                    : "Enter valid email",
                      ),
                    if (!isLogin) SizedBox(height: 16),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: isLogin ? "Username or Email" : "Username",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator:
                          (val) =>
                              val!.isEmpty ? "This field is required" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator:
                          (val) =>
                              val!.length < 6 ? "Password too short" : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(isLogin ? Icons.login : Icons.person_add),
                      label: Text(isLogin ? 'Login' : 'Sign Up'),
                      onPressed: isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading ? null : toggleMode,
                      child: Text(
                        isLogin
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Login",
                      ),
                    ),
                    if (isLogin)
                      TextButton(
                        onPressed: isLoading ? null : _showPasswordResetDialog,
                        child: Text("Forgot Password?"),
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

