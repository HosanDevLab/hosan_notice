import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/login.dart';
import 'package:hosan_notice/types.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

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

class HomePage extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메인'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text('과학 5분 스피치'),
                            subtitle: Text('과학 주석재 | 100일 남음'),
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
                            title: Text('로봇 3차시 실습 과제'),
                            subtitle: RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                style: TextStyle(color: Colors.grey[600]),
                                text: '로봇 정지원 | ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.red),
                                text: '20분 남음!',
                              ),
                            ])),
                            onTap: () {},
                          ),
                        ],
                      )),
                ],
              ),
              SizedBox(height: 5),
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
                            subtitle: Text('과학 주석재 | 100일 남음'),
                            onTap: () {},
                          ),
                        ],
                      )),
                ],
              ),
              SizedBox(height: 5),
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
              SizedBox(height: 5),
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
      drawer: Drawer(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: FutureBuilder(
              future: () async {
                DocumentSnapshot student = await firestore.collection('students').doc(user.uid).get();
                return student.data();
              }(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) return Container();
                final data = snapshot.data;

                return UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(user.photoURL ?? ''),
                    backgroundColor: Colors.transparent,
                  ),
                  accountEmail: Text(user.email ?? ''),
                  accountName: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? ''),
                      Text('${data['grade']}학년 ${data['classNum']}반 ${data['numberInClass']}번')
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[400],
                  ),
                );
              },
            )
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Divider(height: 0),
                ListTile(
                  title: Text('메인'),
                  dense: true,
                  leading: Icon(Icons.home),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('과제 및 수행평가'),
                  dense: true,
                  leading: Icon(Icons.assignment),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('내 학반'),
                  dense: true,
                  leading: Icon(Icons.school),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('급식 메뉴'),
                  dense: true,
                  leading: Icon(Icons.dining),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('화장실 휴지 현황'),
                  dense: true,
                  leading: Icon(Icons.data_usage),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('교직원 배치도'),
                  dense: true,
                  leading: Icon(Icons.people),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('로그아웃', style: TextStyle(color: Colors.red)),
                  dense: true,
                  leading: Icon(Icons.logout, color: Colors.red),
                  onTap: () async {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('로그아웃'),
                            content: Text('로그아웃할까요?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('계속하기'),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await FirebaseAuth.instance.signOut();
                                  await GoogleSignIn().signOut();
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LoginPage(),
                                          fullscreenDialog: true));
                                },
                              ),
                              TextButton(
                                child: Text('취소'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        });
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('설정'),
                  dense: true,
                  leading: Icon(Icons.settings),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 0),
                ListTile(
                  title: Text('개발자 및 정보'),
                  dense: true,
                  leading: Icon(Icons.info),
                  onTap: () async {
                    PackageInfo packageInfo = await PackageInfo.fromPlatform();
                    showAboutDialog(
                        context: context,
                        applicationName: packageInfo.appName,
                        applicationIcon: Image.asset('assets/hosan.png',
                            width: 70, height: 70),
                        applicationVersion: packageInfo.version,
                        applicationLegalese: '호산고 제3기 로봇공학반 교내 피지컬 컴퓨팅 대회 출품작',
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                text: '앱/서버 개발: ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.black),
                                text: '황부연 ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.blue),
                                text: '(21181@hosan.hs.kr)',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launch('mailto:21181@hosan.hs.kr');
                                  },
                              ),
                              TextSpan(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                text: '\n하드웨어 개발/설계: ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.black),
                                text: '강해, 이승민',
                              ),
                            ])),
                          )
                        ]);
                  },
                ),
              ],
            ),
          )
        ],
      )),
    );
  }
}
