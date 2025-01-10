import "dart:convert";

import "package:file_share/services/secure_storage.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart";

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late int user_id;

  List contacts = [];

  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;

  String baseUrl = "http://127.0.0.1:8000/file_share";

  Future<void> getContacts() async {
    var response = await post(Uri.parse(baseUrl + "/get-contacts/"),
        body: {"user_id": user_id.toString()});

    var info = jsonDecode(response.body)["data"];

    setState(() {
      contacts = info;
    });
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

  Future<void> loadUserId() async {
    String? num = await SecureStorage.read("user_id");
    setState(() {
      user_id = int.parse(num!);
    });
    await getContacts();
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
                          obscureText: true,
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
}
