import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/drawer.dart';

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
                  (snapshot.data[1] as List).firstWhere((e) => e.id == subjectId)['name'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(height: 16),
              ListView(
                shrinkWrap: true,
                children: (snapshot.data[0] as List)
                    .where((e) =>
                        e.data()['subject'] ==
                        firestore.collection('subjects').doc(subjectId))
                    .map<Widget>((e) => (Card(
                          margin: EdgeInsets.all(10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 0.6, color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(e.data()['title']),
                            onTap: () {},
                          ),
                        )),)
                    .toList(),
              )
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
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('과목별 과제',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                                Text('아래 카드를 양쪽으로 밀어서 과목을 전환합니다.',
                                    textAlign: TextAlign.end),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 200,
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
                  final fetchFuture = fetchSubjects();
                  setState(() {
                    _subjects = fetchFuture;
                  });
                  await Future.wait([fetchFuture]);
                },
              );
            },
          ),
          drawer: MainDrawer(parentContext: context),
        ));
  }
}
