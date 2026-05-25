import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';
import 'employee_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  void loginUser() async {
    String empID = idController.text.trim();
    String password = passController.text.trim();

    if (empID.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(empID)
          .get();

      if (!doc.exists || doc.data() == null) {
        showError("Employee not found");
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      final storedPassword = data['password']?.toString();
      final role = data['role']?.toString() ?? "employee";

      if (storedPassword == null) {
        showError("Invalid employee data");
        return;
      }

      if (storedPassword != password) {
        showError("Wrong password");
        return;
      }

      if (!mounted) return;

      final name = data['name']?.toString() ?? 'User';
      final isAdmin = role.toLowerCase() == 'admin';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin
              ? AdminDashboard(
                  adminId: doc.id,
                  adminName: name,
                )
              : EmployeeShell(
                  employeeId: doc.id,
                  role: role,
                ),
        ),
      );
    } catch (e) {
      showError("Login error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    idController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.lock_outline, size: 90, color: Colors.white),
              SizedBox(height: 15),
              Text("Employee Login",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),

              TextField(
                controller: idController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.badge, color: Colors.white),
                  hintText: "Employee ID",
                  hintStyle: TextStyle(
                      color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              TextField(
                controller: passController,
                obscureText: obscurePassword,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  hintText: "Password",
                  hintStyle: TextStyle(
                      color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading ?  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      :  Text("LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}