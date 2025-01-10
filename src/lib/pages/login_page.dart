import "package:flutter/material.dart";
import "package:file_share/services/secure_storage.dart";
import "package:http/http.dart";
import "package:google_fonts/google_fonts.dart";
import "package:device_info_plus/device_info_plus.dart";
import "dart:core";
import "dart:convert";
import "dart:io";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String username = "";
  String password = "";
  String? errorText;
  List<bool> errors = [false, false];
  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;

  String baseUrl = "http://127.0.0.1:8000/file_share";

  bool validateInputs() {
    setState(() {
      errors = [
        username.isEmpty,
        password.isEmpty
      ];
    });
    return (!errors[0] && !errors[1]);
  }

  void login() async {
    List<String> deviceInfo = await getDeviceInfo();
    var response = await post(Uri.parse(baseUrl + "/login/"),
        body: {"username": username, "password": password, "device_id": deviceInfo[0], "device_name": deviceInfo[1], "platform": deviceInfo[2]});

    var info = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await SecureStorage.delete();
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

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await SecureStorage.delete();
        return;
      }
    }
    if (info["user_id"] != null) {await Navigator.popAndPushNamed(context, "/home");}
  }

  Future<List<String>> getDeviceInfo() async {
    List<String> data = [];
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isWindows) {
      var info = await deviceInfo.windowsInfo;
      data = [info.deviceId, info.computerName, "windows"];
    }
    return data;
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
    getDeviceInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Login",
            style: TextStyle(fontFamily: primaryFont)
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Username or email",
                    hintText: "Username or email",
                    border: OutlineInputBorder(),
                    errorText: errors[0] ? "Username/email cannot be empty" : null
                  ),
                  style: TextStyle(fontFamily: primaryFont),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      username = value;
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
                    errorText: errors[1] ? "Password cannot be empty" : null
                  ),
                  style: TextStyle(fontFamily: primaryFont),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      password = value;
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
                    bool valid = validateInputs();
                    if (valid) login();
                  },
                  child:
                      Text("Login", style: TextStyle(fontFamily: primaryFont))),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(onPressed: () {Navigator.popAndPushNamed(context, "/signup");}, child: Text("Don't have an account yet? Sign up here!", style: TextStyle(fontFamily: primaryFont))),
              )
            ],
          ),
        ));
  }
}
