import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/new_assignment.dart';
import 'package:hosan_notice/widgets/drawer.dart';

import 'assignment.dart';

class AssignmentsPage extends StatefulWidget {
  _AssignmentsPageState createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _assignments,
      _subjects;

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
    _assignments = fetchAssignments();
    _subjects = fetchSubjects();
  }

  Widget assignmentCard(
      BuildContext context, AsyncSnapshot snapshot, String subjectId) {
    Iterable<dynamic> subjectAssignments = (snapshot.data[0] as List).where(
        (e) =>
            e.data()['subject'] ==
            firestore.collection('subjects').doc(subjectId));

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
                  (snapshot.data[1] as List)
                      .firstWhere((e) => e.id == subjectId)['name'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(height: 16),
              (subjectAssignments.isNotEmpty
                  ? Expanded(
                      child: ListView(
                          shrinkWrap: true,
                          children: subjectAssignments
                              .where((e) => e.data()['deadline'] == null
                                  ? true
                                  : (e.data()['deadline'].toDate() as DateTime)
                                          .difference(DateTime.now())
                                          .inSeconds >
                                      0)
                              .map<Widget>(
                            (e) {
                              final data = e.data();

                              Duration? timeDiff;
                              String? timeDiffStr;
                              if (data['deadline'] != null) {
                                timeDiff =
                                    (data['deadline'].toDate() as DateTime)
                                        .difference(DateTime.now());
                                if (timeDiff.inSeconds <= 0) {
                                  final timeDiffNagative = DateTime.now()
                                      .difference(data['deadline'].toDate()
                                          as DateTime);
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
                                  title: Text(data['title'],
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      data['deadline'] == null
                                          ? '기한 없음'
                                          : timeDiffStr!,
                                      style: TextStyle(fontSize: 13)),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AssignmentPage(assignmentId: e.id),
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
                      print('asdf');
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
                    label: Text('모두 보기')),
              ),
              SizedBox(height: 10),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
        message: '뒤로가기를 한번 더 누르면 종료합니다.',
        child: Scaffold(
          appBar: AppBar(
            title: Text('과제 및 수행평가'),
            centerTitle: true,
          ),
          body: FutureBuilder(
            future: Future.wait([_assignments, _subjects]),
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
                    ]));
              }

              return RefreshIndicator(
                child: Container(
                  height: double.infinity,
                  child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('과목별 과제',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                SizedBox(height: 4),
                                Text(
                                    '수업에서 과제가 있다면 잊어버리지 않도록 누구나 자율적으로 등록해 친구들과 공유하세요!',
                                    textAlign: TextAlign.start),
                                Divider(),
                                Text('아래 카드를 양쪽으로 밀어서 과목을 전환합니다.')
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.66,
                            child: PageView(
                              physics: BouncingScrollPhysics(),
                              controller:
                                  PageController(viewportFraction: 0.95),
                              onPageChanged: (index) {},
                              children: (snapshot.data[1] as List)
                                  .map((e) => Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5),
                                      child: assignmentCard(
                                          context, snapshot, e.id)))
                                  .toList(),
                            ),
                          )
                        ],
                      )),
                ),
                onRefresh: () async {
                  final fetchSubjectsFuture = fetchSubjects();
                  final fetchAssignmentsFuture = fetchAssignments();
                  setState(() {
                    _assignments = fetchAssignmentsFuture;
                    _subjects = fetchSubjectsFuture;
                  });
                  await Future.wait(
                      [fetchSubjectsFuture, fetchAssignmentsFuture]);
                },
              );
            },
          ),
          drawer: MainDrawer(parentContext: context),
        ));
  }
}
