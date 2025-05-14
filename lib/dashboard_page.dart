import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_page.dart';

const appId = '8YLfi6BITxTiH1sT4udmgimcGZ45dPo1ILAGTdgu';
const restKey = 'scK02G7UzAq13Ogpv4K7RjrbJBaxVoJAyPidzjIM';
const serverUrl = 'https://parseapi.back4app.com';

class DashboardPage extends StatefulWidget {
  final String username;
  final String sessionToken;

  const DashboardPage({required this.username, required this.sessionToken});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];
  String? editingTaskId;

  Future<String?> getCurrentUserId() async {
    final response = await http.get(
      Uri.parse('$serverUrl/users/me'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['objectId'];
    }
    return null;
  }

  Future<void> fetchTasks() async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    final whereQuery = jsonEncode({
      "user": { 
        "__type": "Pointer",
        "className": "_User",
        "objectId": userId
      }
    });

    final response = await http.get(
      Uri.parse('$serverUrl/classes/Task?where=$whereQuery&order=-createdAt'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        tasks = List<Map<String, dynamic>>.from(data['results']);
      });
    }
  }

  Future<void> createOrUpdateTask() async {
    final title = titleController.text.trim();
    final description = descController.text.trim();
    if (title.isEmpty || description.isEmpty) return;

    final userId = await getCurrentUserId();
    if (userId == null) return;

    final taskData = {
      "title": title,
      "description": description,
      "user": {
        "__type": "Pointer",
        "className": "_User",
        "objectId": userId
      }
    };

    http.Response response;
    if (editingTaskId != null) {
      // Update existing
      response = await http.put(
        Uri.parse('$serverUrl/classes/Task/$editingTaskId'),
        headers: {
          "X-Parse-Application-Id": appId,
          "X-Parse-REST-API-Key": restKey,
          "X-Parse-Session-Token": widget.sessionToken,
          "Content-Type": "application/json"
        },
        body: jsonEncode(taskData),
      );
    } else {
      // Create new
      response = await http.post(
        Uri.parse('$serverUrl/classes/Task'),
        headers: {
          "X-Parse-Application-Id": appId,
          "X-Parse-REST-API-Key": restKey,
          "X-Parse-Session-Token": widget.sessionToken,
          "Content-Type": "application/json"
        },
        body: jsonEncode(taskData),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editingTaskId != null ? "Task updated" : "Task created")),
      );
      titleController.clear();
      descController.clear();
      editingTaskId = null;
      fetchTasks();
    } else {
      final error = jsonDecode(response.body)['error'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(title: Text("Error"), content: Text(error)),
      );
    }
  }

  Future<void> deleteTask(String objectId) async {
    final response = await http.delete(
      Uri.parse('$serverUrl/classes/Task/$objectId'),
      headers: {
        "X-Parse-Application-Id": appId,
        "X-Parse-REST-API-Key": restKey,
        "X-Parse-Session-Token": widget.sessionToken,
      },
    );

    if (response.statusCode == 200) {
      fetchTasks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task deleted")));
    } else {
      final error = jsonDecode(response.body)['error'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(title: Text("Error"), content: Text(error)),
      );
    }
  }

  void startEditing(Map<String, dynamic> task) {
    setState(() {
      editingTaskId = task['objectId'];
      titleController.text = task['title'] ?? '';
      descController.text = task['description'] ?? '';
    });
  }

  void showDetail(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Description:\n${task['description'] ?? ''}"),
            SizedBox(height: 10),
            Text("Created At:\n${task['createdAt']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))
        ],
      ),
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthPage()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Dashboard")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Welcome, ${widget.username}!", style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              TextField(controller: titleController, decoration: InputDecoration(labelText: "Task Title")),
              TextField(controller: descController, decoration: InputDecoration(labelText: "Description")),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: createOrUpdateTask,
                child: Text(editingTaskId == null ? "Create Task" : "Update Task"),
              ),
              SizedBox(height: 20),
              Divider(),
              Expanded(
                child: tasks.isEmpty
                    ? Center(child: Text("No tasks found"))
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (_, i) {
                          final task = tasks[i];
                          return Card(
                            child: ListTile(
                              title: Text(task['title'] ?? ''),
                              subtitle: Text(task['description'] ?? ''),
                              onTap: () => showDetail(task),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: Icon(Icons.edit), onPressed: () => startEditing(task)),
                                  IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteTask(task['objectId'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Logout"),
              ),
            ],
          ),
        ),
      );
}
