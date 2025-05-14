import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart';

const appId = '8YLfi6BITxTiH1sT4udmgimcGZ45dPo1ILAGTdgu';
const restKey = 'scK02G7UzAq13Ogpv4K7RjrbJBaxVoJAyPidzjIM';
const serverUrl = 'https://parseapi.back4app.com';

class AuthPage extends StatefulWidget {
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  void toggleMode() {
    setState(() => isLogin = !isLogin);
  }

  Future<void> authenticate() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    final url = isLogin ? '$serverUrl/login' : '$serverUrl/users';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "Content-Type": "application/json"
      },
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final sessionToken = data['sessionToken'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            username: username,
            sessionToken: sessionToken,
          ),
        ),
      );
    } else {
      final error = jsonDecode(response.body)['error'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(title: Text("Error"), content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(controller: usernameController, decoration: InputDecoration(labelText: "Username")),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: authenticate, child: Text(isLogin ? "Login" : "Sign Up")),
              TextButton(
                onPressed: toggleMode,
                child: Text(isLogin ? "Don't have an account? Sign up" : "Already have an account? Login"),
              )
            ],
          ),
        ),
      );
}