import 'package:file_share/pages/login_page.dart';
import 'package:file_share/pages/otp_page.dart';
import 'package:file_share/pages/signup_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      routes: {
        "/": (context) => Login(),
        "/signup": (context) => Signup(),
        "/otp": (context) => OtpPage()
      },
      theme: ThemeData(useMaterial3: false),
    )
  );
}
