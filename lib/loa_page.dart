import 'package:employeeattendance/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'login_page.dart';

class LoaPage extends StatefulWidget {
  final String employeeId;

  const LoaPage({
    super.key,
    required this.employeeId,
  });

  @override
  State<LoaPage> createState() => _LoaPageState();
}

class _LoaPageState extends State<LoaPage> {
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController reasonController = TextEditingController();
  bool isLoading = false;
  final CollectionReference loa = FirebaseFirestore.instance.collection('loa_requests');

  int currentIndex = 2;

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
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
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              employeeId: widget.employeeId,
            ),
          ),
        );
        break;
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    var doc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(widget.employeeId)
        .get();

    return doc.data() as Map<String, dynamic>;
  }

  Future<void> pickStartDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) setState(() => startDate = date);
  }

  Future<void> pickEndDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) setState(() => endDate = date);
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    return "${date.month}/${date.day}/${date.year}";
  }

  Future<void> submitLOA(Map<String, dynamic> userData) async {
    if (startDate == null ||
        endDate == null ||
        reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await loa.add({
        'employee_id': widget.employeeId,
        'name': userData['name'],
        'reason': reasonController.text.trim(),
        'start_date': Timestamp.fromDate(startDate!),
        'end_date': Timestamp.fromDate(endDate!),
        'status': "PENDING",
        'created_at': Timestamp.now(),
      });

      reasonController.clear();
      setState(() {
        startDate = null;
        endDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("LOA Submitted Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        title: Text("LOA", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),

      body: Column(
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
            child: FutureBuilder<Map<String, dynamic>>(
              future: getUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("Loading...",
                    style: TextStyle(color: Colors.white),
                  );
                }

                final data = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Employee: ${data['name']}",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18),
                    ),
                    Text("Employee ID: ${widget.employeeId}",
                      style: TextStyle(
                          color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: getUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final userData = snapshot.data!;

                  return Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickStartDate,
                        icon: Icon(Icons.calendar_today),
                        label: Text("Start Date: ${formatDate(startDate)}"),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: pickEndDate,
                        icon: Icon(Icons.calendar_today),
                        label: Text("End Date: ${formatDate(endDate)}"),
                      ),
                      SizedBox(height: 15),

                      TextField(
                        controller: reasonController,
                        maxLines: 4,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Reason for leave...",
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => submitLOA(userData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                              color: Colors.white)
                              : Text("SUBMIT LOA",
                              style: TextStyle(color: Colors.white)
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: loa
                            .where('employee_id',
                            isEqualTo: widget.employeeId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }

                          var docs = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data()
                              as Map<String, dynamic>;

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text("Reason: ${data['reason']}"),
                                    Text("Status: ${data['status']}"),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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