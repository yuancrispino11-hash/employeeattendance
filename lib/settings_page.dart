import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'loa_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final String employeeId;

  const SettingsPage({
    super.key,
    required this.employeeId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final CollectionReference employees =
  FirebaseFirestore.instance.collection('employees');

  late TextEditingController nameController;
  late TextEditingController passwordController;

  bool isLoading = false;
  int currentIndex = 3;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    passwordController = TextEditingController();

    loadUser();
  }

  Future<void> loadUser() async {
    var doc = await employees.doc(widget.employeeId).get();
    var data = doc.data() as Map<String, dynamic>;

    nameController.text = data['name'] ?? '';
    setState(() {});
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> updateProfile() async {
    setState(() => isLoading = true);

    try {
      await employees.doc(widget.employeeId).update({
        "name": nameController.text.trim(),
        if (passwordController.text.trim().isNotEmpty)
          "password": passwordController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  void onTabChanged(int index) {
    setState(() => currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              employeeId: widget.employeeId,
            ),
          ),
        );
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPage(
              employeeId: widget.employeeId,
            ),
          ),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoaPage(
              employeeId: widget.employeeId,
            ),
          ),
        );
        break;

      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: employees.doc(widget.employeeId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Employee: ${data['name'] ?? ''}",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text("Employee ID: ${widget.employeeId}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 10),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password (optional)",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text("UPDATE PROFILE",
                            style: TextStyle(color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E3A8A),
        currentIndex: currentIndex,
        onTap: onTabChanged,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: "LOA"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}