import "package:file_share/widgets/logout_button.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String? primaryFont = GoogleFonts.redHatDisplay().fontFamily;
  late TabController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Home",
            style: TextStyle(fontFamily: primaryFont)
          ),
          centerTitle: true,
          actions: [LogoutButton()],
          bottom: TabBar(
            controller: controller,
            tabs: [
              Tab(child: Text("Devices", style: TextStyle(fontFamily: primaryFont),)),
              Tab(child: Text("Contacts", style: TextStyle(fontFamily: primaryFont),)),
              Tab(child: Text("Documents", style: TextStyle(fontFamily: primaryFont),)),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller,
          children: []
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: IconButton(onPressed: () {}, icon: Icon(Icons.upload)),),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}