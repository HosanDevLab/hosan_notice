import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import '../widgets/drawer.dart';

class SubjectsPage extends StatefulWidget {
  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  bool editMode = false;

  late TabController _tabController;

  late Future<List<Map<dynamic, dynamic>>> _subjects, _teachers;
  late Future<Map<dynamic, dynamic>> _me;

  Set<String> subjectsFirst = {};
  Set<String> subjectsSecond = {};

  Future<Map<dynamic, dynamic>> fetchStudentsMe() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      (data['subjects']['1st'] as List).sort((a, b) => a['order'] - b['order']);
      (data['subjects']['2nd'] as List).sort((a, b) => a['order'] - b['order']);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchStudentsMe();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map> patchStudentsMe(Map data) async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.patch(
      Uri.parse(
          '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
      headers: {
        'ID-Token': await user.getIdToken(true),
        'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map;
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await patchStudentsMe(data);
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map<dynamic, dynamic>>> fetchSubjects() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/subjects/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      data.sort((a, b) => a['order'] - b['order']);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchSubjects();
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
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _me = fetchStudentsMe();
    _subjects = fetchSubjects();
    _teachers = fetchTeachers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _me.then((s) {
      setState(() {
        subjectsFirst = (s['subjects']['1st'] as List)
            .map((e) => e['_id'] as String)
            .toSet();
        subjectsSecond = (s['subjects']['2nd'] as List)
            .map((e) => e['_id'] as String)
            .toSet();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 수강 관리'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: '1학기',
            ),
            Tab(text: '2학기'),
          ],
        ),
        actions: [
          TextButton(
            child: Text(editMode ? '완료' : '편집'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              primary: Colors.white,
            ),
            onPressed: () async {
              if (editMode) {
                final processDialog = showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Text("처리하는 중입니다..."),
                          ),
                        ],
                      ),
                    );
                  },
                );

                final patchStudentsMeFuture = patchStudentsMe({
                  'subjects': {
                    '1st': subjectsFirst.toList(),
                    '2nd': subjectsSecond.toList(),
                  }
                });

                setState(() {
                  _me = patchStudentsMeFuture;
                });

                await patchStudentsMeFuture;
                Navigator.pop(context);
              }

              setState(() {
                editMode = editMode ? false : true;
              });
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_me, _subjects, _teachers]),
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

          final student = snapshot.data[0];
          final subjects = snapshot.data[1] as List<Map>;
          final teachers = snapshot.data[2] as List<Map>;

          return Container(
            height: double.infinity,
            child: TabBarView(
              controller: _tabController,
              children: ['1st', '2nd'].map((t) {
                final filteredSubjects = ((editMode
                        ? subjects.where((e) =>
                            e['grade'] == student['grade'] &&
                            [0, t == '1st' ? 1 : 2].contains(e['termType']))
                        : (student['subjects'][t] as List)) as Iterable)
                    .where((e) => e['hidden'] != true)
                    .toList();

                filteredSubjects.sort((a, b) => a['order'] - b['order']);

                return RefreshIndicator(
                  child: ListView(
                    physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: filteredSubjects.map((e) {
                      final subjectTeachers = teachers
                          .where((t) => t['subjects'].contains(e['_id']));

                      return ListTile(
                        contentPadding: editMode
                            ? EdgeInsets.symmetric(horizontal: 3)
                            : null,
                        leading: editMode
                            ? Transform.scale(
                                scale: 1.05,
                                child: Transform.translate(
                                  offset: Offset(6, 0),
                                  child: Checkbox(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    value: (t == '1st'
                                            ? subjectsFirst
                                            : subjectsSecond)
                                        .contains(e['_id']),
                                    onChanged: (value) {
                                      setState(() {
                                        if (e['isRequired'] == true) {
                                          return;
                                        }

                                        if (value == true) {
                                          if (t == '1st') {
                                            subjectsFirst.add(e['_id']);
                                          } else {
                                            subjectsSecond.add(e['_id']);
                                          }
                                        } else {
                                          if (t == '1st') {
                                            subjectsFirst.remove(e['_id']);
                                          } else {
                                            subjectsSecond.remove(e['_id']);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            if (e['isRequired'] == true) {
                              return;
                            }

                            if (t == '1st') {
                              if (subjectsFirst.contains(e['_id'])) {
                                subjectsFirst.remove(e['_id']);
                              } else {
                                subjectsFirst.add(e['_id']);
                              }
                            } else {
                              if (subjectsSecond.contains(e['_id'])) {
                                subjectsSecond.remove(e['_id']);
                              } else {
                                subjectsSecond.add(e['_id']);
                              }
                            }
                          });
                        },
                        title: Text(
                          (editMode && e['isRequired'] ? '[필수] ' : '') +
                              e['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: subjectTeachers.isNotEmpty
                            ? Text(
                                subjectTeachers
                                        .map((t) => t['name'])
                                        .join(', ') +
                                    ' 선생님',
                                style: TextStyle(fontSize: 13),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                  onRefresh: () async {
                    final fetchStudentMeFuture = fetchStudentsMe();
                    final fetchSubjectsFuture = fetchSubjects();
                    final fetchTeachersFuture = fetchTeachers();

                    setState(() {
                      _me = fetchStudentMeFuture;
                      _subjects = fetchSubjectsFuture;
                      _teachers = fetchTeachersFuture;
                    });

                    await Future.wait([
                      fetchStudentMeFuture,
                      fetchSubjectsFuture,
                      fetchTeachersFuture,
                    ]);
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
