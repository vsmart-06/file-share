import "dart:convert";
import "dart:io";
import "dart:math";
import "package:device_info_plus/device_info_plus.dart";
import "package:file_share/services/secure_storage.dart";
import "package:file_share/widgets/logout_button.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:http/http.dart";
import "package:file_picker/file_picker.dart";
import "package:image_picker/image_picker.dart";

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
  List<String> deviceInfo = [];

  bool deviceChange = false;
  bool contactChange = false;

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

  Widget deviceAction(String action, int device_id, String name,
      BuildContext dialogContext, Function renameFunction) {
    return TextButton.icon(
      onPressed: () async {
        if (action == "Rename" || action == "Cancel") {
          renameFunction();
          return;
        }
        if (action == "Confirm" && name.length < 3) {
          renameFunction("The new name is too short", true);
          return;
        }
        await post(Uri.parse(baseUrl + "/modify-device/"), body: {
          "device_id": device_id.toString(),
          "change": (action == "Confirm") ? "rename" : "remove",
          "name": name
        });
        Navigator.of(dialogContext).pop();
        setState(() {
          deviceChange = true;
        });
      },
      label: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          action,
          style: TextStyle(fontFamily: primaryFont),
        ),
      ),
      icon: Icon((action == "Remove")
          ? Icons.delete
          : (action == "Rename")
              ? Icons.edit
              : (action == "Confirm")
                  ? Icons.check
                  : Icons.close),
      style: ButtonStyle(
          backgroundColor:
              WidgetStatePropertyAll((action == "Remove" || action == "Cancel")
                  ? Colors.red
                  : (action == "Rename")
                      ? Colors.blue
                      : Colors.green),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    );
  }

  Widget deviceCard(
      int device_id, String identifier, String name, String platform) {
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
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      deviceChange = false;
                    });
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          bool rename = false;
                          String newName = "";
                          String error = "";
                          return StatefulBuilder(
                            builder: (stateContext, setDialogState) =>
                                AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: Text(
                                (!rename) ? "Device" : "New Device",
                                style: TextStyle(fontFamily: primaryFont),
                              ),
                              content: (!rename)
                                  ? Text("Name: ${name}\nPlatform: ${platform}",
                                      style: TextStyle(fontFamily: primaryFont))
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text("Old Name: ${name}",
                                              style: TextStyle(
                                                  fontFamily: primaryFont)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: "New Name",
                                              hintText: "New Name",
                                              errorText: (error.isEmpty)
                                                  ? null
                                                  : error,
                                              errorStyle: TextStyle(
                                                  fontFamily: primaryFont),
                                              border: OutlineInputBorder(),
                                            ),
                                            style: TextStyle(
                                                fontFamily: primaryFont),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                newName = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                              actions: (!rename)
                                  ? (identifier != deviceInfo[0])
                                      ? [
                                          deviceAction(
                                              "Remove",
                                              device_id,
                                              deviceInfo[1],
                                              dialogContext,
                                              () {}),
                                          deviceAction("Rename", device_id,
                                              deviceInfo[1], dialogContext, () {
                                            setDialogState(() {
                                              error = "";
                                              rename = true;
                                            });
                                          })
                                        ]
                                      : [
                                          deviceAction("Rename", device_id,
                                              deviceInfo[1], dialogContext, () {
                                            setDialogState(() {
                                              error = "";
                                              rename = true;
                                            });
                                          })
                                        ]
                                  : [
                                      deviceAction("Confirm", device_id,
                                          newName, dialogContext, (e, r) {
                                        setDialogState(() {
                                          error = e;
                                          rename = r;
                                        });
                                      }),
                                      deviceAction("Cancel", device_id,
                                          deviceInfo[1], dialogContext, () {
                                        setDialogState(() {
                                          error = "";
                                          rename = false;
                                        });
                                      })
                                    ],
                              actionsAlignment: MainAxisAlignment.center,
                            ),
                          );
                        }).then((value) async {
                      if (deviceChange) await getDevices();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          name,
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
              (e) => deviceCard(
                  e["device_id"], e["identifier"], e["name"], e["platform"]),
            )
            .toList(),
      ),
    );
  }

  Future<void> getContacts() async {
    var response = await post(Uri.parse(baseUrl + "/get-contacts/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      contacts = info;
    });
  }

  Widget contactAction(
      String action, String username, BuildContext dialogContext) {
    return TextButton.icon(
      onPressed: () async {
        await post(Uri.parse(baseUrl + "/modify-contact/"), body: {
          "user_id": user_id.toString(),
          "username": username,
          "change": action
        });
        Navigator.of(dialogContext).pop();
        setState(() {
          contactChange = true;
        });
      },
      label: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          action,
          style: TextStyle(fontFamily: primaryFont),
        ),
      ),
      icon: Icon((action == "Accept")
          ? Icons.check
          : (action == "Decline")
              ? Icons.close
              : (action == "Withdraw")
                  ? Icons.undo
                  : Icons.delete),
      style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: WidgetStatePropertyAll((action == "Accept")
              ? Colors.green
              : (action == "Decline")
                  ? Colors.red
                  : (action == "Withdraw")
                      ? Colors.grey[600]
                      : Colors.blue),
          foregroundColor: WidgetStatePropertyAll(Colors.white)),
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
              color: (status == "approved") ? Colors.green : Colors.grey[600],
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
                    setState(() {
                      contactChange = false;
                    });
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            title: Text(
                              status[0].toUpperCase() +
                                  status.substring(1) +
                                  ((status == "approved")
                                      ? " contact"
                                      : " request"),
                              style: TextStyle(fontFamily: primaryFont),
                            ),
                            content: Text(
                                "Username: ${username}\nEmail: ${email}",
                                style: TextStyle(fontFamily: primaryFont)),
                            actions: (status == "incoming")
                                ? [
                                    contactAction(
                                        "Accept", username, dialogContext),
                                    contactAction(
                                        "Decline", username, dialogContext)
                                  ]
                                : (status == "outgoing")
                                    ? [
                                        contactAction(
                                            "Withdraw", username, dialogContext)
                                      ]
                                    : [
                                        contactAction(
                                            "Delete", username, dialogContext)
                                      ],
                            actionsAlignment: MainAxisAlignment.center,
                          );
                        }).then((value) async {
                      if (contactChange) await getContacts();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                          builder: (stateContext, setDialogState) =>
                              AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                actionsAlignment: MainAxisAlignment.center,
                                title: Text(
                                  "New contact",
                                  style: TextStyle(fontFamily: primaryFont),
                                ),
                                content: TextFormField(
                                  decoration: InputDecoration(
                                      labelText: "User",
                                      hintText: "Username/Email",
                                      border: OutlineInputBorder(),
                                      errorText:
                                          error.isNotEmpty ? error : null,
                                      errorStyle:
                                          TextStyle(fontFamily: primaryFont)),
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
                                          error =
                                              "Username/Email cannot be empty";
                                        });
                                        return;
                                      }
                                      var response = await post(
                                          Uri.parse(baseUrl + "/add-contact/"),
                                          body: {
                                            "user_id": user_id.toString(),
                                            "second": user
                                          });

                                      var info = jsonDecode(response.body);
                                      if (response.statusCode == 400) {
                                        setDialogState(() {
                                          error = info["error"];
                                        });
                                        return;
                                      }
                                      Navigator.of(dialogContext).pop();
                                    },
                                    label: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        "Send",
                                        style:
                                            TextStyle(fontFamily: primaryFont),
                                      ),
                                    ),
                                    icon: Icon(Icons.send),
                                    iconAlignment: IconAlignment.end,
                                    style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        backgroundColor:
                                            WidgetStatePropertyAll(Colors.blue),
                                        foregroundColor: WidgetStatePropertyAll(
                                            Colors.white)),
                                  ),
                                ],
                              ));
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

  Widget recipientButton(String recipient, bool selected, Function callback) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextButton(
        onPressed: () => callback(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            recipient,
            style: TextStyle(fontFamily: primaryFont),
          ),
        ),
        style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
            backgroundColor:
                WidgetStatePropertyAll((selected) ? Colors.blue : Colors.white),
            foregroundColor: WidgetStatePropertyAll(
                (selected) ? Colors.white : Colors.black),
            side: WidgetStatePropertyAll(
                BorderSide(color: (selected) ? Colors.blue : Colors.black))),
      ),
    );
  }

  Widget autocompleteButton(String text, int index, Function callback) {
    return Column(
      children: [
        (index == 0) ? Divider(
          thickness: 1,
          color: Colors.black,
        ) : Container(),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: TextButton(
            onPressed: () {
              callback();
            },
            child: Text(
              text,
              style: TextStyle(fontFamily: primaryFont, color: Colors.black),
            ),
          ),
        ),
        Divider(
          thickness: 1,
          color: Colors.black,
        )
      ],
    );
  }

  Widget generateAutocomplete(
      bool generate, String text, bool device, Function callback) {
    if (!generate) return Container();

    text = text.toLowerCase();
    List names = [];
    if (device) {
      for (Map e in devices) {
        String name = e["name"];
        if (name.toLowerCase().startsWith(text)) names.add(name);
      }
    } else {
      for (Map e in contacts) {
        String username = e["username"];
        String email = e["email"];
        if (username.toLowerCase().startsWith(text) &&
            e["status"] == "approved") names.add(username);
        if (email.toLowerCase().startsWith(text) && e["status"] == "approved")
          names.add(email);
      }
    }
    names = names.sublist(0, min(5, names.length));

    return Container(
      child: (names.isNotEmpty)
          ? Column(
              children: names.map(
              (e) {
                return autocompleteButton(e, names.indexOf(e), () {
                  callback(e);
                });
              },
            ).toList())
          : Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "No ${(device) ? 'devices' : 'users'} available",
                style: TextStyle(fontFamily: primaryFont),
              ),
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

  Future<List<String>> getDeviceInfo() async {
    List<String> data = [];
    var dInfo = DeviceInfoPlugin();
    if (Platform.isWindows) {
      var info = await dInfo.windowsInfo;
      data = [info.deviceId, info.computerName, "windows"];
    }
    setState(() {
      deviceInfo = data;
    });
    return data;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserId();
    getDeviceInfo();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (!login)
      return Scaffold(
          body: Center(
              child: LoadingAnimationWidget.inkDrop(
                  color: Colors.blue, size: 100)));
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
      body: TabBarView(
          controller: controller,
          children: [devicesPage(), contactsPage(), Container()]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) {
                    bool device = true;
                    String textError = "";
                    bool generate = true;
                    String recipientName = "";

                    Map files = {};
                    String fileError = "";

                    TextEditingController controller = TextEditingController();
                    return StatefulBuilder(
                        builder: (stateContext, setDialogState) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: Text(
                                "Send file",
                                style: TextStyle(fontFamily: primaryFont),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        recipientButton("Device", device, () {
                                          setDialogState(() {
                                            device = !device;
                                            generate = true;
                                            textError = "";
                                            fileError = "";
                                          });
                                        }),
                                        recipientButton("User", !device, () {
                                          setDialogState(() {
                                            device = !device;
                                            generate = true;
                                            textError = "";
                                            fileError = "";
                                          });
                                        }),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            labelText: "Recipient",
                                            hintText: "Recipient",
                                            errorText:
                                                (textError.isEmpty) ? null : textError,
                                            errorStyle: TextStyle(
                                                fontFamily: primaryFont),
                                            border: OutlineInputBorder(),
                                          ),
                                          style: TextStyle(
                                              fontFamily: primaryFont),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              textError = "";
                                              fileError = "";
                                              recipientName = value;
                                            });
                                          },
                                        ),
                                        (recipientName.isNotEmpty)
                                            ? generateAutocomplete(
                                                generate,
                                                recipientName,
                                                device,
                                                (text) => setDialogState(() {
                                                      controller.text = text;
                                                      generate = false;
                                                      recipientName = text;
                                                    }))
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: TextButton(
                                      onPressed: () async {
                                        setDialogState(() {fileError = "";});

                                        FilePickerResult? result =
                                            await FilePicker.platform
                                                .pickFiles(withData: true, allowMultiple: true);
                                    
                                        if (result != null) {
                                          for (var f in result.files) {
                                            if (files.length < 5) {
                                              files[f.name] = f.bytes;
                                            }
                                            else {
                                              setDialogState(() {fileError = "You can send a maximum of 5 documents at a time";}); 
                                              break;
                                            }
                                          }
                                          setDialogState(() {
                                            files = files;
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          "Pick a file",
                                          style: TextStyle(
                                              fontFamily: primaryFont),
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  Colors.blue),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                                  Colors.white)),
                                    ),
                                  ),
                                  (Platform.isAndroid || Platform.isIOS) ? Padding(
                                    padding: EdgeInsets.all(10),
                                    child: TextButton(
                                      onPressed: () async {
                                        setDialogState(() {fileError = "";});
                                        
                                        ImagePicker picker = ImagePicker();
                                        List<XFile> media = await picker.pickMultiImage();
                                    
                                        if (media.isNotEmpty) {
                                          for (var f in media) {
                                            if (files.length < 5) {
                                              files[f.name] = await f.readAsBytes();
                                            }
                                            else {
                                              setDialogState(() {fileError = "You can send a maximum of 5 documents at a time";}); 
                                              break;
                                            }
                                          }
                                          setDialogState(() {
                                            files = files;
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          "Pick an image",
                                          style: TextStyle(
                                              fontFamily: primaryFont),
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  Colors.blue),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                                  Colors.white)),
                                    ),
                                  ) : Container(),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: files.keys
                                          .map((file) => Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    file,
                                                    style: TextStyle(
                                                        fontFamily:
                                                            primaryFont),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        setDialogState(() =>
                                                            files.remove(file)),
                                                    icon: Icon(Icons.close),
                                                    splashRadius: 20,
                                                  )
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  (fileError.isNotEmpty) ? Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(fileError, style: TextStyle(fontFamily: primaryFont, color: Colors.red),),
                                  ) : Container()
                                ],
                              ),
                              actions: [
                                TextButton.icon(
                                  onPressed: () async {
                                    bool flag = false;
                                    int? device_id;

                                    if (device) {
                                      for (Map x in devices) {
                                        if (x["name"] == recipientName) {
                                          device_id = x["device_id"];
                                          flag = true;
                                          break;
                                        }
                                      }
                                    } else {
                                      for (Map x in contacts) {
                                        if (x["username"] == recipientName ||
                                            x["email"] == recipientName) {
                                          flag = true;
                                          break;
                                        }
                                      }
                                    }

                                    if (!flag) {
                                      setDialogState(() {
                                        textError = "This ${(device) ? 'device' : 'user'} does not exist";
                                        fileError = "";
                                      });
                                      return;
                                    }

                                    if (files.isEmpty) {
                                      setDialogState(() {
                                        textError = "";
                                        fileError = "No files have been uploaded";
                                      });
                                      return;
                                    }

                                    
                                  },
                                  label: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      "Send",
                                      style: TextStyle(fontFamily: primaryFont),
                                    ),
                                  ),
                                  icon: Icon(Icons.send),
                                  iconAlignment: IconAlignment.end,
                                  style: ButtonStyle(
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      backgroundColor:
                                          WidgetStatePropertyAll(Colors.blue),
                                      foregroundColor:
                                          WidgetStatePropertyAll(Colors.white)),
                                ),
                              ],
                              actionsAlignment: MainAxisAlignment.center,
                            ));
                  });
            },
            icon: Icon(Icons.upload)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
