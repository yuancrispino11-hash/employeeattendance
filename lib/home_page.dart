import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/utils/app_theme.dart';
import 'package:employeeattendance/utils/attendance_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  final String employeeId;
  final String role;

  const HomePage({
    super.key,
    required this.employeeId,
    required this.role,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference attendance =
      FirebaseFirestore.instance.collection('attendance');

  bool isLoading = false;
  AttendanceConfig _config = const AttendanceConfig();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AttendanceConfig.loadFromFirestore();
    if (mounted) setState(() => _config = config);
  }

  String get todayId => attendanceDocId(widget.employeeId);

  Stream<DocumentSnapshot> get userStream => FirebaseFirestore.instance
      .collection('employees')
      .doc(widget.employeeId)
      .snapshots();

  Stream<DocumentSnapshot> get todayAttendanceStream =>
      attendance.doc(todayId).snapshots();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> timeIn() async {
    setState(() => isLoading = true);

    try {
      final doc = await attendance.doc(todayId).get();
      final data = doc.data() as Map<String, dynamic>?;

      if (doc.exists && data != null && data['time_in'] != null) {
        _showMessage('Already timed in today');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employeeId)
          .get();
      final userData = userDoc.data() ?? {};
      final now = Timestamp.now();

      await attendance.doc(todayId).set({
        'employee_id': widget.employeeId,
        'name': userData['name'] ?? 'Unknown',
        'department': userData['department'],
        'time_in': now,
        'time_out': null,
        'date': now,
        'created_at': now,
        'updated_at': now,
      });

      _showMessage('Time In Successful');
    } catch (e) {
      _showMessage('Time in failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> timeOut() async {
    setState(() => isLoading = true);

    try {
      final doc = await attendance.doc(todayId).get();

      if (!doc.exists) {
        _showMessage('No Time In record yet');
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data['time_out'] != null) {
        _showMessage('Already timed out');
        return;
      }

      await attendance.doc(todayId).update({
        'time_out': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      _showMessage('Time Out Successful');
    } catch (e) {
      _showMessage('Time out failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _attendanceCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _attendanceRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
              label,
              style: TextStyle(
                  color: Colors.white70,
              )
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        title: Text('Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: userStream,
              builder: (context, snapshot) {
                String name = 'Loading...';
                if (snapshot.hasData) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  name = data?['name']?.toString() ?? 'Employee';
                }

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.home_rounded, color: Colors.white, size: 28,
                        ),
                      ),
                      SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('ID: ${widget.employeeId}',
                              style: TextStyle(
                                  color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today: ${formatDateTime(DateTime.now())}",
                    style: TextStyle(
                        color: Colors.white,
                    ),
                  ),
                  Text('Late after ${_config.lateHour}:${_config.lateMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : timeIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text('TIME IN',
                        style: TextStyle(
                            color: Colors.white,
                        ),
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
                      child: Text('TIME OUT',
                        style: TextStyle(
                            color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: StreamBuilder<DocumentSnapshot>(
                stream: todayAttendanceStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _attendanceCard(
                      children: [
                        Text('No attendance record for today',
                          style: TextStyle(
                              color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Tap TIME IN to start',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final timeInTs = data['time_in'] as Timestamp?;
                  final timeOutTs = data['time_out'] as Timestamp?;
                  final timeInDate = timeInTs?.toDate();
                  final status = getDailyStatus(timeInDate, config: _config);
                  final color = statusColor(status);

                  return _attendanceCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Attendance",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _attendanceRow(
                        'Time In',
                        timeInTs != null ? formatDateTime(timeInTs.toDate()) : '—',
                      ),
                      SizedBox(height: 8),
                      _attendanceRow(
                        'Time Out',
                        timeOutTs != null ? formatDateTime(timeOutTs.toDate()) : 'Not yet',
                      ),
                      SizedBox(height: 8),
                      _attendanceRow(
                        'Hours Worked',
                        calculateHours(
                          timeInTs,
                          timeOutTs,
                          standardMinutes: _config.standardWorkMinutes,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
