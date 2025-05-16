import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'auth_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final appId = dotenv.env['APP_ID']!;
final restKey = dotenv.env['REST_KEY']!;
final serverUrl = dotenv.env['SERVER_URL']!;

class DashboardPage extends StatefulWidget {
  final String username;
  final String sessionToken;

  const DashboardPage({required this.username, required this.sessionToken});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> tasks = [];
  String? editingTaskId;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<String?> getCurrentUserId() async {
    final res = await http.get(
      Uri.parse('$serverUrl/users/me'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['objectId'];
    return null;
  }

  Future<void> fetchTasks() async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    final query = jsonEncode({
      "user": {"__type": "Pointer", "className": "_User", "objectId": userId},
    });

    final res = await http.get(
      Uri.parse('$serverUrl/classes/Task?where=$query&order=-createdAt'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );

    if (res.statusCode == 200) {
      setState(() {
        tasks = List<Map<String, dynamic>>.from(
          jsonDecode(res.body)['results'],
        );
      });
    }
  }

  Future<void> createOrUpdateTask() async {
    final name = nameController.text.trim();
    final bio = bioController.text.trim();
    final age = ageController.text.trim();

    final ageValue = int.parse(age); // safe now since form was validated

    final userId = await getCurrentUserId();
    if (userId == null) return;

    final taskData = {
      "name": name,
      "bio": bio,
      "age": ageValue,
      "user": {"__type": "Pointer", "className": "_User", "objectId": userId},
    };

    final isUpdate = editingTaskId != null;
    final uri =
        isUpdate
            ? Uri.parse('$serverUrl/classes/Task/$editingTaskId')
            : Uri.parse('$serverUrl/classes/Task');

    final res =
        await (isUpdate
            ? http.put(uri, headers: _headers(), body: jsonEncode(taskData))
            : http.post(uri, headers: _headers(), body: jsonEncode(taskData)));

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(isUpdate ? "Updated" : "Created")));
      clearFields();
      fetchTasks();
    } else {
      showError(jsonDecode(res.body)['error']);
    }
  }

  Future<void> deleteTask(String id) async {
    final res = await http.delete(
      Uri.parse('$serverUrl/classes/Task/$id'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );
    if (res.statusCode == 200) {
      fetchTasks();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Deleted")));
    } else {
      showError(jsonDecode(res.body)['error']);
    }
  }

  void clearFields() {
    nameController.clear();
    bioController.clear();
    ageController.clear();
    editingTaskId = null;
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Error"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  void startEditing(Map<String, dynamic> task) {
    setState(() {
      editingTaskId = task['objectId'];
      nameController.text = task['name'] ?? '';
      bioController.text = task['bio'] ?? '';
      ageController.text = task['age']?.toString() ?? '';
    });
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthPage()),
      (_) => false,
    );
  }

  Map<String, String> _headers() => {
    "X-Parse-Application-Id": appId,
    "X-Parse-REST-API-Key": restKey,
    "X-Parse-Session-Token": widget.sessionToken,
    "Content-Type": "application/json",
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      // Top Navigation
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Hi, ${widget.username}",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),

      // Gradient background and layout
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child:
                    isWide
                        ? Row(
                          children: [
                            Expanded(child: _buildGradientFormCard()),
                            SizedBox(width: 20),
                            Expanded(child: _buildGradientTaskList()),
                          ],
                        )
                        : Column(
                          children: [
                            _buildGradientFormCard(),
                            SizedBox(height: 20),
                            Expanded(child: _buildGradientTaskList()),
                          ],
                        ),
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              child: Center(
                child: Text(
                  "© ${DateTime.now().year} Monita. All rights reserved.",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFormCard() {
  return Card(
    elevation: 10,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.white.withOpacity(0.9),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey, // ← Add the form key here
        child: Column(
          children: [
            Text(
              "Hi, ${widget.username}!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: bioController,
              decoration: InputDecoration(
                labelText: "Bio",
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Bio is required' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: ageController,
              decoration: InputDecoration(
                labelText: "Age",
                prefixIcon: Icon(Icons.cake_outlined),
                helperText: "Age must be a number (e.g. 25)",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                } else if (int.tryParse(value) == null) {
                  return 'Age must be a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(editingTaskId == null ? Icons.add : Icons.update),
              label: Text(editingTaskId == null ? "Create" : "Update"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  createOrUpdateTask();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildGradientTaskList() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child:
            tasks.isEmpty
                ? Center(
                  child: Text("No tasks yet!", style: TextStyle(fontSize: 16)),
                )
                : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return ListTile(
                      title: Text(
                        task['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("${task['bio']} • Age: ${task['age']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => startEditing(task),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteTask(task['objectId']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
