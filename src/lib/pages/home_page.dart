import "dart:convert";
import "package:file_share/services/secure_storage.dart";
import "package:file_share/widgets/logout_button.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:http/http.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late int user_id;
  bool login = false;

  List devices = [];
  List contacts = [];

  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;
  late TabController controller;

  String baseUrl = "http://127.0.0.1:8000/file_share";

  Future<void> getDevices() async {
    var response = await post(Uri.parse(baseUrl + "/get-devices/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      devices = info;
    });
  }
  
  Future<void> getContacts() async {
    var response = await post(Uri.parse(baseUrl + "/get-contacts/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      contacts = info;
    });
  }

  Widget deviceCard(String name, String platform, int count) {
    platform = platform[0].toUpperCase() + platform.substring(1);
    platform = platform.replaceAll("os", "OS");
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

  Widget contactCard(String username, String email, String status) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              (status == "approved")
                  ? Icons.check
                  : (status == "outgoing")
                      ? Icons.north_east
                      : Icons.south_west,
              color: (status == "approved") ? Colors.green : Colors.grey,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: (status == "approved") ? null : Colors.yellow[50],
                child: TextButton(
                  onPressed: () {
                    if (status != "approved") {}
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Username: ${username}",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: primaryFont,
                          ),
                        ),
                        Text(
                          "Email: ${email}",
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
          ),
        ],
      ),
    );
  }

  Widget devicesPage() {
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

  Widget contactsPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Column(
            children: contacts
                .map((e) => contactCard(e["username"], e["email"], e["status"]))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      String user = "";
                      String error = "";
                      return StatefulBuilder(
                        builder: (stateContext, setDialogState) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        title: Text("New contact", style: TextStyle(fontFamily: primaryFont),),
                        content: TextFormField(
                          decoration: InputDecoration(
                              labelText: "User",
                              hintText: "Username/Email",
                              border: OutlineInputBorder(),
                              errorText: error.isNotEmpty
                                  ? error
                                  : null),
                          style: TextStyle(fontFamily: primaryFont),
                          onChanged: (value) {
                            setDialogState(() {
                              user = value;
                            });
                          },
                        ),
                        actions: [
                          TextButton.icon(
                            onPressed: () async {
                              if (user.isEmpty) {
                                setDialogState(() {
                                  error = "Username/Email cannot be empty";
                                });
                                return;
                              }
                              var response = await post(Uri.parse(baseUrl + "/add-contact/"),
                                  body: {"user_id": user_id.toString(), "second": user});

                              var info = jsonDecode(response.body);
                              if (response.statusCode == 400) {
                                setDialogState(() {
                                  error = info["error"];
                                });
                                return;
                              }
                              Navigator.of(dialogContext).pop();
                            }, 
                            label: Text("Send", style: TextStyle(fontFamily: primaryFont),),
                            icon: Icon(Icons.send),
                            iconAlignment: IconAlignment.end,
                          ),
                        ],
                      )
                      );
                    }).then((value) async => await getContacts());
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "+ New contact",
                  style: TextStyle(fontFamily: primaryFont),
                ),
              ),
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)))),
            ),
          )
        ],
      ),
    );
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
        login = true;
      });
      getDevices();
      getContacts();
    } else {
      await SecureStorage.delete();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => route == "/");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserId();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (!login)
      return Scaffold(body: Center(child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100)));
    return Scaffold(
      appBar: AppBar(
        title: Text("Home", style: TextStyle(fontFamily: primaryFont)),
        centerTitle: true,
        actions: [LogoutButton()],
        bottom: TabBar(
          controller: controller,
          tabs: [
            Tab(
                child: Text(
              "Devices",
              style: TextStyle(fontFamily: primaryFont),
            )),
            Tab(
                child: Text(
              "Contacts",
              style: TextStyle(fontFamily: primaryFont),
            )),
            Tab(
                child: Text(
              "Documents",
              style: TextStyle(fontFamily: primaryFont),
            )),
          ],
        ),
      ),
      body: TabBarView(controller: controller, children: [
        devicesPage(),
        contactsPage(),
        Container()
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: IconButton(onPressed: () {}, icon: Icon(Icons.upload)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
