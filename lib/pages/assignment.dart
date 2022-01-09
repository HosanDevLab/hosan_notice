import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssignmentPage extends StatefulWidget {
  final String assignmentId;

  AssignmentPage({Key? key, required this.assignmentId}) : super(key: key);

  @override
  _AssignmentPageState createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  late Future<DocumentSnapshot<Map<String, dynamic>>> _assignment;
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _subjects;
  bool? assignmentLoadDone;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchAssignment() async {
    assignmentLoadDone = false;
    DocumentSnapshot<Map<String, dynamic>> data = await firestore
        .collection('assignments')
        .doc(widget.assignmentId)
        .get();
    return data;
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
    _assignment = fetchAssignment();
    _subjects = fetchSubjects();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([_assignment, _subjects]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text('과제 불러오는 중...'),
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
                    ])));
          }

          final data = snapshot.data[0].data();

          Duration? timeDiff;
          String? timeDiffStr;
          if (data['deadline'] != null) {
            timeDiff = (data['deadline'].toDate() as DateTime)
                .difference(DateTime.now());
            if (timeDiff.inSeconds <= 0) {
              final timeDiffNagative = DateTime.now()
                  .difference(data['deadline'].toDate() as DateTime);
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

          return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title']),
                    Text(
                        data['deadline'] != null
                            ? '기한: ${data['deadline'].toDate().toLocal().toString().split('.')[0]} 까지'
                            : '기한 없음',
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2!
                            .apply(color: Colors.white))
                  ],
                ),
                toolbarHeight: 70,
                backgroundColor:
                    (data['deadline'] == null || timeDiff!.inSeconds >= 0)
                        ? Colors.deepPurple
                        : Colors.pink,
              ),
              body: RefreshIndicator(
                  child: Container(
                    height: double.infinity,
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      child: Column(children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Card(
                                  margin: EdgeInsets.fromLTRB(20, 20, 6, 0),
                                  child: ListTile(
                                    horizontalTitleGap: 2,
                                    leading: Icon(Icons.subject, size: 28),
                                    title: Text(
                                      data['subject'] is DocumentReference
                                          ? (snapshot.data[1] as List)
                                              .firstWhere((e) =>
                                                  e.id ==
                                                  data['subject'].id)['name']
                                          : data['subject'],
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    onTap: () {},
                                  )),
                            ),
                            (data['teacher'] != null
                                ? Expanded(
                                    flex: 3,
                                    child: Card(
                                        margin:
                                            EdgeInsets.fromLTRB(6, 20, 20, 0),
                                        child: ListTile(
                                          horizontalTitleGap: 2,
                                          leading: Icon(Icons.person, size: 28),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(data['teacher'],
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              Text('선생님',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          onTap: () {},
                                        )),
                                  )
                                : SizedBox(width: 14))
                          ],
                        ),
                        Card(
                            margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: ListTile(
                              leading: Icon(Icons.timer, size: 28),
                              title: Text(data['deadline'] == null
                                  ? '기한 없음'
                                  : timeDiffStr!),
                              onTap: () {},
                            )),
                        SizedBox(
                          width: double.infinity,
                          child: Card(
                              margin: EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                child: SelectableText(
                                    (data['description'] as String).isNotEmpty
                                        ? data['description']
                                            .replaceAll(r'\n', '\n')
                                        : '(내용 없음)',
                                    style: TextStyle(fontSize: 16)),
                              )),
                        ),
                      ]),
                    ),
                  ),
                  onRefresh: () async {
                    final fetchFuture = fetchAssignment();
                    setState(() {
                      _assignment = fetchFuture;
                    });
                    await Future.wait([fetchFuture]);
                  }));
        });
  }
}
