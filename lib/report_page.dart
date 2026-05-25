import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/utils/attendance_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatefulWidget {
  final String employeeId;
  final String role;

  const ReportPage({
    super.key,
    required this.employeeId,
    required this.role,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime? selectedDate;
  AttendanceConfig _config = const AttendanceConfig();

  final CollectionReference attendance = FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    AttendanceConfig.loadFromFirestore().then((c) {
      if (mounted) setState(() => _config = c);
    });
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

  List<QueryDocumentSnapshot> _sortedByDate(List<QueryDocumentSnapshot> docs) {
    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final aDate = (a.data() as Map<String, dynamic>)['date'] as Timestamp?;
      final bDate = (b.data() as Map<String, dynamic>)['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  Widget _statusChip(String status) {
    final color = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label,
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> data) {
    final status = getReportStatus(data, config: _config);
    final color = statusColor(status);
    final timeIn = data['time_in'] as Timestamp?;
    final timeOut = data['time_out'] as Timestamp?;
    final recordDate = data['date'] as Timestamp?;
    final name = data['name']?.toString() ?? 'Attendance Record';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E3A8A).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRecordDate(recordDate),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(name,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.login_rounded,
                  label: 'Time In',
                  value: timeIn != null
                      ? formatDateTime(timeIn.toDate())
                      : 'Not set',
                ),
                _detailRow(
                  icon: Icons.logout_rounded,
                  label: 'Time Out',
                  value: timeOut != null
                      ? formatDateTime(timeOut.toDate())
                      : 'Not yet',
                ),
                _detailRow(
                  icon: Icons.timer_outlined,
                  label: 'Hours',
                  value: calculateHours(
                    timeIn,
                    timeOut,
                    standardMinutes: _config.standardWorkMinutes,
                  ),
                ),
                Divider(color: Color(0xFF334155), height: 1),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: Colors.white38),
                    SizedBox(width: 6),
                    Text('ID: ${data['employee_id'] ?? widget.employeeId}',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        title: Text("Attendance History",
          style: TextStyle(
              color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Filter by date',
            onPressed: pickDate,
          ),
          if (selectedDate != null)
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: Colors.white),
              tooltip: 'Clear filter',
              onPressed: () => setState(() => selectedDate = null),
            ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
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

          final docs = snapshot.data!.docs;

          final filtered = _sortedByDate(
            docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['date'] == null) return false;
              return isSameDate(data['date']);
            }).toList(),
          );

          final recordCount = filtered.length;

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
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attendance History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            selectedDate == null
                                ? 'All records · $recordCount total'
                                : 'Filtered · $recordCount record${recordCount == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: Colors.white70,
                            ),
                          ),
                          if (selectedDate != null) ...[
                            SizedBox(height: 4),
                            Text('${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            SizedBox(height: 12),
                            Text(
                              selectedDate == null
                                  ? 'No attendance records yet'
                                  : 'No records for this date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              selectedDate == null
                                  ? 'Time in from Home to create records'
                                  : 'Tap the calendar to pick another date',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index].data() as Map<String, dynamic>;
                          return _recordCard(data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}