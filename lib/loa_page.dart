import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/utils/app_theme.dart';
import 'package:employeeattendance/utils/attendance_utils.dart';
import 'package:flutter/material.dart';

class LoaPage extends StatefulWidget {
  final String employeeId;
  final String role;

  const LoaPage({
    super.key,
    required this.employeeId,
    required this.role,
  });

  @override
  State<LoaPage> createState() => _LoaPageState();
}

class _LoaPageState extends State<LoaPage> {
  final CollectionReference loa = FirebaseFirestore.instance.collection('loa_requests');
  final TextEditingController reasonController = TextEditingController();

  String selectedType = 'Sick Leave';
  bool isLoading = false;
  bool isHalfDay = false;
  DateTime? leaveStart;
  DateTime? leaveEnd;

  static const _leaveTypes = ['Sick Leave', 'Vacation Leave', 'Emergency Leave',
  ];

  Stream<DocumentSnapshot> get _userStream => FirebaseFirestore.instance
      .collection('employees')
      .doc(widget.employeeId)
      .snapshots();

  IconData _iconForType(String type) {
    switch (type) {
      case 'Sick Leave':
        return Icons.medical_services_outlined;
      case 'Vacation Leave':
        return Icons.beach_access_outlined;
      case 'Emergency Leave':
        return Icons.warning_amber_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '—';
    final date = timestamp.toDate();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/${day}/${date.year} · $hour:$minute $ampm';
  }

  List<QueryDocumentSnapshot> _sortedDocs(List<QueryDocumentSnapshot> docs) {
    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = aData['date'] as Timestamp?;
      final bDate = bData['date'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  void submitRequest() async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a reason for your leave')),
      );
      return;
    }

    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reason must be at least 10 characters'),
        ),
      );
      return;
    }

    if (leaveStart == null || leaveEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select leave start and end dates')),
      );
      return;
    }

    if (leaveEnd!.isBefore(leaveStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employeeId)
          .get();
      final userData = userDoc.data();
      final now = Timestamp.now();

      await loa.add({
        'employee_id': widget.employeeId,
        'employee_name': userData?['name'] ?? widget.employeeId,
        'department': userData?['department'],
        'type': selectedType,
        'reason': reason,
        'status': 'Pending',
        'is_half_day': isHalfDay,
        'leave_start': Timestamp.fromDate(leaveStart!),
        'leave_end': Timestamp.fromDate(leaveEnd!),
        'date': now,
        'created_at': now,
        'updated_at': now,
      });

      reasonController.clear();
      setState(() {
        isHalfDay = false;
        leaveStart = null;
        leaveEnd = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('LOA request submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

  Future<void> _pickLeaveDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (leaveStart ?? DateTime.now()) : (leaveEnd ?? leaveStart ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          leaveStart = picked;
          if (leaveEnd != null && leaveEnd!.isBefore(picked)) leaveEnd = picked;
        } else {
          leaveEnd = picked;
        }
      });
    }
  }

  Future<void> _cancelRequest(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel request?'),
        content: Text('This pending leave request will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await loa.doc(docId).update({
        'status': 'Cancelled',
        'updated_at': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel failed: $e')),
        );
      }
    }
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'New Request',
            subtitle: 'Submit a leave request for admin approval',
          ),
          DropdownButtonFormField<String>(
            value: selectedType,
            dropdownColor: Color(0xFF1E293B),
            style: TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration(
              label: 'Leave Type',
              hint: 'Select type',
              icon: _iconForType(selectedType),
            ),
            items: _leaveTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedType = value);
            },
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickLeaveDate(isStart: true),
                  icon: Icon(Icons.date_range, color: Colors.white70),
                  label: Text(
                    leaveStart == null ? 'Start date' : formatShortDate(leaveStart!),
                    style: TextStyle(
                        color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickLeaveDate(isStart: false),
                  icon: Icon(Icons.event, color: Colors.white70),
                  label: Text(
                    leaveEnd == null ? 'End date' : formatShortDate(leaveEnd!),
                    style: TextStyle(
                        color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Half day',
              style: TextStyle(color: Colors.white),
            ),
            value: isHalfDay,
            onChanged: (v) => setState(() => isHalfDay = v),
          ),
          SizedBox(height: 8),
          TextField(
            controller: reasonController,
            maxLines: 3,
            maxLength: 300,
            style: TextStyle(
                color: Colors.white,
            ),
            decoration: AppTheme.inputDecoration(
              label: 'Reason',
              hint: 'Describe why you need this leave (min. 10 characters)',
              icon: Icons.notes_outlined,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : submitRequest,
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send_rounded),
              label: Text(isLoading ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _requestCard(String docId, Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'Leave';
    final status = data['status']?.toString() ?? 'Pending';
    final reason = data['reason']?.toString() ?? '';
    final date = data['date'] as Timestamp?;
    final leaveStartTs = data['leave_start'] as Timestamp?;
    final leaveEndTs = data['leave_end'] as Timestamp?;
    final halfDay = data['is_half_day'] == true;

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
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A8A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconForType(type), color: Colors.white70, size: 22,),
              ),
              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          SizedBox(height: 12),
          Text('Reason',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
            ),
          ),
          SizedBox(height: 4),
          if (leaveStartTs != null) ...[
            SizedBox(height: 6),
            Text('Leave: ${formatShortDate(leaveStartTs.toDate())}'
              '${leaveEndTs != null ? ' → ${formatShortDate(leaveEndTs.toDate())}' : ''}'
              '${halfDay ? ' (Half day)' : ''}',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(reason,
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
            ),
          ),
          if (status == 'Pending') ...[
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelRequest(docId),
                icon: Icon(Icons.cancel_outlined, size: 18),
                label: Text('Cancel request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
          if (status == 'Rejected') ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.red.shade300),
                SizedBox(width: 6),
                Text('Contact admin for details',
                  style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Leave of Absence',
          style: TextStyle(
              color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              String name = 'Loading...';
              if (snapshot.hasData) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                name = data?['name']?.toString() ?? 'Employee';
              }

              return Container(
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
                        Icons.event_available,
                        color: Colors.white,
                        size: 28,
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
                          Text(
                            'ID: ${widget.employeeId}',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: loa
                  .where('employee_id', isEqualTo: widget.employeeId)
                  .snapshots(),
              builder: (context, snapshot) {
                int pendingCount = 0;
                List<QueryDocumentSnapshot> docs = [];

                if (snapshot.hasData) {
                  docs = _sortedDocs(snapshot.data!.docs);
                  for (final doc in docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    if ((d['status'] ?? 'Pending') == 'Pending') {
                      pendingCount++;
                    }
                  }
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load requests',
                      style: TextStyle(
                          color: Colors.red.shade300,
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formCard(),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('My Requests',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (pendingCount > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Text(
                                      '$pendingCount pending',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: Colors.white.withValues(alpha: 0.2),
                            ),
                            SizedBox(height: 12),
                            Text('No LOA requests yet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text('Submit your first request above',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              return _requestCard(docs[index].id, data);
                            },
                            childCount: docs.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
