import "dart:convert";

import "package:file_share/services/secure_storage.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart";

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late int user_id;

  List devices = [];

  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;

  String baseUrl = "http://127.0.0.1:8000/file_share";

  Future<void> getDevices() async {
    var response = await post(Uri.parse(baseUrl + "/get-devices/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      devices = info;
    });
  }

  Widget deviceCard(String name, String platform, int count) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon((platform == "ios")
                ? Icons.phone_iphone_outlined
                : (platform == "android")
                    ? Icons.phone_android_outlined
                    : (platform == "macos")
                        ? Icons.laptop_mac_outlined
                        : Icons.desktop_windows_outlined),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        name + ((count != 0) ? " (${count})" : ""),
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: primaryFont,
                        ),
                      ),
                      Text(
                        "Platform: ${platform}",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: primaryFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadUserId() async {
    String? num = await SecureStorage.read("user_id");
    setState(() {
      user_id = int.parse(num!);
    });
    await getDevices();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserId();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: devices
            .map(
              (e) => deviceCard(e["name"], e["platform"], e["count"]),
            )
            .toList(),
      ),
    );
  }
}