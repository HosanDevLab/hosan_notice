import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String name;
  final int grade;
  final int classNum;
  final int numberInClass;
  final bool isPending;

  Student(this.name, this.grade, this.classNum, this.numberInClass, this.isPending);
}

class Assignment {
  final String title;
  final String description;
  final String subject;
  final String teacher;
  final Timestamp createdAt;
  final Timestamp deadline;

  Assignment(this.title, this.description, this.subject, this.teacher, this.createdAt, this.deadline);
}