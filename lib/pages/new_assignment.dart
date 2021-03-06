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

class NewAssignmentPage extends StatefulWidget {
  final String subjectId;

  NewAssignmentPage({Key? key, required this.subjectId}) : super(key: key);

  @override
  _NewAssignmentPageState createState() => _NewAssignmentPageState();
}

class _NewAssignmentPageState extends State<NewAssignmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final user = FirebaseAuth.instance.currentUser!;
  final storage = new LocalStorage('auth.json');
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime? deadline;
  String? teacher;
  bool isBeingAdded = false;
  late String title;
  late String description;
  String type = 'assignment';

  late Future<Map> _subject;
  late Future<List<Map>> _teachers;

  Future<Map<dynamic, dynamic>> fetchSubject() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/subjects/${widget.subjectId}'),
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

  Future<List<Map<dynamic, dynamic>>> fetchTeachers() async {
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
    _subject = fetchSubject();
    _teachers = fetchTeachers();
    super.initState();
  }

  Future postAssignment(BuildContext context, String assignmentId) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isBeingAdded = true;
      });

      Future<Map<dynamic, dynamic>> postData() async {
        var rawData = remoteConfig.getAll()['BACKEND_HOST'];
        var cfgs = jsonDecode(rawData!.asString());

        final response = await http.post(
            Uri.parse(
                '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments'),
            body: jsonEncode({
              'title': title,
              'description': description,
              'type': type,
              'subject': widget.subjectId,
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
          return await postData();
        } else {
          throw Exception('Failed to load post');
        }
      }

      final data = await postData();

      setState(() {
        isBeingAdded = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AssignmentPage(
            assignmentId: data['_id'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([_subject, _teachers]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text('???????????? ???...'),
                ),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('???????????? ???', textAlign: TextAlign.center),
                      )
                    ])));
          }

          final subject = snapshot.data[0];
          final List<Map> teachers = snapshot.data[1];

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('??? ??????/???????????? ??????'),
                  Text(subject['name'],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButton(
                                    value: teacher,
                                    isExpanded: true,
                                    hint: Text(
                                      '?????????',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        child: Text(
                                          '?????? ??? ???',
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
                                                overflow: TextOverflow.ellipsis,
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
                            ),
                          ),
                          // Card(
                          //   margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                          //   child: Row(
                          //     children: [
                          //       Expanded(
                          //         child: RadioListTile(
                          //           title: Text('??????'),
                          //           value: 'assignment',
                          //           groupValue: type,
                          //           onChanged: (value) {
                          //             setState(() {
                          //               type = value as String;
                          //             });
                          //           },
                          //         ),
                          //       ),
                          //       Expanded(
                          //         child: RadioListTile(
                          //           title: Text('????????????'),
                          //           value: 'assessment',
                          //           groupValue: type,
                          //           onChanged: (value) {
                          //             setState(() {
                          //               type = value as String;
                          //             });
                          //           },
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Card(
                              margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: ListTile(
                                leading: Icon(Icons.timer, size: 28),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deadline == null
                                        ? '?????? ??????'
                                        : DateFormat('yyyy-MM-dd a hh:mm')
                                                .format(deadline!)
                                                .replaceAll('AM', '??????')
                                                .replaceAll('PM', '??????') +
                                            ' ??????'),
                                    deadline == null
                                        ? Text('????????? ????????? ?????? ??????',
                                            style: TextStyle(fontSize: 12))
                                        : Container()
                                  ],
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2050),
                                  );
                                  if (date == null) return;

                                  final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now());
                                  if (time == null) return;

                                  setState(() {
                                    deadline = DateTime(date.year, date.month,
                                        date.day, time.hour, time.minute);
                                  });
                                },
                              )),
                          SizedBox(
                            width: double.infinity,
                            child: Card(
                                margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                                child: Container(
                                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: TextFormField(
                                      validator: (value) =>
                                          value == null ? "????????? ???????????????." : null,
                                      onSaved: (text) {
                                        title = text!;
                                      },
                                      decoration: InputDecoration(
                                          border: UnderlineInputBorder(
                                              borderSide: BorderSide.none),
                                          label: Text('??????(????????????) ??????')),
                                      keyboardType: TextInputType.text,
                                    ))),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Card(
                                margin: EdgeInsets.fromLTRB(10, 12, 10, 8),
                                child: Container(
                                    padding: EdgeInsets.fromLTRB(10, 5, 10, 15),
                                    child: TextFormField(
                                      validator: (value) =>
                                          value == null ? "????????? ???????????????." : null,
                                      onSaved: (text) {
                                        description = text!;
                                      },
                                      decoration:
                                          InputDecoration(label: Text('??????(????????????) ??????')),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    ))),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 4,
                            ),
                            child: Text(
                              '* ?????? ???????????? ?????? ????????? ?????? ??????, ???????????? '
                              '?????????????????? ?????????????????? ?????????????????????! '
                              '????????? ????????? ????????? ?????? ??????????????? ??????????????????.',
                              style: Theme.of(context).textTheme.caption!.apply(
                                    fontSizeDelta: -1,
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                          Divider(indent: 10, endIndent: 10, height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 5,
                            ),
                            child: Text(
                              '* ????????? ????????????, ?????? ??? ?????????????????? ???????????????. '
                              '????????? ???????????? ??????????????? ??????????????????!',
                              style: Theme.of(context).textTheme.caption!.apply(
                                    fontWeightDelta: 1,
                                    fontSizeDelta: -1,
                                  ),
                            ),
                          ),
                          Divider(indent: 10, endIndent: 10),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                icon: Icon(Icons.done),
                                label: Text(
                                    isBeingAdded ? '???????????? ???...' : '?????? ??? ????????????'),
                                onPressed: () async {
                                  if (isBeingAdded) return;
                                  await postAssignment(context, subject['_id']);
                                }),
                          ),
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
                  await Future.wait([fetchSubjectFuture, fetchTeachersFuture]);
                }),
          );
        });
  }
}
