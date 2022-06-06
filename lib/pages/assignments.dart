import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'assignment.dart';
import 'new_assignment.dart';

class AssignmentsPage extends StatefulWidget {
  _AssignmentsPageState createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  late Future<List<Map<dynamic, dynamic>>> _assignments;
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
      final data = json.decode(response.body);
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

  @override
  void initState() {
    super.initState();
    _me = fetchStudentsMe();
    _assignments = fetchAssignments();
  }

  Widget assignmentCard(
      BuildContext context, AsyncSnapshot snapshot, String subjectId) {
    Iterable<dynamic> subjectAssignments = (snapshot.data[0] as List)
        .where((e) => e['subject']['_id'] == subjectId);

    final filteredSubjectAssignments = subjectAssignments.where((e) =>
        e['deadline'] == null
            ? true
            : DateTime.parse(e['deadline'])
                    .difference(DateTime.now())
                    .inSeconds >
                0);

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                ((snapshot.data[1]['subjects'][remoteConfig.getString(kDebugMode
                            ? 'DEV_CURRENT_SEMESTER'
                            : 'CURRENT_SEMESTER')] ??
                        []) as List)
                    .firstWhere((e) => e['_id'] == subjectId)['name'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),
            (filteredSubjectAssignments.isNotEmpty
                ? Expanded(
                    child: ListView(
                        shrinkWrap: true,
                        children: filteredSubjectAssignments.map<Widget>(
                          (e) {
                            Duration? timeDiff;
                            String? timeDiffStr;
                            if (e['deadline'] != null) {
                              timeDiff = DateTime.parse(e['deadline'])
                                  .difference(DateTime.now());
                              if (timeDiff.inSeconds <= 0) {
                                final timeDiffNagative = DateTime.now()
                                    .difference(DateTime.parse(e['deadline']));
                                if (timeDiffNagative.inDays > 0)
                                  timeDiffStr =
                                      '${timeDiffNagative.inDays}일 전 마감됨';
                                else if (timeDiffNagative.inHours > 0)
                                  timeDiffStr =
                                      '${timeDiffNagative.inHours}시간 전 마감됨';
                                else if (timeDiffNagative.inMinutes > 0)
                                  timeDiffStr =
                                      '${timeDiffNagative.inMinutes}분 전 마감됨';
                                else
                                  timeDiffStr =
                                      '${timeDiffNagative.inSeconds}초 전 마감됨';
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

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 0.5, color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(e['title'],
                                    style: TextStyle(fontSize: 15),
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    e['deadline'] == null
                                        ? '기한 없음'
                                        : timeDiffStr!,
                                    style: TextStyle(fontSize: 13)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssignmentPage(
                                          assignmentId: e['_id']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ).toList()),
                  )
                : Column(
                    children: [
                      Text('지금은 과제가 없습니다! 다행이네요.\n과제가 있다면 자율적으로 등록하세요!',
                          textAlign: TextAlign.center),
                      SizedBox(height: 20)
                    ],
                  )),
            Divider(endIndent: 10, indent: 10, height: 24),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            NewAssignmentPage(subjectId: subjectId)));
                  },
                  icon: Icon(Icons.add),
                  label: Text('과제 등록하기!')),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.open_in_new),
                  label: Text('모두 보기 (개발중)')),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('과제 및 수행평가'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([_assignments, _me]),
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

          final student = snapshot.data[1];

          return RefreshIndicator(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverFillRemaining(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('과목별 과제',
                                style: Theme.of(context).textTheme.headline6),
                            SizedBox(height: 8),
                            Text(
                              '수업에서 과제가 있다면 잊어버리지 않도록 누구나 자율적으로 등록해 친구들과 공유하세요!',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.start,
                            ),
                            Divider(),
                            Text(
                              '아래 카드를 양쪽으로 밀어서 과목을 전환합니다.',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          physics: BouncingScrollPhysics(),
                          controller: PageController(viewportFraction: 0.95),
                          onPageChanged: (index) {},
                          children: ((student['subjects'][
                                      remoteConfig.getString(kDebugMode
                                          ? 'DEV_CURRENT_SEMESTER'
                                          : 'CURRENT_SEMESTER')] ??
                                  []) as List)
                              .where((e) =>
                                  student['grade'] == e['grade'] &&
                                  e['hidden'] != true)
                              .map(
                                (e) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: assignmentCard(
                                    context,
                                    snapshot,
                                    e['_id'],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            onRefresh: () async {
              final fetchStudentMeFuture = fetchStudentsMe();
              final fetchAssignmentsFuture = fetchAssignments();
              setState(() {
                _me = fetchStudentsMe();
                _assignments = fetchAssignmentsFuture;
              });
              await Future.wait([fetchAssignmentsFuture, fetchStudentMeFuture]);
            },
          );
        },
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
