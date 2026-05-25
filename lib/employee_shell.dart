import 'package:employeeattendance/home_page.dart';
import 'package:employeeattendance/loa_page.dart';
import 'package:employeeattendance/report_page.dart';
import 'package:employeeattendance/settings_page.dart';
import 'package:flutter/material.dart';

class EmployeeShell extends StatefulWidget {
  final String employeeId;
  final String role;

  const EmployeeShell({
    super.key,
    required this.employeeId,
    required this.role,
  });

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(employeeId: widget.employeeId, role: widget.role),
          ReportPage(employeeId: widget.employeeId, role: widget.role),
          LoaPage(employeeId: widget.employeeId, role: widget.role),
          SettingsPage(employeeId: widget.employeeId, role: widget.role),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E3A8A),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'LOA'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
