import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employeeattendance/login_page.dart';
import 'package:employeeattendance/utils/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String employeeId;
  final String role;

  const SettingsPage({
    super.key,
    required this.employeeId,
    required this.role,
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    passwordController = TextEditingController();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final doc = await employees.doc(widget.employeeId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      nameController.text = data?['name'] ?? '';
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> updateProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _snack('Name cannot be empty');
      return;
    }

    setState(() => isLoading = true);

    try {
      final updates = <String, dynamic>{
        'name': name,
        'updated_at': Timestamp.now(),
      };
      final pass = passwordController.text.trim();
      if (pass.isNotEmpty) {
        if (pass.length < 6) {
          _snack('Password must be at least 6 characters');
          if (mounted) setState(() => isLoading = false);
          return;
        }
        updates['password'] = pass;
      }

      await employees.doc(widget.employeeId).update(updates);
      passwordController.clear();
      _snack('Profile updated successfully');
    } catch (e) {
      _snack('Update failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: Text('Settings',
            style: TextStyle(
                color: Colors.white
            ),
        ),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
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

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final role = data['role']?.toString() ?? widget.role;
          final department = data['department']?.toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
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
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? '',
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
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account (read-only)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            _readOnlyRow('Role', role.toUpperCase()),
                            _readOnlyRow('Employee ID', widget.employeeId),
                            if (department != null && department.isNotEmpty)
                              _readOnlyRow('Department', department),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 14),
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: Colors.white),
                              decoration: AppTheme.inputDecoration(
                                label: 'Name',
                                hint: 'Your full name',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            SizedBox(height: 14),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: TextStyle(color: Colors.white),
                              decoration: AppTheme.inputDecoration(
                                label: 'New Password',
                                hint: 'Leave blank to keep current',
                                icon: Icons.lock_outline,
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('UPDATE PROFILE'),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110,
            child: Text(
                label, style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
