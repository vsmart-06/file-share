import "dart:convert";
import "dart:io";
import "dart:math";
import "package:archive/archive_io.dart";
import "package:file_share/services/device_info.dart";
import "package:file_share/services/secure_storage.dart";
import "package:file_share/widgets/logout_button.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:http/http.dart";
import "package:file_picker/file_picker.dart";
import "package:image_picker/image_picker.dart";
import "package:gal/gal.dart";
import "package:archive/archive.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late int user_id;
  bool login = false;

  List? devices;
  List? contacts;
  List? documents;
  bool gettingDevices = false;
  bool gettingContacts = false;
  bool gettingDocuments = false;
  List<String> deviceInfo = [];

  bool deviceChange = false;
  bool contactChange = false;
  bool documentChange = false;

  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;
  late TabController controller;
  int navigationBarIndex = 0;

  String baseUrl = "https://file-share-weld.vercel.app/file_share";

  Future<void> getDevices([bool pulled = false]) async {
    if (!pulled) setState(() {
      gettingDevices = true;
    });

    var response = await post(Uri.parse(baseUrl + "/get-devices/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      devices = info;
      gettingDevices = false;
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
          renameFunction("The new name is too short");
          return;
        }
        renameFunction();
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
    if (platform != "ios" && platform != "macos") platform = platform[0].toUpperCase() + platform.substring(1);
    else platform = platform.replaceAll("os", "OS");
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon((platform == "iOS")
                ? Icons.phone_iphone_outlined
                : (platform == "Android")
                    ? Icons.phone_android_outlined
                    : (platform == "macOS")
                        ? Icons.laptop_mac_outlined
                        : (platform == "Windows") ? Icons.desktop_windows_outlined : Icons.laptop),
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
                          bool acted = false;
                          return StatefulBuilder(
                            builder: (stateContext, setDialogState) =>
                                AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: Text(
                                (!rename) ? "Device" : "New Device",
                                style: TextStyle(fontFamily: primaryFont),
                              ),
                              content: SingleChildScrollView(
                                child: (!rename)
                                    ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text("Name: ${name}\nPlatform: ${platform}",
                                              style: TextStyle(fontFamily: primaryFont)),
                                        ),
                                        (acted) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container(),
                                      ],
                                    )
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
                                          (acted) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container(),
                                        ],
                                      ),
                              ),
                              actions: (acted) ? [] : (!rename)
                                  ? (identifier != deviceInfo[0])
                                      ? [
                                          deviceAction(
                                              "Remove",
                                              device_id,
                                              deviceInfo[1],
                                              dialogContext,
                                              () {setDialogState(() {acted = true;});}),
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
                                          newName, dialogContext, ([e = ""]) {
                                        setDialogState(() {
                                          error = e;
                                          rename = true;
                                          acted = e.isEmpty;
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
                    child: (MediaQuery.of(context).orientation == Orientation.landscape) ? Row(
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
                    ) : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
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
    if (devices == null)
      return Center(
          child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100));
    return RefreshIndicator(
      onRefresh: () async {await getDevices(true);},
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: devices!
                .map(
                  (e) => deviceCard(
                      e["device_id"], e["identifier"], e["name"], e["platform"]),
                )
                .toList() + [(gettingDevices) ? Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100),
                          ) : Container()],
          ),
        ),
      ),
    );
  }

  Future<void> getContacts([bool pulled = false]) async {
    if (!pulled) setState(() {
      gettingContacts = true;
    });

    var response = await post(Uri.parse(baseUrl + "/get-contacts/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      contacts = info;
      gettingContacts = false;
    });
  }

  Widget contactAction(
      String action, String username, BuildContext dialogContext, Function callback) {
    return TextButton.icon(
      onPressed: () async {
        callback();
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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
                          bool acted = false;

                          return StatefulBuilder(
                            builder: (stateContext, setDialogState) => AlertDialog(
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
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                          "Username: ${username}\nEmail: ${email}",
                                          style: TextStyle(fontFamily: primaryFont)),
                                    ),
                                    (acted) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container(),
                                  ],
                                ),
                              ),
                              actions: (acted) ? [] : (status == "incoming")
                                  ? [
                                      contactAction(
                                          "Accept", username, dialogContext, () => setDialogState(() {acted = true;})),
                                      contactAction(
                                          "Decline", username, dialogContext, () => setDialogState(() {acted = true;}))
                                    ]
                                  : (status == "outgoing")
                                      ? [
                                          contactAction(
                                              "Withdraw", username, dialogContext, () => setDialogState(() {acted = true;}))
                                        ]
                                      : [
                                          contactAction(
                                              "Delete", username, dialogContext, () => setDialogState(() {acted = true;}))
                                        ],
                              actionsAlignment: MainAxisAlignment.center,
                            ),
                          );
                        }).then((value) async {
                      if (contactChange) await getContacts();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: (MediaQuery.of(context).orientation == Orientation.landscape) ? Row(
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
                    ) : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
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
    if (contacts == null)
      return Center(
          child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100));
    return RefreshIndicator(
      onRefresh: () async {await getContacts(true);},
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight),
          child: Column(
            children: [
              (contacts!.isEmpty)
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        "You have no contacts",
                        style: TextStyle(fontFamily: primaryFont, fontSize: 20),
                      ),
                    ))
                  : Column(
                      children: contacts!
                          .map((e) =>
                              contactCard(e["username"], e["email"], e["status"]))
                          .toList(),
                    ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      contactChange = false;
                    });
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          String user = "";
                          String error = "";
                
                          bool sendingContact = false;
                
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
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
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
                                                  error = "";
                                                });
                                              },
                                            ),
                                          ),
                                          (sendingContact) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container()
                                        ],
                                      ),
                                    ),
                                    actions: (sendingContact) ? [] : [
                                      TextButton.icon(
                                        onPressed: () async {
                                          if (user.isEmpty) {
                                            setDialogState(() {
                                              error =
                                                  "Username/Email cannot be empty";
                                            });
                                            return;
                                          }
                
                                          setDialogState(() {sendingContact = true;});
                
                                          var response = await post(
                                              Uri.parse(baseUrl + "/add-contact/"),
                                              body: {
                                                "user_id": user_id.toString(),
                                                "second": user
                                              });
                
                                          var info = jsonDecode(response.body);
                
                                          setDialogState(() {sendingContact = false;});
                
                                          if (response.statusCode == 400) {
                                            setDialogState(() {
                                              error = info["error"];
                                            });
                                            return;
                                          }
                                          Navigator.of(dialogContext).pop();
                                          setState(() {
                                            contactChange = true;
                                          });
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
                        }).then((value) async {if (contactChange) await getContacts();});
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
              ),
              (gettingContacts) ? Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100),
                          ) : Container()
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getDocuments([bool pulled = false]) async {
    if (!pulled) setState(() {
      gettingDocuments = true;
    });

    var response = await post(Uri.parse(baseUrl + "/get-documents/"),
        body: {"user_id": user_id.toString(), "identifier": deviceInfo[0]});

    List info = jsonDecode(response.body)["data"];

    info = info.map((e) {
      var files = ZipDecoder().decodeBytes(base64Decode(e["documents"]));
      List unzipped = [];
      for (var file in files) {
        if (file.isFile) {
          unzipped.add({"name": file.name, "bytes": base64Encode(file.readBytes()!.toList())});
        }
      }
      e["documents"] = unzipped;
      return e;
    }).toList();
    

    setState(() {
      documents = info;
      gettingDocuments = false;
    });
  }

  Widget documentAction(
      String action, int document_id, BuildContext dialogContext, Function callback) {
    return TextButton.icon(
      onPressed: () async {
        callback();
        if (action == "Close") {
          await post(Uri.parse(baseUrl + "/open-document/"),
              body: {"document_id": document_id.toString()});
          Navigator.of(dialogContext).pop();
          return;
        }
        await post(Uri.parse(baseUrl + "/delete-document/"),
            body: {"document_id": document_id.toString()});
        Navigator.of(dialogContext).pop();
        setState(() {
          documentChange = true;
        });
      },
      label: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          action,
          style: TextStyle(fontFamily: primaryFont),
        ),
      ),
      icon: Icon((action == "Close")
          ? Icons.close
          : (action == "Delete")
              ? Icons.delete
              : Icons.undo),
      style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: WidgetStatePropertyAll((action == "Close")
              ? Colors.blue
              : (action == "Delete")
                  ? Colors.red
                  : Colors.grey[600]),
          foregroundColor: WidgetStatePropertyAll(Colors.white)),
    );
  }

  Widget documentCard(int document_id, String status, String name,
      bool is_device, List documents, List texts, String time) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              (status == "outgoing") ? Icons.north_east : Icons.south_west,
              color: Colors.green,
            ),
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
                      documentChange = false;
                    });
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          bool acted = false;
                          String downloaded = "";
                          String copied = "";
                          List downloadFiles = [];

                          return StatefulBuilder(
                            builder: (stateContext, setDialogState) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: Text(
                                "Shared ${status == 'incoming' ? 'by' : 'to'} ${name}",
                                style: TextStyle(fontFamily: primaryFont),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
                                      child: Text(
                                          "Username: ${name}\n\nTime: ${DateTime.parse(time).toLocal()}",
                                          style: TextStyle(fontFamily: primaryFont)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: documents
                                            .map((file) => Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      file["name"],
                                                      style: TextStyle(
                                                          fontFamily: primaryFont),
                                                    ),
                                                    IconButton(
                                                      tooltip: "Download",
                                                      onPressed: () async {
                                                        String name = file["name"];
                                      
                                                        var bytes =
                                                            base64Decode(file["bytes"]);
                                      
                                                        if (["png", "jpg", "jpeg", "mov", "mpg", "mpeg"].contains(name.split(".")[name.split(".").length-1]) && (Platform.isIOS || Platform.isAndroid)) {
                                                          await Gal.putImageBytes(bytes);
                                                          setDialogState(() {downloaded = name; downloadFiles.add(name);});
                                                          return;
                                                        }
                                      
                                                        String? path = await FilePicker
                                                            .platform
                                                            .saveFile(
                                                                dialogTitle: "Save File",
                                                                fileName: name,
                                                                bytes: bytes,
                                                                lockParentWindow: true);
                                                                  
                                                        if (path != null && (!Platform.isIOS && !Platform.isAndroid)) {
                                                          XFile f = XFile.fromData(bytes);
                                                          f.saveTo(path);
                                                        }
                                      
                                                        if (path != null) setDialogState(() {downloaded = name; downloadFiles.add(name);});
                                                      },
                                                      icon: Icon((downloadFiles.contains(file["name"])) ? Icons.check : Icons.download, color: (downloadFiles.contains(file["name"])) ? Colors.green : Colors.black,),
                                                      splashRadius: 20,
                                                    )
                                                  ],
                                                ))
                                            .toList() + texts.map((text) => Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    SelectableText(
                                                      text,
                                                      style: TextStyle(
                                                          fontFamily: primaryFont),
                                                    ),
                                                    IconButton(
                                                      tooltip: "Copy",
                                                      onPressed: () async {
                                                        await Clipboard.setData(ClipboardData(text: text));
                                                        setDialogState(() {
                                                          copied = text;
                                                        });
                                                      },
                                                      icon: Icon((copied == text) ? Icons.check : Icons.copy_rounded, color: (copied == text) ? Colors.green : Colors.black,),
                                                      splashRadius: 20,
                                                    )
                                                  ],
                                                )).toList()
                                      ),
                                    ),
                                    (acted) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container(),

                                    (downloaded.isNotEmpty) ? Padding(padding: EdgeInsets.all(10), child: Text(downloaded + " was downloaded successfully", style: TextStyle(fontFamily: primaryFont),),) : Container()
                                  ],
                                ),
                              ),
                              actions: (acted) ? [] : (status == "incoming")
                                  ? [
                                      documentAction(
                                          "Close", document_id, dialogContext, () => setDialogState(() {acted = true; downloaded = "";})),
                                      documentAction(
                                          "Delete", document_id, dialogContext, () => setDialogState(() {acted = true; downloaded = "";}))
                                    ]
                                  : [
                                      documentAction(
                                          "Withdraw", document_id, dialogContext, () => setDialogState(() {acted = true; downloaded = "";}))
                                    ],
                              actionsAlignment: MainAxisAlignment.center,
                            ),
                          );
                        }).then((value) async {
                      if (documentChange)
                        await getDocuments();
                      else if (status == "incoming")
                        await post(Uri.parse(baseUrl + "/open-document/"),
                            body: {"document_id": document_id.toString()});
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: (MediaQuery.of(context).orientation == Orientation.landscape) ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "${(is_device) ? 'Device' : 'Username'}: ${name}",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: primaryFont,
                          ),
                        ),
                        Text((texts.length * documents.length != 0) ? ("${documents.length} document${(documents.length > 1) ? 's' : ''} and ${texts.length} text${(texts.length > 1) ? 's' : ''}") : (texts.length == 0) ? ("${documents.length} document${(documents.length > 1) ? 's' : ''}") : ("${texts.length} text${(texts.length > 1) ? 's' : ''}"),
                            style: TextStyle(
                                color: Colors.black, fontFamily: primaryFont)),
                      ],
                    ) : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(is_device) ? 'Device' : 'Username'}: ${name}",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: primaryFont,
                          ),
                        ),
                        Text((texts.length * documents.length != 0) ? ("${documents.length} document${(documents.length > 1) ? 's' : ''} and ${texts.length} text${(texts.length > 1) ? 's' : ''}") : (texts.length == 0) ? ("${documents.length} document${(documents.length > 1) ? 's' : ''}") : ("${texts.length} text${(texts.length > 1) ? 's' : ''}"),
                            style: TextStyle(
                                color: Colors.black, fontFamily: primaryFont)),
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

  Widget documentsPage() {
    if (documents == null || (documents!.isEmpty && gettingDocuments))
      return Center(
          child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100));
    return RefreshIndicator(
      onRefresh: () async {await getDocuments(true);},
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight),
          child: (documents!.isEmpty)
              ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          "You have no documents",
                          style: TextStyle(fontFamily: primaryFont, fontSize: 20),
                                      ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: documents!
                    .map(
                      (e) => documentCard(e["document_id"], e["status"],
                          e["second"], e["is_device"], (e["documents"] == null) ? [] : e["documents"], (e["texts"] == null) ? [] : e["texts"], e["time"]),
                    )
                    .toList() + [(gettingDocuments) ? Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: LoadingAnimationWidget.inkDrop(color: Colors.blue, size: 100),
                    ) : Container()],
              ),
        ),
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
        (index == 0)
            ? Divider(
                thickness: 1,
                color: Colors.black,
              )
            : Container(),
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
      for (Map e in devices!) {
        String name = e["name"];
        if (name.toLowerCase().startsWith(text) &&
            (e["identifier"] != deviceInfo[0])) names.add(name);
      }
    } else {
      for (Map e in contacts!) {
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
      DeviceInfo.getDeviceInfo();
      String? num = await SecureStorage.read("user_id");
      setState(() {
        user_id = int.parse(num!);
        login = true;
        deviceInfo = DeviceInfo.data;
      });
      getDevices();
      getContacts();
      getDocuments();
    } else {
      await SecureStorage.delete();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => route == "/");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserId();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(() => setState(() {navigationBarIndex = controller.index;}));
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
        actions: [IconButton(tooltip: "Reload", splashRadius: 20, onPressed: () {getDevices(); getContacts(); getDocuments();}, icon: Icon(Icons.refresh)), LogoutButton()],
        bottom: (MediaQuery.of(context).orientation == Orientation.landscape) ? TabBar(
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
        ) : null,
      ),
      body: TabBarView(
          controller: controller,
          children: [devicesPage(), contactsPage(), documentsPage()]),
      floatingActionButton: FloatingActionButton(
          tooltip: "Share a document",
          onPressed: () {
            setState(() {
              documentChange = false;
            });
            showDialog(
                context: context,
                builder: (dialogContext) {
                  bool device = true;
                  String textError = "";
                  bool generate = true;
                  String recipientName = "";
    
                  String currentText = "";
                  bool addText = false;
                  List<String> texts = [];
                  bool duplicateText = false;

                  Map files = {};
                  String uploadError = "";
    
                  bool sendingDocuments = false;
    
                  TextEditingController recipientController = TextEditingController();
                  TextEditingController textController = TextEditingController();
                  return StatefulBuilder(
                      builder: (stateContext, setDialogState) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            title: Text(
                              "Send file",
                              style: TextStyle(fontFamily: primaryFont),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        recipientButton("Device", device, () {
                                          setDialogState(() {
                                            device = !device;
                                            generate = true;
                                            textError = "";
                                            uploadError = "";
                                          });
                                        }),
                                        recipientButton("User", !device, () {
                                          setDialogState(() {
                                            device = !device;
                                            generate = true;
                                            textError = "";
                                            uploadError = "";
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
                                          controller: recipientController,
                                          decoration: InputDecoration(
                                            labelText: "Recipient",
                                            hintText: "Recipient",
                                            errorText: (textError.isEmpty)
                                                ? null
                                                : textError,
                                            errorStyle: TextStyle(
                                                fontFamily: primaryFont),
                                            border: OutlineInputBorder(),
                                          ),
                                          style:
                                              TextStyle(fontFamily: primaryFont),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              textError = "";
                                              uploadError = "";
                                              recipientName = value;
                                              generate = true;
                                            });
                                          },
                                        ),
                                        (recipientName.isNotEmpty)
                                            ? generateAutocomplete(
                                                generate,
                                                recipientName,
                                                device,
                                                (text) => setDialogState(() {
                                                      recipientController.text = text;
                                                      generate = false;
                                                      recipientName = text;
                                                    }))
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                  (addText) ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: textController,
                                            decoration: InputDecoration(
                                              labelText: "Text",
                                              hintText: "Text",
                                              errorText: (duplicateText)
                                                  ? "You have already added this text"
                                                  : null,
                                              errorStyle: TextStyle(
                                                  fontFamily: primaryFont),
                                              border: OutlineInputBorder(),
                                            ),
                                            style:
                                                TextStyle(fontFamily: primaryFont),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                uploadError = "";
                                                currentText = value;
                                                duplicateText = false;
                                              });
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 5),
                                          child: IconButton(onPressed: () {
                                            if (currentText.isNotEmpty) {
                                              if (texts.contains(currentText)) {
                                                setDialogState(() {
                                                  duplicateText = true;
                                                });
                                                return;
                                              }
                                              setDialogState(() {
                                                texts.add(currentText);
                                                textController.clear();
                                                addText = false;
                                                currentText = "";
                                              });
                                            }
                                          }, icon: Icon(Icons.check),
                                          color: Colors.green,
                                          splashRadius: 20,),
                                        )
                                      ],
                                    ),
                                  ) : Container(),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: TextButton(
                                      onPressed: () async {
                                        if (addText) return;
                                        if (texts.length == 5) {
                                          setDialogState(() {
                                            uploadError = "You can send a maximum of 5 texts at a time";
                                          });
                                          return;
                                        }
                                        setDialogState(() {
                                          uploadError = "";
                                          addText = true;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          "Add text",
                                          style:
                                              TextStyle(fontFamily: primaryFont),
                                        ),
                                      ),
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
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: TextButton(
                                      onPressed: () async {
                                        setDialogState(() {
                                          uploadError = "";
                                        });
                              
                                        FilePickerResult? result =
                                            await FilePicker.platform.pickFiles(
                                                withData: true,
                                                allowMultiple: true,
                                                lockParentWindow: true);
                              
                                        if (result != null) {
                                          for (var f in result.files) {
                                            if (files.length < 5) {
                                              files[f.name] = f.bytes;
                                            } else {
                                              setDialogState(() {
                                                uploadError =
                                                    "You can send a maximum of 5 documents at a time";
                                              });
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
                                          style:
                                              TextStyle(fontFamily: primaryFont),
                                        ),
                                      ),
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
                                  ),
                                  (Platform.isAndroid || Platform.isIOS)
                                      ? Padding(
                                          padding: EdgeInsets.all(10),
                                          child: TextButton(
                                            onPressed: () async {
                                              setDialogState(() {
                                                uploadError = "";
                                              });
                              
                                              ImagePicker picker = ImagePicker();
                                              List<XFile> media =
                                                  await picker.pickMultiImage();
                              
                                              if (media.isNotEmpty) {
                                                for (var f in media) {
                                                  if (files.length < 5) {
                                                    files[f.name] =
                                                        await f.readAsBytes();
                                                  } else {
                                                    setDialogState(() {
                                                      uploadError =
                                                          "You can send a maximum of 5 documents at a time";
                                                    });
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
                                        )
                                      : Container(),
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
                                                        fontFamily: primaryFont),
                                                  ),
                                                  IconButton(
                                                    tooltip: "Remove",
                                                    onPressed: (sendingDocuments) ? () {} : () {setDialogState(() => files.remove(file));},
                                                    icon: Icon(Icons.close),
                                                    splashRadius: 20,
                                                  )
                                                ],
                                              ))
                                          .toList() + texts.map(
                                            (text) => Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  SelectableText(
                                                    text,
                                                    style: TextStyle(
                                                        fontFamily: primaryFont),
                                                  ),
                                                  IconButton(
                                                    tooltip: "Remove",
                                                    onPressed: (sendingDocuments) ? () {} : () {setDialogState(() => texts.remove(text));},
                                                    icon: Icon(Icons.close),
                                                    splashRadius: 20,
                                                  )
                                                ],
                                              )
                                          ).toList(),
                                    ),
                                  ),
                                  (uploadError.isNotEmpty)
                                      ? Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            uploadError,
                                            style: TextStyle(
                                                fontFamily: primaryFont,
                                                color: Colors.red),
                                          ),
                                        )
                                      : Container(),
                                  (sendingDocuments) ? Padding(padding: EdgeInsets.all(10), child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 50)) : Container()
                                ],
                              ),
                            ),
                            actions: (sendingDocuments) ? [] : [
                              TextButton.icon(
                                onPressed: () async {
                                  bool flag = false;
                                  int? device_id;
    
                                  if (device) {
                                    for (Map x in devices!) {
                                      if (x["name"] == recipientName) {
                                        device_id = x["device_id"];
                                        flag = true;
                                        break;
                                      }
                                    }
                                  } else {
                                    for (Map x in contacts!) {
                                      if (x["username"] == recipientName ||
                                          x["email"] == recipientName) {
                                        flag = true;
                                        break;
                                      }
                                    }
                                  }
    
                                  if (!flag) {
                                    setDialogState(() {
                                      textError =
                                          "This ${(device) ? 'device' : 'user'} does not exist";
                                      uploadError = "";
                                    });
                                    return;
                                  }
    
                                  if (files.isEmpty && texts.isEmpty) {
                                    setDialogState(() {
                                      textError = "";
                                      uploadError = "No files have been uploaded";
                                    });
                                    return;
                                  }
    
                                  setDialogState(() {sendingDocuments = true;});
    
                                  Archive archive = Archive();
                                  for (String file in files.keys) {
                                    archive.addFile(ArchiveFile(file, files[file].length, files[file]));
                                  }
                                  var zipBytes = ZipEncoder().encode(archive);
    
                                  var request = MultipartRequest("POST",
                                      Uri.parse(baseUrl + "/share-documents/"));
                                  request.files.add(MultipartFile.fromBytes("zipped_file", zipBytes, filename: "zipped_file.zip"));
    
                                  request.fields["user_id"] =
                                      user_id.toString();
                                  request.fields["identifier"] = deviceInfo[0];
                                  if (device_id != null)
                                    request.fields["device_id"] =
                                        device_id.toString();
                                  else
                                    request.fields["username"] = recipientName;

                                  request.fields["texts"] = jsonEncode(texts);

                                  var response = await Response.fromStream(
                                      await request.send());
    
                                  setDialogState(() {sendingDocuments = false;});
    
                                  if (response.statusCode != 200) {
                                    setDialogState(() {
                                      textError = "";
                                      uploadError =
                                          jsonDecode(response.body)["error"];
                                    });
                                  } else {
                                    Navigator.of(dialogContext).pop();
                                    setState(() {
                                      documentChange = true;
                                    });
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
                }).then((value) async {
              if (documentChange) await getDocuments();
            });
          },
          child: Icon(Icons.upload)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: (MediaQuery.of(context).orientation == Orientation.portrait) ? 
      BottomNavigationBar(
        currentIndex: navigationBarIndex,
        enableFeedback: true,
        selectedLabelStyle: TextStyle(fontFamily: primaryFont),
        unselectedLabelStyle: TextStyle(fontFamily: primaryFont),
        onTap: (value) {
          setState(() {
            navigationBarIndex = value;
          });
          controller.animateTo(value);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_rounded),
            label: "Devices"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page_rounded),
            label: "Contacts"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_rounded),
            label: "Documents"
          ),
        ]
      ) : null
    );
  }
}
