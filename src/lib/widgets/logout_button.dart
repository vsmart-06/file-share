import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:file_share/services/secure_storage.dart";

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;

    return TextButton.icon(
      onPressed: () async {
        await SecureStorage.delete();
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => route == "/");
      }, 
      icon: Icon(Icons.logout),
      label: Text("Logout", style: TextStyle(fontFamily: primaryFont),),
      iconAlignment: IconAlignment.end,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}