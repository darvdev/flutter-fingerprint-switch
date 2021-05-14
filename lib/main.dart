import 'package:fingerprint/pages/start_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData().copyWith(
      primaryColor: Colors.teal,
      accentColor: Colors.teal,
    ),
    home: StartPage(),
  ));
}