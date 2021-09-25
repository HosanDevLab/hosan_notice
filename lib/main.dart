import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hosan_notice/pages/assignment.dart';
import 'package:hosan_notice/pages/assignments.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:hosan_notice/pages/login.dart';

void main() async {
  await dotenv.load(fileName: ".env");
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', 'KR'),
        // include country code too
      ],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assignments = fetchAssignments();
    _subjects = fetchSubjects();
    precacheImage(AssetImage('assets/hosan.png'), context);
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
                            TextButton(
                              child: Text('더보기'),
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AssignmentsPage()));
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
                            return Column(
                              children: (snapshot.data[0] as List)
                                  .where((e) => e.data()['deadline'] == null
                                  ? true
                                  : (e.data()['deadline'].toDate()
                              as DateTime)
                                  .difference(DateTime.now())
                                  .inSeconds >
                                  0)
                                  .map<Widget>((e) {
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
