import 'package:employeeattendance/loa_page.dart';
import 'package:employeeattendance/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'login_page.dart';

class ReportPage extends StatefulWidget {
  final String employeeId;

  const ReportPage({
    super.key,
    required this.employeeId,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime? selectedDate;
  int currentIndex = 1;

  final CollectionReference attendance = FirebaseFirestore.instance.collection('attendance');

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });

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

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  bool isSameDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();

    if (selectedDate == null) return true;

    return date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;
  }

  String formatDate(DateTime date) {
    int hour = date.hour;
    String ampm = "AM";

    if (hour >= 12) {
      ampm = "PM";
      if (hour > 12) hour -= 12;
    }

    if (hour == 0) hour = 12;

    String minute = date.minute.toString().padLeft(2, '0');

    return "${date.month}/${date.day}/${date.year} - $hour:$minute $ampm";
  }

  String getStatus(Map<String, dynamic> data) {
    if (data['time_in'] == null) return "ABSENT";

    DateTime timeIn = (data['time_in'] as Timestamp).toDate();
    DateTime? timeOut =
    data['time_out'] != null ? (data['time_out'] as Timestamp).toDate() : null;
    DateTime cutoff = DateTime(timeIn.year, timeIn.month, timeIn.day, 8, 0);

    bool isLate = timeIn.isAfter(cutoff);

    int totalMinutes =
    timeOut != null ? timeOut.difference(timeIn).inMinutes : 0;

    bool isUndertime = timeOut != null && totalMinutes < 480;

    if (timeOut == null) {
      return isLate ? "LATE (INCOMPLETE)" : "PRESENT (INCOMPLETE)";
    }

    if (isUndertime) return "UNDERTIME";
    if (isLate) return "LATE";

    return "PRESENT";
  }

  Color getStatusColor(String status) {
    if (status.contains("PRESENT")) return Colors.green;
    if (status.contains("LATE")) return Colors.orange;
    if (status.contains("UNDERTIME")) return Colors.amber;
    if (status.contains("ABSENT")) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        title: Text("Attendance History",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: pickDate,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: attendance
            .where('employee_id', isEqualTo: widget.employeeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          var filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['date'] != null && isSameDate(data['date']);
          }).toList();

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
                    Text("Attendance History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(selectedDate == null
                          ? "Showing: ALL RECORDS"
                          : "Showing: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text("No attendance found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {

                    final data = filtered[index].data() as Map<String, dynamic>;

                    String status = getStatus(data);

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Employee ID: ${data['employee_id']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("Time In: ${data['time_in'] != null ? formatDate((data['time_in'] as Timestamp).toDate()) : 'Not set'}",
                          ),
                          Text("Time Out: ${data['time_out'] != null ? formatDate((data['time_out'] as Timestamp).toDate()) : 'Not yet'}",
                          ),
                          SizedBox(height: 8),
                          Text("Status: $status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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