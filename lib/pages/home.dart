import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/modules/refresh_token.dart';
import 'package:hosan_notice/pages/myclass.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'assignment.dart';
import 'assignments.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  late Future<List<Map<dynamic, dynamic>>> _assignments, _teachers;
  late Future<Map<dynamic, dynamic>> _me, _timetable;

  int timeTableMode = 0;

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
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchStudentsMe();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map<dynamic, dynamic>>> fetchAssignments() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      data.sort((a, b) => a['deadline'] == null ? 1 : 0);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchAssignments();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/timetables/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTimetable();
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
    () async {
      final intent = AndroidIntent(
          action: "android.bluetooth.adapter.action.REQUEST_ENABLE");
      await intent.launch();
      await Permission.location.request();
    }();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _me = fetchStudentsMe();
    _assignments = fetchAssignments();
    _timetable = fetchTimetable();
    _teachers = fetchTeachers();
    precacheImage(AssetImage('assets/hosan.png'), context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget assignmentCard(BuildContext context, Map assignment, teacher) {
    Duration? timeDiff;
    String? timeDiffStr;
    if (assignment['deadline'] != null) {
      timeDiff =
          DateTime.parse(assignment['deadline']).difference(DateTime.now());
      if (timeDiff.inSeconds <= 0) {
        final timeDiffNagative =
            DateTime.now().difference(DateTime.parse(assignment['deadline']));
        if (timeDiffNagative.inDays > 0)
          timeDiffStr = '${timeDiffNagative.inDays}일 전 마감됨';
        else if (timeDiffNagative.inHours > 0)
          timeDiffStr = '${timeDiffNagative.inHours}시간 전 마감됨';
        else if (timeDiffNagative.inMinutes > 0)
          timeDiffStr = '${timeDiffNagative.inMinutes}분 전 마감됨';
        else
          timeDiffStr = '${timeDiffNagative.inSeconds}초 전 마감됨';
      } else {
        if (timeDiff.inDays > 0)
          timeDiffStr = '${timeDiff.inDays}일 남음';
        else if (timeDiff.inHours > 0)
          timeDiffStr = '${timeDiff.inHours}시간 남음';
        else if (timeDiff.inMinutes > 0)
          timeDiffStr = '${timeDiff.inMinutes}분 남음';
        else
          timeDiffStr = '${timeDiff.inSeconds}초 남음';
      }
    }

    final subjectStr = assignment['subject']['name'];

    String teacherString = '';
    if (teacher is String) {
      teacherString = teacher + ' ';
    } else if (teacher is Map) {
      teacherString = (teacher['name'] ?? '') + ' ';
    }

    return Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(assignment['title']),
              subtitle: RichText(
                text: TextSpan(
                    style: TextStyle(color: Colors.grey[600]),
                    children: [
                      TextSpan(text: '$subjectStr '),
                      TextSpan(text: '${teacherString}| '),
                      TextSpan(
                          text: assignment['deadline'] == null
                              ? '기한 없음'
                              : '$timeDiffStr',
                          style: assignment['deadline'] != null &&
                                  timeDiff!.inDays < 0
                              ? TextStyle(color: Colors.red)
                              : TextStyle())
                    ]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AssignmentPage(assignmentId: assignment['_id']),
                  ),
                );
              },
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('메인'),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: Future.wait([_me, _assignments, _timetable, _teachers]),
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
            final assignments = snapshot.data[1];
            final timetable = snapshot.data[2];
            final List<Map> teachers = snapshot.data[3];

            final recentAssignments = (assignments as List).where((e) =>
                e['deadline'] == null
                    ? true
                    : DateTime.parse(e['deadline'])
                            .difference(DateTime.now())
                            .inSeconds >
                        0);

            final dow = DateTime.now().weekday;

            final tod = TimeOfDay.now();
            final inMin = tod.hour * 60 + tod.minute;

            late String currentPeriod;
            int period = 0;
            if (inMin < 8 * 60 + 20) {
              currentPeriod = '일과시간 전';
            } else if (8 * 60 + 20 <= inMin && inMin < 9 * 60 + 20) {
              period = 1;
              currentPeriod = '현재 1교시';
            } else if (9 * 60 + 20 <= inMin && inMin < 10 * 60 + 20) {
              period = 2;
              currentPeriod = '현재 2교시';
            } else if (10 * 60 + 20 <= inMin && inMin < 11 * 60 + 20) {
              period = 3;
              currentPeriod = '현재 3교시';
            } else if (11 * 60 + 20 <= inMin && inMin < 12 * 60 + 20) {
              period = 4;
              currentPeriod = '현재 4교시';
            } else if (12 * 60 + 20 <= inMin && inMin < 13 * 60 + 20) {
              currentPeriod = '점심시간';
            } else if (13 * 60 + 20 <= inMin && inMin < 14 * 60 + 20) {
              period = 5;
              currentPeriod = '현재 5교시';
            } else if (14 * 60 + 20 <= inMin && inMin < 15 * 60 + 20) {
              period = 6;
              currentPeriod = '현재 6교시';
            } else if (15 * 60 + 20 <= inMin && inMin < 16 * 60 + 20) {
              period = 7;
              currentPeriod = '현재 7교시';
            } else {
              if (dow == 6 || dow == 7) {
                currentPeriod = '';
              } else {
                currentPeriod = '일과시간 끝';
              }
            }

            final filteredTable = (timetable['table'] as List)
                .where((e) => e['dow'] == dow)
                .toList();

            return RefreshIndicator(
              child: Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(
                                '${student['name']}님, 안녕하세요!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5!
                                    .apply(fontWeightDelta: 1),
                              ),
                              SizedBox(height: 10),
                              Text('호산고 알리미입니다.'),
                            ],
                          ),
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('시간표',
                                    style:
                                        Theme.of(context).textTheme.subtitle1),
                                ToggleButtons(
                                  children: [
                                    Text('오늘'),
                                    Text('전체'),
                                  ],
                                  onPressed: (val) {
                                    setState(() {
                                      timeTableMode = val;
                                    });
                                  },
                                  isSelected: [
                                    timeTableMode == 0,
                                    timeTableMode == 1
                                  ],
                                  borderRadius: BorderRadius.circular(10),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  constraints: BoxConstraints(
                                    minHeight: 30,
                                    minWidth: 50,
                                  ),
                                  textStyle: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            timeTableMode == 0
                                ? filteredTable.isNotEmpty
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ...(filteredTable
                                                ..sort((a, b) =>
                                                    a['period'] - b['period']))
                                              .map(
                                            (a) => TextButton(
                                              onPressed: () {},
                                              child: Text(
                                                a['subject']?['short_name'] ??
                                                    a['subject']?['name'] ??
                                                    '',
                                                style: period == a['period']
                                                    ? TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      )
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .caption,
                                                textAlign: TextAlign.center,
                                              ),
                                              style: TextButton.styleFrom(
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Center(
                                        child: Text(
                                          '오늘 시간표 정보 없음',
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption,
                                        ),
                                      )
                                : Table(
                                    border: TableBorder.all(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.black12,
                                        width: 0.5),
                                    children: [
                                      TableRow(children: [
                                        ...['월', '화', '수', '목', '금'].map(
                                          (e) => TableCell(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5),
                                              child: Text(
                                                e,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ]),
                                      ...List.generate(7, (i) => i + 1,
                                              growable: true)
                                          .map((e) {
                                        return TableRow(
                                          children: ((timetable['table']
                                                      as List)
                                                  .where(
                                                      (r) => r['period'] == e)
                                                  .toList()
                                                ..sort((a, b) =>
                                                    a['dow'] - b['dow']))
                                              .map(
                                                (f) => TableCell(
                                                  child: InkWell(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                      child: Text(
                                                        f['subject']?[
                                                                'short_name'] ??
                                                            f['subject']
                                                                ?['name'] ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    onTap: () {},
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        );
                                      })
                                    ],
                                  ),
                            SizedBox(height: 8),
                          ],
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('현재 할당된 과제',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                TextButton(
                                  child: Text('더보기'),
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AssignmentsPage(),
                                      ),
                                      (route) => route.isFirst,
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            recentAssignments.isNotEmpty
                                ? Column(
                                    children:
                                        recentAssignments.map<Widget>((e) {
                                      return assignmentCard(
                                        context,
                                        e,
                                        teachers.firstWhere(
                                          (t) => t['_id'] == e['teacher'],
                                          orElse: () => {},
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Container(
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      '현재 할당된 과제가 없습니다!',
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  ),
                          ],
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('최근 학급 게시글',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                TextButton(
                                  child: Text('더보기'),
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MyClassPage(),
                                      ),
                                      (route) => route.isFirst,
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              color: Colors.white,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('이 기능은 개발중입니다.'),
                                    subtitle: Text('OOO 작성 | X일 전'),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '최근 급식',
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text('더보기'),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text('2021년 11월 1일'),
                                      subtitle: Text('테스트'),
                                      onTap: () {},
                                    ),
                                  ],
                                )),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              onRefresh: () async {
                final fetchStudentsMeFuture = fetchStudentsMe();
                final fetchAssignmentsFuture = fetchAssignments();
                final fetchTimetableFuture = fetchTimetable();
                final fetchTeachersFuture = fetchTeachers();

                setState(() {
                  _me = fetchStudentsMeFuture;
                  _assignments = fetchAssignmentsFuture;
                  _timetable = fetchTimetableFuture;
                  _teachers = fetchTeachersFuture;
                });
                await Future.wait([
                  fetchStudentsMeFuture,
                  fetchAssignmentsFuture,
                  fetchTimetableFuture,
                  fetchTeachersFuture
                ]);
              },
            );
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
