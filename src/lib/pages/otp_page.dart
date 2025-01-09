import "package:flutter/material.dart";
import "package:file_share/services/secure_storage.dart";
import "package:http/http.dart";
import "package:google_fonts/google_fonts.dart";
import "dart:core";
import "dart:convert";

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  late int user_id;

  String code = "";
  bool error = false;
  String? errorText;
  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;

  String baseUrl = "http://127.0.0.1:8000/file_share";

  void checkCode() async {
    var response = await post(Uri.parse(baseUrl + "/check-code/"),
        body: {"user_id": user_id.toString(), "code": code});

    var info = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await SecureStorage.writeMany({"user_id": info["user_id"].toString(), "last_login": DateTime.now().toString()});
      await Navigator.popAndPushNamed(context, "/home");
      return;
    } else if (response.statusCode == 400) {
      setState(() {
        errorText = info["error"];
      });
      return;
    }
  }

  Future<bool> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        return false;
      }
    }
    return (info["user_id"] != null);
  }

  Future<void> loadUserId() async {
    if (await checkLogin()) {
      String? num = await SecureStorage.read("user_id");
      setState(() {
        user_id = int.parse(num!);
      });
    }
    else {
      await SecureStorage.delete();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => route == "/");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "OTP",
            style: TextStyle(fontFamily: primaryFont)
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  "An email was sent with a 6 digit verification code. Enter that code to login",
                  style: TextStyle(fontFamily: primaryFont),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "OTP",
                    hintText: "OTP",
                    border: OutlineInputBorder(),
                    errorText: (error == true && errorText == null) ? "Code has to be 6 digits long" : null
                  ),
                  style: TextStyle(fontFamily: primaryFont),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      code = value;
                    });
                  },
                ),
              ),
              (errorText != null)
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        errorText!,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : Container(),
              TextButton(
                  style: ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(125, 60)),
                      backgroundColor: WidgetStatePropertyAll(Colors.blue),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)))),
                  onPressed: () {
                    try {
                      int.parse(code);
                      if (code.length != 6) {
                        setState(() {
                          error = true;
                        });
                      }
                    }
                    catch (e) {
                      setState(() {
                        error = true;
                      });
                    }
                    if (!error) checkCode();
                  },
                  child:
                      Text("Verify", style: TextStyle(fontFamily: primaryFont))),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(onPressed: () {Navigator.popAndPushNamed(context, "/");}, child: Text("Already have an account? Login here!", style: TextStyle(fontFamily: primaryFont))),
              )
            ],
          ),
        ));
  }
}
