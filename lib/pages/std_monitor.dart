import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/attend_monitor.dart';
import 'package:hosan_notice/widgets/drawer.dart';

class StudentMonitorPage extends StatefulWidget {
  StudentMonitorPage({Key? key}) : super(key: key);

  @override
  _StudentMonitorPageState createState() => _StudentMonitorPageState();
}

class _StudentMonitorPageState extends State<StudentMonitorPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  int? grade, classNum;
  String name = '';

  late Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>> _students;

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchStudents() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('students').get();
    return data.docs;
  }

  @override
  void initState() {
    super.initState();
    _students = fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학생 모니터링'),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: _students,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('불러오는 중', textAlign: TextAlign.center),
                    )
                  ],
                ),
              );
            }

            final students = snapshot.data
                as Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>;

            return RefreshIndicator(
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      child: ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          height: max(500, constraints.maxHeight),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Text(
                                  '학생 모니터링',
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                              ),
                              SizedBox(height: 5),
                              Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int?>(
                                      decoration: InputDecoration(
                                          border: InputBorder.none),
                                      autofocus: false,
                                      value: grade,
                                      onChanged: (newValue) {
                                        print(newValue);
                                        setState(() {
                                          grade = newValue;
                                        });
                                      },
                                      items: [
                                            DropdownMenuItem<int?>(
                                              child: Text('모든 학년'),
                                              value: null,
                                            )
                                          ] +
                                          List.generate(3, (i) => i + 1)
                                              .map((i) {
                                            return DropdownMenuItem(
                                                child: Text('$i학년'), value: i);
                                          }).toList(),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int?>(
                                      decoration: InputDecoration(
                                          border: InputBorder.none),
                                      autofocus: false,
                                      value: classNum,
                                      onChanged: (newValue) {
                                        print(newValue);
                                        setState(() {
                                          classNum = newValue;
                                        });
                                      },
                                      items: [
                                            DropdownMenuItem<int?>(
                                              child: Text('모든 반'),
                                              value: null,
                                            )
                                          ] +
                                          List.generate(
                                              grade == 1
                                                  ? 8
                                                  : grade == 2
                                                      ? 9
                                                      : 10,
                                              (i) => i + 1).map((i) {
                                            return DropdownMenuItem(
                                                child: Text('$i반'), value: i);
                                          }).toList(),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                              TextFormField(
                                keyboardType: TextInputType.text,
                                autofocus: false,
                                onChanged: (text) {
                                  name = text;
                                },
                                onFieldSubmitted: (text) {
                                  name = text;
                                },
                                decoration: InputDecoration(
                                  labelText: '학생 이름',
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.deepPurple),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide:
                                          BorderSide(color: Colors.red)),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                ),
                              ),
                              SizedBox(height: 5),
                              ListView(
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                children: students.where((e) {
                                  final data = e.data();
                                  return ((grade != null)
                                          ? data['grade'] == grade
                                          : true) &&
                                      ((classNum != null)
                                          ? data['classNum'] == classNum
                                          : true) &&
                                      ((name.isNotEmpty)
                                          ? data['name'].contains(name)
                                          : true);
                                }).map((e) {
                                  final data = e.data();

                                  return Card(
                                    child: ListTile(
                                      title: Text(data['name']),
                                      subtitle: Text(
                                        '${data['grade']}학년 ' +
                                            '${data['classNum']}반 ' +
                                            '${data['numberInClass']}번',
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AttendMonitorPage(
                                              uid: e.id,
                                              grade: data['grade'],
                                              classNum: data['classNum'],
                                              numberInClass:
                                                  data['numberInClass'],
                                              name: name,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              onRefresh: () async {
                final fetchFuture = fetchStudents();
                setState(() {
                  _students = fetchFuture;
                });
                await fetchFuture;
              },
            );
          }),
      drawer: MainDrawer(
        parentContext: context,
      ),
    );
  }
}
