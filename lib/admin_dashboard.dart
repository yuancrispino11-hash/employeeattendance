import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employeeattendance/admin_employee_attendance_page.dart';
import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/utils/attendance_utils.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminDashboard({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final employees = FirebaseFirestore.instance.collection('employees');
  final attendance = FirebaseFirestore.instance.collection('attendance');
  final loa = FirebaseFirestore.instance.collection('loa_requests');

  int currentIndex = 0;
  String _loaFilter = 'All';
  final TextEditingController _loaSearchController = TextEditingController();

  @override
  void dispose() {
    _loaSearchController.dispose();
    super.dispose();
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _showAddEmployeeDialog() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'employee';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add Employee',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(idController, 'Employee ID'),
                SizedBox(height: 10),
                _dialogField(nameController, 'Full Name'),
                SizedBox(height: 10),
                _dialogField(passwordController, 'Password', obscure: true),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogDecoration('Role'),
                  items: [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = idController.text.trim();
                final name = nameController.text.trim();
                final password = passwordController.text.trim();

                if (id.isEmpty || name.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill all fields')),
                  );
                  return;
                }

                final existing = await employees.doc(id).get();
                if (existing.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Employee ID already exists')),
                  );
                  return;
                }

                final now = Timestamp.now();
                await employees.doc(id).set({
                  'name': name,
                  'password': password,
                  'role': selectedRole,
                  'active': true,
                  'created_at': now,
                  'updated_at': now,
                });

                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    idController.dispose();
    nameController.dispose();
    passwordController.dispose();

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee created')),
      );
    }
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogDecoration(label),
    );
  }

  Future<void> _showEditEmployeeDialog(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(text: data['name']?.toString());
    final passwordController = TextEditingController();
    final deptController = TextEditingController(text: data['department']?.toString() ?? '');
    String selectedRole = data['role']?.toString() ?? 'employee';
    bool isActive = data['active'] != false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Edit Employee', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: $employeeId', style: const TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                _dialogField(nameController, 'Full Name'),
                SizedBox(height: 10),
                _dialogField(passwordController, 'New Password (optional)', obscure: true),
                SizedBox(height: 10),
                _dialogField(deptController, 'Department (optional)'),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: Color(0xFF1E293B),
                  style: TextStyle(
                      color: Colors.white
                  ),
                  decoration: _dialogDecoration('Role'),
                  items: [
                    DropdownMenuItem(
                        value: 'employee',
                        child: Text('Employee')
                    ),
                    DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin')
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Active', style: TextStyle(color: Colors.white)),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final updates = <String, dynamic>{
                  'name': name,
                  'role': selectedRole,
                  'active': isActive,
                  'department': deptController.text.trim().isEmpty ? null : deptController.text.trim(),
                  'updated_at': Timestamp.now(),
                };
                final pass = passwordController.text.trim();
                if (pass.isNotEmpty) updates['password'] = pass;
                await employees.doc(employeeId).update(updates);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    passwordController.dispose();
    deptController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee updated')),
      );
    }
  }

  Future<void> _updateLoaStatus(String docId, String status) async {
    await loa.doc(docId).update({
      'status': status,
      'approved_by': widget.adminId,
      'updated_at': Timestamp.now(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    if (employeeId == widget.adminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete your own account')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text('Remove employee $employeeId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(
                    color: Colors.red)
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final attSnap = await attendance.where('employee_id', isEqualTo: employeeId).get();
      final loaSnap = await loa.where('employee_id', isEqualTo: employeeId).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in attSnap.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in loaSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(employees.doc(employeeId));
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee and related records removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _deactivateEmployee(String employeeId) async {
    await employees.doc(employeeId).update({
      'active': false,
      'updated_at': Timestamp.now(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee deactivated')),
      );
    }
  }

  Widget _buildOverview() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${widget.adminName}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Total Employees',
            stream: employees.snapshots(),
            icon: Icons.people,
          ),
          SizedBox(height: 10),
          _buildCard(
            title: 'Attendance Records',
            stream: attendance.snapshots(),
            icon: Icons.access_time,
          ),
          SizedBox(height: 10),
          _buildCard(
            title: 'Pending LOA',
            stream: loa.where('status', isEqualTo: 'Pending').snapshots(),
            icon: Icons.pending_actions,
          ),
          SizedBox(height: 20),
          Text('Recent Attendance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: attendance.orderBy('date', descending: true).limit(20).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No attendance records',
                      style: TextStyle(
                          color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final empId = data['employee_id']?.toString() ?? '';
                    return Card(
                      color: Color(0xFF1E293B),
                      child: ListTile(
                        onTap: empId.isEmpty ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminEmployeeAttendancePage(
                                      employeeId: empId,
                                      employeeName:
                                          data['name']?.toString() ?? empId,
                                    ),
                                  ),
                                );
                              },
                        title: Text(data['name'] ?? 'Unknown',
                          style: TextStyle(
                              color: Colors.white,
                          ),
                        ),
                        subtitle: Text('ID: $empId · Tap for history',
                          style: TextStyle(
                              color: Colors.white70,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.white54,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployees() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddEmployeeDialog,
              icon: Icon(Icons.person_add),
              label: Text('Add Employee / Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('All Employees',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: employees.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator()
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text('No employees yet',
                    style: TextStyle(
                        color: Colors.white70,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role']?.toString() ?? 'employee';
                  final isAdmin = role.toLowerCase() == 'admin';
                  final active = data['active'] != false;

                  return Card(
                    color: Color(0xFF1E293B),
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEmployeeAttendancePage(
                              employeeId: doc.id,
                              employeeName: data['name']?.toString() ?? doc.id,
                            ),
                          ),
                        );
                      },
                      leading: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: active ? (isAdmin ? Colors.amber : Colors.white70) : Colors.grey,
                      ),
                      title: Text(data['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${doc.id} • ${role.toUpperCase()}'
                        '${active ? '' : ' • INACTIVE'}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: doc.id == widget.adminId ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _showEditEmployeeDialog(doc.id, data),
                                ),
                                IconButton(
                                  icon: Icon(
                                    active ? Icons.person_off : Icons.person,
                                    color: Colors.orange,
                                  ),
                                  onPressed: active ? () => _deactivateEmployee(doc.id) : null,
                                ),

                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteEmployee(doc.id),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static const _loaFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled',
  ];

  Widget _loaFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: _loaFilters.map((label) {
            final selected = _loaFilter == label;
            final isLast = label == _loaFilters.last;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _loaFilter = label),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoaRequests() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _loaSearchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or reason...',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF334155)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by status',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _loaFilterBar(),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: loa.orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final query = _loaSearchController.text.trim().toLowerCase();
              var docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString() ?? 'Pending';
                if (_loaFilter != 'All' && status != _loaFilter) return false;
                if (query.isEmpty) return true;
                final name =
                    (data['employee_name'] ?? data['employee_id'] ?? '')
                        .toString()
                        .toLowerCase();
                final reason = (data['reason'] ?? '').toString().toLowerCase();
                final id = (data['employee_id'] ?? '').toString().toLowerCase();
                return name.contains(query) ||
                    reason.contains(query) ||
                    id.contains(query);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text('No matching LOA requests',
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
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString() ?? 'Pending';
                  final isPending = status == 'Pending';
                  final color = statusColor(status);
                  final empName = data['employee_name']?.toString() ??
                      data['employee_id']?.toString() ?? 'Unknown';
                  final leaveStart = data['leave_start'] as Timestamp?;
                  final leaveEnd = data['leave_end'] as Timestamp?;

                  return Card(
                    color: Color(0xFF1E293B),
                    margin: EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('ID: ${data['employee_id'] ?? ''}',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (leaveStart != null)
                            Text('Leave: ${formatShortDate(leaveStart.toDate())}'
                              '${leaveEnd != null ? ' → ${formatShortDate(leaveEnd.toDate())}' : ''}'
                              '${data['is_half_day'] == true ? ' (Half day)' : ''}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          SizedBox(height: 4),
                          Text('${data['type'] ?? ''} — ${data['reason'] ?? ''}',
                            style: TextStyle(
                                color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPending) ...[
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateLoaStatus(doc.id, 'Approved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Approve'),
                                  ),
                                ),
                                SizedBox(width: 10),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _updateLoaStatus(doc.id, 'Rejected'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Text(title, style: TextStyle(
                  color: Colors.white,
              )
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text('0', style: TextStyle(color: Colors.white));
              }
              return Text(
                '${snapshot.data!.docs.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
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
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Admin Dashboard',
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
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildOverview(),
          _buildEmployees(),
          _buildLoaRequests(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E3A8A),
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Employees'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'LOA'),
        ],
      ),
    );
  }
}
