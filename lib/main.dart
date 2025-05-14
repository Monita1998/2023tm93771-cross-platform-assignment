import 'package:flutter/material.dart';
import 'auth_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Back4App Web',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthPage(),
      );
}
