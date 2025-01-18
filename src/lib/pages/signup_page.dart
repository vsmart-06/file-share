import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart";
import "package:file_share/services/secure_storage.dart";
import "dart:core";
import "dart:convert";

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String username = "";
  String email = "";
  String password = "";
  String? errorText;
  List<bool> errors = [false, false, false];
  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;


  String baseUrl = "https://file-share-weld.vercel.app/file_share";

  bool validateInputs() {
    setState(() {
      errors = [
        RegExp(r"(?=.*[^a-z0-9.\-_])|^.{0,5}$|^.{10,}$").hasMatch(username),
        !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email),
        !RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}").hasMatch(password)
      ];
    });
    return (!errors[0] && !errors[1] && !errors[2]);
  }

  void signup() async {
    var response = await post(Uri.parse(baseUrl + "/signup/"),
        body: {"username": username, "email": email, "password": password});

    var info = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await SecureStorage.delete();
      await SecureStorage.writeOne("user_id", info["user_id"].toString());
      await Navigator.popAndPushNamed(context, "/otp");
      return;

    } else if (response.statusCode == 400) {
      setState(() {
        errorText = info["error"];
      });
      return;
    }
  }

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await SecureStorage.delete();
        await Navigator.pushNamedAndRemoveUntil(context, "/", (route) => route == "/");
        return;
      }
    }
    if (info["user_id"] != null) await Navigator.popAndPushNamed(context, "/home");
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Sign Up",
            style: TextStyle(fontFamily: primaryFont)
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Username",
                    hintText: "Username",
                    border: OutlineInputBorder(),
                    errorText: errors[0] ? "Invalid username" : null,
                    errorStyle: TextStyle(fontFamily: primaryFont)
                  ),
                  style: TextStyle(fontFamily: primaryFont),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      username = value;
                      errors[0] = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Email",
                    border: OutlineInputBorder(),
                    errorText: errors[1] ? "Invalid email" : null,
                    errorStyle: TextStyle(fontFamily: primaryFont)
                  ),
                  style: TextStyle(fontFamily: primaryFont),
                  onChanged: (value) {
                    setState(() {
                      email = value;
                      errors[1] = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Password",
                    border: OutlineInputBorder(),
                    errorText: errors[2] ? "Invalid password" : null,
                    errorStyle: TextStyle(fontFamily: primaryFont)),
                    style: TextStyle(fontFamily: primaryFont),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      password = value;
                      errors[2] = false;
                    });
                  },
                ),
              ),
              (errorText != null) ? Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(errorText!, style: TextStyle(color: Colors.red),),
              ) : Container(),
              TextButton(
                  style: ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(125, 60)),
                      backgroundColor: WidgetStatePropertyAll(Colors.blue),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)))),
                  onPressed: () {
                    bool valid = validateInputs();
                    if (valid) signup();
                  },
                  child:
                      Text("Sign Up", style: TextStyle(fontFamily: primaryFont))),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(onPressed: () {Navigator.popAndPushNamed(context, "/");}, child: Text("Already have an account? Login here!", style: TextStyle(fontFamily: primaryFont)))),
            ],
          ),
        ));
  }
}
