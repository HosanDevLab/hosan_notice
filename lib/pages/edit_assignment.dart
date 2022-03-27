import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'assignment.dart';

class EditAssignmentPage extends StatefulWidget {
  final Map assignment;

  EditAssignmentPage(this.assignment, {Key? key}) : super(key: key);

  @override
  _EditAssignmentPageState createState() => _EditAssignmentPageState();
}

class _EditAssignmentPageState extends State<EditAssignmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  DateTime? deadline;
  String? teacher;
  bool isBeingEdited = false;
  late String title;
  late String description;
  String type = 'assignment';

  late Future<Map> _subject;
  late Future<List<Map>> _teachers;

  Future<Map> fetchSubject() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/subjects/${widget.assignment['subject']['_id']}'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchSubject();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map>> fetchTeachers() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/teachers/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTeachers();
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  void initState() {
    deadline = widget.assignment['deadline'] != null
        ? DateTime.parse(widget.assignment['deadline'])
        : null;
    teacher = widget.assignment['teacher'];
    type = widget.assignment['type'];

    _subject = fetchSubject();
    _teachers = fetchTeachers();
    super.initState();
  }

  Future patchAssignment(BuildContext context, String assignmentId) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isBeingEdited = true;
      });

      Future<Map> patchData() async {
        var rawData = remoteConfig.getAll()['BACKEND_HOST'];
        var cfgs = jsonDecode(rawData!.asString());

        final response = await http.patch(
            Uri.parse(
                '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignment['_id']}'),
            body: jsonEncode({
              'title': title,
              'description': description,
              'type': type,
              'subject': widget.assignment['subject']['_id'],
              'teacher': teacher,
              'deadline': deadline?.toIso8601String(),
            }),
            headers: {
              'ID-Token': await user.getIdToken(true),
              'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
              'Content-Type': 'application/json'
            });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data;
        } else if (response.statusCode == 401 &&
            jsonDecode(response.body)['code'] == 40100) {
          await refreshToken();
          return await patchData();
        } else {
          throw Exception('Failed to load post');
        }
      }

      await patchData();

      setState(() {
        isBeingEdited = false;
      });

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AssignmentPage(
            assignmentId: widget.assignment['_id'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: FutureBuilder(
          future: Future.wait([_subject, _teachers]),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('불러오는 중...'),
                ),
                body: Center(
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
                ),
              );
            }

            final subject = snapshot.data[0];
            final List<Map> teachers = snapshot.data[1];

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('과제 편집'),
                    Text(assignment['title'],
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2!
                            .apply(color: Colors.white))
                  ],
                ),
                toolbarHeight: 70,
              ),
              body: RefreshIndicator(
                  child: Container(
                    height: double.infinity,
                    child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            Card(
                                margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                                child: ListTile(
                                  horizontalTitleGap: 2,
                                  leading: Icon(Icons.subject, size: 28),
                                  title: Text(subject['name'],
                                      overflow: TextOverflow.ellipsis),
                                  onTap: () {},
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: ListTile(
                                  horizontalTitleGap: 2,
                                  leading: Icon(Icons.person, size: 28),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DropdownButton(
                                        value: teacher,
                                        isExpanded: true,
                                        hint: Text(
                                          '선생님',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            child: Text(
                                              '선택 안 함',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            value: 0,
                                          ),
                                          ...teachers
                                              .where((e) => e['subjects']
                                                  .contains(subject['_id']))
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  child: Text(
                                                    e['name'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  value: e['_id'],
                                                ),
                                              )
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            teacher =
                                                value is String ? value : null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {},
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: RadioListTile(
                                            title: Text('과제'),
                                            value: 'assignment',
                                            groupValue: type,
                                            onChanged: (value) {
                                              setState(() {
                                                type = value as String;
                                              });
                                            })),
                                    Expanded(
                                        child: RadioListTile(
                                            title: Text('수행평가'),
                                            value: 'assessment',
                                            groupValue: type,
                                            onChanged: (value) {
                                              setState(() {
                                                type = value as String;
                                              });
                                            })),
                                  ],
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: ListTile(
                                  leading: Icon(Icons.timer, size: 28),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(deadline == null
                                          ? '기한 없음'
                                          : DateFormat('yyyy-MM-dd a hh:mm')
                                                  .format(deadline!.toLocal())
                                                  .replaceAll('AM', '오전')
                                                  .replaceAll('PM', '오후') +
                                              ' 까지'),
                                      deadline == null
                                          ? Text('이곳을 클릭해 기한 설정',
                                              style: TextStyle(fontSize: 12))
                                          : Container()
                                    ],
                                  ),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          assignment['deadline'] == null
                                              ? DateTime.now()
                                              : DateTime.parse(
                                                  assignment['deadline'],
                                                ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2050),
                                    );
                                    if (date == null) return;

                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          assignment['deadline'] == null
                                              ? TimeOfDay.now()
                                              : TimeOfDay.fromDateTime(
                                                  DateTime.parse(
                                                    assignment['deadline'],
                                                  ),
                                                ),
                                    );
                                    if (time == null) return;

                                    setState(() {
                                      deadline = DateTime(date.year, date.month,
                                          date.day, time.hour, time.minute).toUtc();
                                    });
                                  },
                                )),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                  margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                                  child: Container(
                                      padding:
                                          EdgeInsets.fromLTRB(10, 0, 10, 0),
                                      child: TextFormField(
                                        validator: (value) =>
                                            value == null ? "제목을 입력하세요." : null,
                                        initialValue: assignment['title'],
                                        onSaved: (text) {
                                          title = text!;
                                        },
                                        decoration: InputDecoration(
                                            border: UnderlineInputBorder(
                                                borderSide: BorderSide.none),
                                            label: Text('과제 제목')),
                                        keyboardType: TextInputType.text,
                                      ))),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                  margin: EdgeInsets.fromLTRB(10, 12, 10, 8),
                                  child: Container(
                                      padding:
                                          EdgeInsets.fromLTRB(10, 5, 10, 15),
                                      child: TextFormField(
                                        validator: (value) =>
                                            value == null ? "내용을 입력하세요." : null,
                                        initialValue: assignment['description'],
                                        onSaved: (text) {
                                          description = text!;
                                        },
                                        decoration: InputDecoration(
                                            label: Text('과제 내용')),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                      ))),
                            ),
                            Divider(indent: 10, endIndent: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                  icon: Icon(Icons.edit),
                                  label: Text(
                                      isBeingEdited ? '수정하는 중...' : '수정하기'),
                                  onPressed: () async {
                                    if (isBeingEdited) return;
                                    await patchAssignment(
                                        context, assignment['_id']);
                                  }),
                            )
                          ]),
                        )),
                  ),
                  onRefresh: () async {
                    final fetchSubjectFuture = fetchSubject();
                    final fetchTeachersFuture = fetchTeachers();

                    setState(() {
                      _subject = fetchSubjectFuture;
                      _teachers = fetchTeachersFuture;
                    });
                    await Future.wait([
                      fetchSubjectFuture,
                      fetchTeachersFuture,
                    ]);
                  }),
            );
          }),
    );
  }
}
