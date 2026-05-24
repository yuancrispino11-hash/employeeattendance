import 'package:employeeattendance/loa_page.dart';
import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_page.dart';

class HomePage extends StatefulWidget {
  final String employeeId;

  const HomePage({
    super.key,
    required this.employeeId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference attendance =
  FirebaseFirestore.instance.collection('attendance');

  bool isLoading = false;
  int currentIndex = 0;

  Stream<DocumentSnapshot> get userStream => FirebaseFirestore.instance
      .collection('employees')
      .doc(widget.employeeId)
      .snapshots();

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });

    switch (index) {
      case 0:
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

  String get todayId {
    DateTime now = DateTime.now();
    return "${widget.employeeId}_${now.year}-${now.month}-${now.day}";
  }

  String getStatus(DateTime? timeIn) {
    if (timeIn == null) return "Absent";

    DateTime cutoff = DateTime(
      timeIn.year,
      timeIn.month,
      timeIn.day,
      8,
      0,
    );

    return timeIn.isAfter(cutoff) ? "Late" : "Present";
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

  String calculateHours(Timestamp? timeIn, Timestamp? timeOut) {
    if (timeIn == null) return "No Time In";

    DateTime start = timeIn.toDate();
    DateTime end = timeOut != null ? timeOut.toDate() : DateTime.now();
    Duration diff = end.difference(start);

    int totalMinutes = diff.inMinutes;
    int regularMinutes = totalMinutes > 480 ? 480 : totalMinutes;
    int otMinutes = totalMinutes > 480 ? totalMinutes - 480 : 0;
    int regH = regularMinutes ~/ 60;
    int regM = regularMinutes % 60;
    int otH = otMinutes ~/ 60;
    int otM = otMinutes % 60;

    return otMinutes > 0
        ? "${regH}h ${regM}m + OT: ${otH}h ${otM}m"
        : "${regH}h ${regM}m";
  }

  Future<Map<String, dynamic>> getUserData() async {
    var doc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(widget.employeeId)
        .get();

    return doc.data() as Map<String, dynamic>;
  }

  void timeIn(Map<String, dynamic> userData) async {
    setState(() => isLoading = true);

    try {
      DocumentSnapshot doc = await attendance.doc(todayId).get();

      if (doc.exists &&
          (doc.data() as Map<String, dynamic>)['time_in'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already timed in today")),
        );
        return;
      }

      await attendance.doc(todayId).set({
        'employee_id': widget.employeeId,
        'name': userData['name'],
        'time_in': Timestamp.now(),
        'time_out': null,
        'date': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Time In Successful")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void timeOut() async {
    setState(() => isLoading = true);

    try {
      DocumentSnapshot doc = await attendance.doc(todayId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Time In record yet")),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      if (data['time_out'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already timed out")),
        );
        return;
      }

      await attendance.doc(todayId).update({
        'time_out': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Time Out Successful")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        title: Text("Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
            child: StreamBuilder<DocumentSnapshot>(
              stream: userStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("Loading...",
                    style: TextStyle(color: Colors.white),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome, ${data['name'] ?? 'Unknown'}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text("Employee ID: ${widget.employeeId}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 15),
          Text("Today's Date: ${formatDate(DateTime.now())}",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 15),

          FutureBuilder<Map<String, dynamic>>(
            future: getUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              final userData = snapshot.data!;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => timeIn(userData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text("TIME IN",
                            style: TextStyle(color: Colors.white)
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : timeOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                        ),
                        child: Text("TIME OUT",
                            style: TextStyle(color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20),

          Text("Today's Attendance",
            style: TextStyle(color: Colors.white),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: attendance.doc(todayId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text("No attendance today",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                DateTime? inTime = data['time_in'] != null
                    ? (data['time_in'] as Timestamp).toDate() : null;

                DateTime? outTime = data['time_out'] != null
                    ? (data['time_out'] as Timestamp).toDate() : null;

                return ListView(
                  padding: EdgeInsets.all(12),
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Employee ID: ${widget.employeeId}"),
                          Text("Status: ${getStatus(inTime)}"),
                          Text("Time In: ${inTime != null ? formatDate(inTime) : 'Not set'}",
                          ),
                          Text("Time Out: ${outTime != null ? formatDate(outTime) : 'Not yet'}",
                          ),
                          Text("Hours: ${calculateHours(data['time_in'], data['time_out'])}",
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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