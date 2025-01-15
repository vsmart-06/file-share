import 'package:file_share/pages/home_page.dart';
import 'package:file_share/pages/login_page.dart';
import 'package:file_share/pages/otp_page.dart';
import 'package:file_share/pages/signup_page.dart';
import 'package:flutter/material.dart';
import "package:google_fonts/google_fonts.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      routes: {
        "/": (context) => Login(),
        "/signup": (context) => Signup(),
        "/otp": (context) => OtpPage(),
        "/home": (context) => Home()
      },
      theme: ThemeData(useMaterial3: false, fontFamily: GoogleFonts.redHatDisplay().fontFamily),
    )
  );
}
