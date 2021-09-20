import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/assignment.dart';
import 'package:hosan_notice/drawer.dart';
import 'package:hosan_notice/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: '호산고등학교 알리미',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: FutureBuilder(
        future: () async {
          if (user == null) return null;
          CollectionReference students =
              FirebaseFirestore.instance.collection('students');
          return await students.doc(user.uid).get();
        }(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (user != null && !snapshot.hasData) {
            return Scaffold(
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
          return user != null && snapshot.data.exists
              ? HomePage()
              : LoginPage();
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _assignments;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAssignments() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('assignments').get();
    final ls = data.docs.toList();
    return ls;
  }

  @override
  void initState() {
    _assignments = fetchAssignments();
    super.initState();
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
          child: SingleChildScrollView(
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                children: <Widget>[
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('현재 할당된 과제',
                              style: Theme.of(context).textTheme.headline6),
                          TextButton(onPressed: () {}, child: Text('더보기')),
                        ],
                      ),
                      SizedBox(height: 5),
                      FutureBuilder(
                        future: _assignments,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();
                          return Column(
                            children: snapshot.data.map<Widget>((e) {
                              final data = e.data();
                              final timeDiff =
                                  (data['deadline'].toDate() as DateTime)
                                      .difference(DateTime.now());
                              String timeDiffStr;
                              if (timeDiff.inDays > 0)
                                timeDiffStr = '${timeDiff.inDays}일 남음';
                              else if (timeDiff.inHours > 0)
                                timeDiffStr = '${timeDiff.inHours}시간 남음';
                              else if (timeDiff.inMinutes > 0)
                                timeDiffStr = '${timeDiff.inMinutes}분 남음';
                              else
                                timeDiffStr = '${timeDiff.inSeconds}초 남음';
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
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        '${data['subject']} ${data['teacher']} | '),
                                                TextSpan(
                                                    text: '$timeDiffStr',
                                                    style: timeDiff.inDays < 0
                                                        ? TextStyle(
                                                            color: Colors.red)
                                                        : TextStyle())
                                              ]),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AssignmentPage(
                                                      assignmentId: e.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ));
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
                                title: Text('이거 완성하기'),
                                subtitle: Text('ㅁㄴㅇㄹ | 0일 남음'),
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
                                title: Text('분리수거좀 제대로 해라'),
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
                                subtitle: Text('[담임] 영어 이종국 | 한 달 전'),
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
                          Text('오늘의 급식',
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
                                title: Text('2021년 9월 19일'),
                                subtitle: Text('ㅁㄴㅇㄹ\nㅁㄴㅇㄹ\nㅁㄴㅇㄹ\nㅁㄴㅇㄹ\n'),
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
          onRefresh: () async {
            final fetchFuture = fetchAssignments();
            setState(() {
              _assignments = fetchFuture;
            });
            await Future.wait([fetchFuture]);
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
