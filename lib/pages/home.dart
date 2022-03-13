import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/modules/refresh_token.dart';
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
  final remoteConfig = RemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  late Future<List<Map<dynamic, dynamic>>> _assignments;
  late Future<Map<dynamic, dynamic>> _me, _timetable;

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
    precacheImage(AssetImage('assets/hosan.png'), context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget assignmentCard(BuildContext context, Map<String, dynamic> assignment) {
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
                      TextSpan(
                          text:
                              '${assignment['teacher'] != null ? assignment['teacher'] + ' ' : ''}| '),
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
          future: Future.wait([_me, _assignments, _timetable]),
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
            final timetable = snapshot.data[1];

            final recentAssignments = (assignments as List).where((e) =>
                e['deadline'] == null
                    ? true
                    : DateTime.parse(e['deadline'])
                            .difference(DateTime.now())
                            .inSeconds >
                        0);

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
                                      return assignmentCard(context, e);
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
                                Text('현재 수행평가',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                TextButton(
                                  child: Text('더보기'),
                                  onPressed: () {},
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
                                      title: Text('완성하기'),
                                      subtitle: Text('SW해커톤 | 9시간 남음'),
                                      onTap: () {},
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('최근 학급 공지',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                TextButton(
                                    onPressed: () {}, child: Text('더보기')),
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
                                      title: Text('테스트 공지'),
                                      subtitle: Text('황부연 작성 | 2일 전'),
                                      onTap: () {},
                                    ),
                                  ],
                                )),
                            Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text('2학기 시간표'),
                                      subtitle: Text('[담임] 영어 OOO | 한 달 전'),
                                      onTap: () {},
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        Divider(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('최근 급식',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                TextButton(
                                    onPressed: () {}, child: Text('더보기')),
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
                setState(() {
                  _me = fetchStudentsMeFuture;
                  _assignments = fetchAssignmentsFuture;
                  _timetable = fetchTimetableFuture;
                });
                await Future.wait([fetchAssignmentsFuture]);
              },
            );
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
