import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = "http://10.0.2.2:8000";

void main() {
  runApp(const HRMSApp());
}

class HRMSApp extends StatelessWidget {
  const HRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "HRMS",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class Api {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$apiUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Invalid email or password");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> employees() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$apiUrl/employees"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Could not load employees");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> departments() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$apiUrl/departments"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Could not load departments");
    }

    return jsonDecode(response.body);
  }

  static Future<void> addEmployee({
    required String employeeCode,
    required String name,
    required String email,
    required String phone,
    required String designation,
    required String joiningDate,
    required int departmentId,
    required String? password,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$apiUrl/employees"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "employee_code": employeeCode,
        "name": name,
        "email": email,
        "phone": phone,
        "designation": designation,
        "joining_date": joiningDate,
        "department_id": departmentId,
        "password": password,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not add employee");
    }
  }

  static Future<void> updateEmployee({
    required int id,
    required String employeeCode,
    required String name,
    required String email,
    required String phone,
    required String designation,
    required String joiningDate,
    required int departmentId,
    required String? password,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("$apiUrl/employees/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "employee_code": employeeCode,
        "name": name,
        "email": email,
        "phone": phone,
        "designation": designation,
        "joining_date": joiningDate,
        "department_id": departmentId,
        "password": password,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not update employee");
    }
  }

  static Future<void> createEmployeeLogin({
    required int id,
    required String password,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$apiUrl/employees/$id/create-login")
          .replace(queryParameters: {"password": password}),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not create login");
    }
  }

  static Future<void> deactivateEmployee(int id) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse("$apiUrl/employees/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not deactivate employee");
    }
  }

  static Future<void> activateEmployee(int id) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("$apiUrl/employees/$id/activate"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not activate employee");
    }
  }

  static Future<Map<String, dynamic>> dashboard() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$apiUrl/dashboard"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Could not load dashboard");
    }

    return jsonDecode(response.body);
  }

  static Future<void> checkIn(int employeeId) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$apiUrl/attendance/check-in?employee_id=$employeeId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Check in failed");
    }
  }

  static Future<void> checkOut(int employeeId) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$apiUrl/attendance/check-out?employee_id=$employeeId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Check out failed");
    }
  }

  static Future<List<dynamic>> attendanceHistory(int employeeId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$apiUrl/attendance/$employeeId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Could not load attendance");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> leaves() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$apiUrl/leaves"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Could not load leaves");
    }

    return jsonDecode(response.body);
  }

  static Future<void> applyLeave({
    required int employeeId,
    required String type,
    required String from,
    required String to,
    required String reason,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$apiUrl/leaves"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "employee_id": employeeId,
        "leave_type": type,
        "from_date": from,
        "to_date": to,
        "reason": reason,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Leave request failed");
    }
  }

  static Future<void> approveLeave(int id) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("$apiUrl/leaves/$id/approve"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not approve leave");
    }
  }

  static Future<void> rejectLeave(int id) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("$apiUrl/leaves/$id/reject"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Could not reject leave");
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveLogin(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", data["token"]);
    await prefs.setString("role", data["role"]);
    if (data["employee_id"] != null) {
      await prefs.setInt("employee_id", data["employee_id"]);
    }
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role") ?? "";
  }

  static Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("employee_id");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final data = await Api.login(email.text.trim(), password.text.trim());
      await Api.saveLogin(data);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 380,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "HRMS",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: Text(loading ? "Logging in..." : "Login"),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  String role = "";
  int? employeeId;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final loadedRole = await Api.getRole();
    final loadedEmployeeId = await Api.getEmployeeId();
    if (!mounted) return;
    setState(() {
      role = loadedRole;
      employeeId = loadedEmployeeId;
    });
  }

  Future<void> logout() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  IconData iconFor(String label) {
    switch (label) {
      case "Dashboard":
        return Icons.dashboard;
      case "Employees":
        return Icons.people;
      case "Departments":
        return Icons.business;
      case "Attendance":
        return Icons.access_time;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isHr = role == "HR";
    final pages = <Widget>[
      DashboardPage(isHr: isHr, employeeId: employeeId),
      if (isHr) const EmployeesPage(),
      if (isHr) const DepartmentsPage(),
      AttendancePage(employeeId: employeeId, isHr: isHr),
      LeavesPage(employeeId: employeeId, isHr: isHr),
    ];

    final labels = <String>[
      "Dashboard",
      if (isHr) "Employees",
      if (isHr) "Departments",
      "Attendance",
      "Leaves",
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (selected >= pages.length) selected = 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text("HRMS"),
            actions: [
              IconButton(
                onPressed: logout,
                tooltip: "Logout",
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: isMobile
              ? pages[selected]
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: (value) =>
                          setState(() => selected = value),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final label in labels)
                          NavigationRailDestination(
                            icon: Icon(iconFor(label)),
                            label: Text(label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages[selected]),
                  ],
                ),
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (value) =>
                      setState(() => selected = value),
                  destinations: [
                    for (final label in labels)
                      NavigationDestination(
                        icon: Icon(iconFor(label)),
                        selectedIcon: Icon(iconFor(label)),
                        label: label,
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  final bool isHr;
  final int? employeeId;

  const DashboardPage({
    super.key,
    required this.isHr,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context) {
    if (isHr) {
      return const HrDashboardPage();
    }

    return EmployeeDashboardPage(
      employeeId: employeeId,
    );
  }
}

class HrDashboardPage extends StatelessWidget {
  const HrDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Api.dashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final d = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "HR Dashboard",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Overview of the organization",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  StatCard(
                    title: "Employees",
                    value: "${d["total_employees"]}",
                    icon: Icons.people,
                  ),
                  StatCard(
                    title: "Present Today",
                    value: "${d["present_today"]}",
                    icon: Icons.check_circle,
                  ),
                  StatCard(
                    title: "Pending Leaves",
                    value: "${d["pending_leaves"]}",
                    icon: Icons.pending_actions,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmployeeDashboardPage extends StatefulWidget {
  final int? employeeId;

  const EmployeeDashboardPage({
    super.key,
    required this.employeeId,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  late Future<List<dynamic>> attendance;
  late Future<List<dynamic>> leaves;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    if (widget.employeeId == null) {
      attendance = Future.value([]);
      leaves = Future.value([]);
      return;
    }

    attendance = Api.attendanceHistory(widget.employeeId!);
    leaves = Api.leaves();
  }

  String todayString() {
    final now = DateTime.now();

    return "${now.year.toString().padLeft(4, "0")}-"
        "${now.month.toString().padLeft(2, "0")}-"
        "${now.day.toString().padLeft(2, "0")}";
  }

  Map<String, dynamic>? getTodayAttendance(List<dynamic> records) {
    final today = todayString();

    for (final record in records) {
      if (record["date"] == today) {
        return Map<String, dynamic>.from(record);
      }
    }

    return null;
  }

  String getAttendanceStatus(Map<String, dynamic>? record) {
    if (record == null) {
      return "Not checked in";
    }

    final checkOut = record["check_out"];
    if (checkOut != null && checkOut.toString().isNotEmpty) {
      return "Checked out at ${formatDashboardTime(checkOut)}";
    }

    final checkIn = record["check_in"];
    if (checkIn != null && checkIn.toString().isNotEmpty) {
      return "Checked in at ${formatDashboardTime(checkIn)}";
    }

    return "Not checked in";
  }

  int getPendingLeaves(List<dynamic> records) {
    return records.where((leave) => leave["status"] == "Pending").length;
  }

  Future<void> attendanceAction(bool checkIn) async {
    if (widget.employeeId == null) return;

    try {
      if (checkIn) {
        await Api.checkIn(widget.employeeId!);
      } else {
        await Api.checkOut(widget.employeeId!);
      }

      if (!mounted) return;

      setState(() {
        attendance = Api.attendanceHistory(widget.employeeId!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkIn
                ? "Checked in successfully"
                : "Checked out successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.employeeId == null) {
      return const Center(
        child: Text("Employee account not found"),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: attendance,
      builder: (context, attendanceSnapshot) {
        if (attendanceSnapshot.hasError) {
          return Center(
            child: Text(attendanceSnapshot.error.toString()),
          );
        }

        if (!attendanceSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return FutureBuilder<List<dynamic>>(
          future: leaves,
          builder: (context, leaveSnapshot) {
            if (leaveSnapshot.hasError) {
              return Center(
                child: Text(leaveSnapshot.error.toString()),
              );
            }

            if (!leaveSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final today = getTodayAttendance(attendanceSnapshot.data!);
            final status = getAttendanceStatus(today);
            final pendingLeaves = getPendingLeaves(leaveSnapshot.data!);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employee Dashboard",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your personal work summary",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      StatCard(
                        title: "Today's Attendance",
                        value: status,
                        icon: status.startsWith("Checked")
                            ? Icons.check_circle
                            : Icons.access_time,
                      ),
                      StatCard(
                        title: "Pending Leaves",
                        value: "$pendingLeaves",
                        icon: Icons.pending_actions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.event_note, size: 35),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "My Leave Requests",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${leaveSnapshot.data!.length} leave request(s)",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String formatDashboardTime(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return "-";
  }

  final text = value.toString();

  try {
    final dateTime = DateTime.parse(text).toLocal();

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, "0");
    final second = dateTime.second.toString().padLeft(2, "0");
    final period = dateTime.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute:$second $period";
  } catch (_) {
    return text.split(".").first;
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final cardWidth = width < 600 ? width - 50 : 250.0;
        return SizedBox(
          width: cardWidth > 0 ? cardWidth : 200,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 35),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: FutureBuilder<List<dynamic>>(
        future: Api.departments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final list = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Departments",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text("No departments found"),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final department = list[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.business),
                              ),
                              title: Text(
                                department["name"] ?? "Department",
                              ),
                              subtitle: Text(
                                department["description"] ?? "",
                              ),
                            ),
                          );
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

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  late Future<List<dynamic>> employees;

  @override
  void initState() {
    super.initState();
    employees = Api.employees();
  }

  void refresh() {
    setState(() {
      employees = Api.employees();
    });
  }

  Future<void> showEmployeeForm({Map<String, dynamic>? employee}) async {
    final isEdit = employee != null;

    final codeController = TextEditingController(
      text: employee?["employee_code"] ?? "",
    );
    final nameController = TextEditingController(
      text: employee?["name"] ?? "",
    );
    final emailController = TextEditingController(
      text: employee?["email"] ?? "",
    );
    final phoneController = TextEditingController(
      text: employee?["phone"] ?? "",
    );
    final designationController = TextEditingController(
      text: employee?["designation"] ?? "",
    );
    final passwordController = TextEditingController();

    DateTime joiningDate = employee != null
        ? DateTime.parse(employee["joining_date"])
        : DateTime.now();

    List<dynamic> departments = [];
    int? selectedDepartmentId = employee?["department_id"];

    try {
      departments = await Api.departments();

      if (selectedDepartmentId == null && departments.isNotEmpty) {
        selectedDepartmentId = departments.first["id"];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return;
    }

    String formatDate(DateTime date) {
      return "${date.year.toString().padLeft(4, "0")}-"
          "${date.month.toString().padLeft(2, "0")}-"
          "${date.day.toString().padLeft(2, "0")}";
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Employee" : "Add Employee"),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: "Employee Code",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: designationController,
                        decoration: const InputDecoration(
                          labelText: "Designation",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit
                              ? "New Password (optional)"
                              : "Password",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: "Department",
                          border: OutlineInputBorder(),
                        ),
                        items: departments.map((department) {
                          return DropdownMenuItem<int>(
                            value: department["id"],
                            child: Text(department["name"]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(
                            () => selectedDepartmentId = value,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Joining Date"),
                        subtitle: Text(formatDate(joiningDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: joiningDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() => joiningDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    if (codeController.text.trim().isEmpty ||
                        nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        selectedDepartmentId == null ||
                        (!isEdit && passwordController.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please fill the required fields",
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        await Api.updateEmployee(
                          id: employee["id"],
                          employeeCode: codeController.text.trim(),
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          designation: designationController.text.trim(),
                          joiningDate: formatDate(joiningDate),
                          departmentId: selectedDepartmentId!,
                          password: passwordController.text.trim().isEmpty
                              ? null
                              : passwordController.text.trim(),
                        );
                      } else {
                        await Api.addEmployee(
                          employeeCode: codeController.text.trim(),
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          designation: designationController.text.trim(),
                          joiningDate: formatDate(joiningDate),
                          departmentId: selectedDepartmentId!,
                          password: passwordController.text.trim().isEmpty
                              ? null
                              : passwordController.text.trim(),
                        );
                      }

                      if (mounted) Navigator.pop(dialogContext);
                      refresh();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? "Save" : "Add"),
                ),
              ],
            );
          },
        );
      },
    );

  
  }

  Future<void> deactivateEmployee(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Deactivate Employee"),
          content: const Text(
            "Are you sure you want to deactivate this employee?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Deactivate"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await Api.deactivateEmployee(id);
      refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee deactivated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> createLogin(int id, String email) async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Create Employee Login"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final value = passwordController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );

    

    if (password == null) return;

    try {
      await Api.createEmployeeLogin(
        id: id,
        password: password,
      );
      refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login created for $email")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> activateEmployee(int id) async {
    try {
      await Api.activateEmployee(id);
      refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee activated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: employees,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Active employees first, deactivated employees last.
          // Within each group, newest employee (highest id) comes first.
          final list = List<dynamic>.from(snapshot.data!);
          list.sort((a, b) {
            final aActive = a["active"] == true;
            final bActive = b["active"] == true;

            if (aActive != bActive) {
              return aActive ? -1 : 1;
            }

            final aId = int.tryParse(a["id"].toString()) ?? 0;
            final bId = int.tryParse(b["id"].toString()) ?? 0;
            return bId.compareTo(aId);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Employees",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showEmployeeForm(),
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text("No employees found"))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final employee =
                              Map<String, dynamic>.from(list[index]);
                          final active = employee["active"] == true;
                          final name =
                              employee["name"]?.toString() ?? "Employee";
                          final designation =
                              employee["designation"]?.toString() ?? "";
                          final department =
                              employee["department"]?.toString() ?? "";
                          final email =
                              employee["email"]?.toString() ?? "";

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: active
                                    ? Colors.indigo.shade100
                                    : Colors.grey.shade300,
                                child: Icon(
                                  active ? Icons.person : Icons.person_off,
                                  color: active
                                      ? Colors.indigo.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(
                                    "$designation • $department",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 3),
                                  Text(
                                    active ? "Active" : "Deactivated",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.indigo
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == "edit") {
                                    showEmployeeForm(employee: employee);
                                  } else if (value == "login") {
                                    createLogin(
                                      employee["id"],
                                      email,
                                    );
                                  } else if (value == "activate") {
                                    activateEmployee(employee["id"]);
                                  } else if (value == "deactivate") {
                                    deactivateEmployee(employee["id"]);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (employee["has_login"] != true)
                                    const PopupMenuItem(
                                      value: "login",
                                      child: Text("Create Login"),
                                    ),
                                  const PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit"),
                                  ),
                                  PopupMenuItem(
                                    value: active
                                        ? "deactivate"
                                        : "activate",
                                    child: Text(
                                      active ? "Deactivate" : "Activate",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
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

class AttendancePage extends StatefulWidget {
  final int? employeeId;
  final bool isHr;

  const AttendancePage({
    super.key,
    required this.employeeId,
    required this.isHr,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Future<List<dynamic>>? employees;

  @override
  void initState() {
    super.initState();
    if (widget.isHr) {
      employees = Api.employees();
    }
  }

  String formatAttendanceTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return "-";

    final text = value.toString();
    try {
      final dateTime = DateTime.parse(text).toLocal();
      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
              ? dateTime.hour - 12
              : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, "0");
      final second = dateTime.second.toString().padLeft(2, "0");
      final period = dateTime.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute:$second $period";
    } catch (_) {
      return text.split(".").first;
    }
  }

  Future<void> viewAttendance(
    BuildContext context,
    int employeeId,
    String employeeName,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("$employeeName - Attendance"),
          content: SizedBox(
            width: 500,
            height: 400,
            child: FutureBuilder<List<dynamic>>(
              future: Api.attendanceHistory(employeeId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data!;
                if (records.isEmpty) {
                  return const Center(
                    child: Text("No attendance records found"),
                  );
                }

                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.access_time),
                      ),
                      title: Text(
                        record["date"]?.toString() ?? "Date",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Check In: ${formatAttendanceTime(record["check_in"])}",
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Check Out: ${formatAttendanceTime(record["check_out"])}",
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> action(bool checkIn) async {
    if (widget.employeeId == null) return;

    try {
      if (checkIn) {
        await Api.checkIn(widget.employeeId!);
      } else {
        await Api.checkOut(widget.employeeId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkIn ? "Checked in successfully" : "Checked out successfully",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget employeeAttendanceView() {
    if (widget.employeeId == null) {
      return const Center(child: Text("Employee account not found"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.access_time, size: 70),
              const SizedBox(height: 15),
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => action(true),
                  icon: const Icon(Icons.login),
                  label: const Text("Check In"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => action(false),
                  icon: const Icon(Icons.logout),
                  label: const Text("Check Out"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusIcon(bool active) {
    return CircleAvatar(
      backgroundColor:
          active ? Colors.indigo.shade100 : Colors.grey.shade300,
      child: Icon(
        active ? Icons.person : Icons.person_off,
        color: active ? Colors.indigo.shade700 : Colors.grey.shade700,
      ),
    );
  }

  Widget hrAttendanceView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: employees,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Same ordering as Employees page: active first, deactivated last.
          final list = List<dynamic>.from(snapshot.data!);
          list.sort((a, b) {
            final aActive = a["active"] == true;
            final bActive = b["active"] == true;
            if (aActive != bActive) return aActive ? -1 : 1;

            final aId = int.tryParse(a["id"].toString()) ?? 0;
            final bId = int.tryParse(b["id"].toString()) ?? 0;
            return bId.compareTo(aId);
          });

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employee Attendance",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final employee =
                            Map<String, dynamic>.from(list[index]);
                        final active = employee["active"] == true;
                        final name =
                            employee["name"]?.toString() ?? "Employee";
                        final designation =
                            employee["designation"]?.toString() ?? "";
                        final department =
                            employee["department"]?.toString() ?? "";

                        if (isMobile) {
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              leading: statusIcon(active),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                "$designation • $department",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: TextButton(
                                onPressed: () => viewAttendance(
                                  context,
                                  employee["id"],
                                  name,
                                ),
                                child: const Text("View"),
                              ),
                            ),
                          );
                        }

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            leading: statusIcon(active),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "$designation • $department",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: TextButton(
                              onPressed: () => viewAttendance(
                                context,
                                employee["id"],
                                name,
                              ),
                              child: const Text("View"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isHr ? hrAttendanceView() : employeeAttendanceView();
  }
}

class LeavesPage extends StatefulWidget {
  final int? employeeId;
  final bool isHr;

  const LeavesPage({
    super.key,
    required this.employeeId,
    required this.isHr,
  });

  @override
  State<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends State<LeavesPage> {
  late Future<List<dynamic>> leaves;

  @override
  void initState() {
    super.initState();
    leaves = Api.leaves();
  }

  Future<void> refresh() async {
    setState(() {
      leaves = Api.leaves();
    });
  }

  Future<void> applyLeave() async {
    if (widget.employeeId == null) return;

    String selectedType = "Casual";
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    String formatDate(DateTime date) {
      return "${date.year.toString().padLeft(4, "0")}-"
          "${date.month.toString().padLeft(2, "0")}-"
          "${date.day.toString().padLeft(2, "0")}";
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Apply Leave"),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Leave Type",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Casual",
                          child: Text("Casual"),
                        ),
                        DropdownMenuItem(
                          value: "Sick",
                          child: Text("Sick"),
                        ),
                        DropdownMenuItem(
                          value: "Earned",
                          child: Text("Earned"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("From Date"),
                      subtitle: Text(formatDate(fromDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            fromDate = picked;
                            if (toDate.isBefore(fromDate)) {
                              toDate = fromDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("To Date"),
                      subtitle: Text(formatDate(toDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: toDate.isBefore(fromDate)
                              ? fromDate
                              : toDate,
                          firstDate: fromDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => toDate = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Reason",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a reason"),
                        ),
                      );
                      return;
                    }

                    try {
                      await Api.applyLeave(
                        employeeId: widget.employeeId!,
                        type: selectedType,
                        from: formatDate(fromDate),
                        to: formatDate(toDate),
                        reason: reasonController.text.trim(),
                      );

                      if (mounted) {
                         Navigator.pop(dialogContext);
                        refresh();
}
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );

  }

  Future<void> approve(int id) async {
    try {
      await Api.approveLeave(id);
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> reject(int id) async {
    try {
      await Api.rejectLeave(id);
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: leaves,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  return Row(
                    children: [
                      const Expanded(
                        child: Text("Leaves", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                      if (!widget.isHr)
                        FilledButton.icon(
                          onPressed: applyLeave,
                          icon: const Icon(Icons.add),
                          label: Text(compact ? "Apply" : "Apply Leave"),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text("No leave requests"))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final leave = Map<String, dynamic>.from(list[index]);
                          final leaveType = leave["leave_type"]?.toString() ?? "Leave";
                          final status = leave["status"]?.toString() ?? "Pending";
                          final reason = leave["reason"]?.toString() ?? "-";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          leaveType,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  if (widget.isHr) ...[
                                    const SizedBox(height: 6),
                                    Text("Employee: ${leave["employee_name"] ?? "-"}"),
                                  ],
                                  const SizedBox(height: 6),
                                  Text("${leave["from_date"]} to ${leave["to_date"]}"),
                                  const SizedBox(height: 6),
                                  Text("Reason: $reason"),
                                  if (widget.isHr && status == "Pending") ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton(
                                          onPressed: () => approve(leave["id"]),
                                          child: const Text("Approve"),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => reject(leave["id"]),
                                          child: const Text("Reject"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
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
