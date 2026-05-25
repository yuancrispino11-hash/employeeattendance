import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employeeattendance/utils/attendance_utils.dart';
import 'package:flutter/material.dart';

class AdminEmployeeAttendancePage extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const AdminEmployeeAttendancePage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(employeeName,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('employee_id', isEqualTo: employeeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aDate =
                  (a.data() as Map<String, dynamic>)['date'] as Timestamp?;
              final bDate =
                  (b.data() as Map<String, dynamic>)['date'] as Timestamp?;
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });

          if (docs.isEmpty) {
            return Center(
              child: Text('No attendance records',
                style: TextStyle(
                    color: Colors.white70,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = getReportStatus(data);
              final color = statusColor(status);
              final timeIn = data['time_in'] as Timestamp?;
              final timeOut = data['time_out'] as Timestamp?;

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatRecordDate(data['date'] as Timestamp?),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('In: ${timeIn != null ? formatDateTime(timeIn.toDate()) : '—'}',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                      ),
                    ),
                    Text('Out: ${timeOut != null ? formatDateTime(timeOut.toDate()) : '—'}',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                      ),
                    ),
                    Text('Hours: ${calculateHours(timeIn, timeOut)}',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
