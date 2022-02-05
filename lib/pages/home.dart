import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/modules/get_device_id.dart';
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

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _assignments,
      _subjects;

  late Future<Map<dynamic, dynamic>> _me;

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
      return json.decode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      final response = await http.get(
          Uri.parse(
              '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/auth/refresh'),
          headers: {
            'ID-Token': await user.getIdToken(true),
            'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
            'Refresh-Token': storage.getItem('REFRESH_TOKEN') ?? '',
            'Device-ID': await getDeviceId() ?? ''
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.setItem('AUTH_TOKEN', data['token']);
        await storage.setItem('REFRESH_TOKEN', data['refreshToken']);
        return await fetchStudentsMe();
      } else {
        throw Exception('Failed to refresh token');
      }
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAssignments() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('assignments').orderBy('deadline').get();
    final ls = data.docs.toList();
    ls.sort((a, b) => a.data()['deadline'] == null ? 1 : 0);
    return ls;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchSubjects() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('subjects').orderBy('order').get();
    final ls = data.docs.toList();
    return ls;
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
    _subjects = fetchSubjects();
    precacheImage(AssetImage('assets/hosan.png'), context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget assignmentCard(BuildContext context, AsyncSnapshot snapshot,
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    Duration? timeDiff;
    String? timeDiffStr;
    if (data['deadline'] != null) {
      timeDiff =
          (data['deadline'].toDate() as DateTime).difference(DateTime.now());
      if (timeDiff.inSeconds <= 0) {
        final timeDiffNagative =
            DateTime.now().difference(data['deadline'].toDate() as DateTime);
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

    final subjectStr = data['subject'] is DocumentReference
        ? (snapshot.data[1] as List)
            .firstWhere((e) => e.id == data['subject'].id)['name']
        : data['subject'];

    return Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(data['title']),
              subtitle: RichText(
                text: TextSpan(
                    style: TextStyle(color: Colors.grey[600]),
                    children: [
                      TextSpan(text: '$subjectStr '),
                      TextSpan(
                          text:
                              '${data['teacher'] != null ? data['teacher'] + ' ' : ''}| '),
                      TextSpan(
                          text: data['deadline'] == null
                              ? '기한 없음'
                              : '$timeDiffStr',
                          style:
                              data['deadline'] != null && timeDiff!.inDays < 0
                                  ? TextStyle(color: Colors.red)
                                  : TextStyle())
                    ]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignmentPage(assignmentId: doc.id),
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
        body: RefreshIndicator(
          child: Container(
            height: double.infinity,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  children: <Widget>[
                    FutureBuilder(
                      future: _me,
                      builder: (BuildContext context,
                          AsyncSnapshot<Map<dynamic, dynamic>> snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        }

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(
                                '${snapshot.data!['name']}님, 안녕하세요!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5!
                                    .apply(fontWeightDelta: 1),
                              ),
                              SizedBox(height: 10),
                              Text('호산고 알리미입니다.'),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('현재 할당된 과제',
                                style: Theme.of(context).textTheme.headline6),
                            TextButton(
                              child: Text('더보기'),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AssignmentsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        FutureBuilder(
                          future: Future.wait([_assignments, _subjects]),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (!snapshot.hasData)
                              return CircularProgressIndicator();

                            final recentAssignments = (snapshot.data[0] as List)
                                .where((e) => e.data()['deadline'] == null
                                    ? true
                                    : (e.data()['deadline'].toDate()
                                                as DateTime)
                                            .difference(DateTime.now())
                                            .inSeconds >
                                        0);

                            if (recentAssignments.isEmpty) {
                              return Container(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  '현재 할당된 과제가 없습니다!',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              );
                            }

                            return Column(
                              children: recentAssignments.map<Widget>((e) {
                                return assignmentCard(context, snapshot, e);
                              }).toList(),
                            );
                          },
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
                                style: Theme.of(context).textTheme.headline6),
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
                                style: Theme.of(context).textTheme.headline6),
                            TextButton(onPressed: () {}, child: Text('더보기')),
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
                                style: Theme.of(context).textTheme.headline6),
                            TextButton(onPressed: () {}, child: Text('더보기')),
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
            final fetchAssignmentsFuture = fetchAssignments();
            final fetchSubjectsFuture = fetchSubjects();
            final fetchStudentsMeFuture = fetchStudentsMe();
            setState(() {
              _assignments = fetchAssignmentsFuture;
              _subjects = fetchSubjectsFuture;
              _me = fetchStudentsMeFuture;
            });
            await Future.wait([fetchAssignmentsFuture]);
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}