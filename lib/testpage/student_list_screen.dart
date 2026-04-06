import 'package:flutter/material.dart';

import 'package:breffini_staff/testpage/student_test_modal.dart';

class TeacherStudentsListScreen extends StatelessWidget {
  final List<StudentResult> students;

  const TeacherStudentsListScreen({required this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Students Results")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(student.studentName[0]),
              ),
              title: Text(
                student.studentName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Score: ${student.score}/${student.total}"),
            ),
          );
        },
      ),
    );
  }
}
