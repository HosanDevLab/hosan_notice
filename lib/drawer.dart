import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/assignments.dart';
import 'package:hosan_notice/main.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login.dart';

class MainDrawer extends StatefulWidget {
  final BuildContext parentContext;

  MainDrawer({Key? key, required this.parentContext}) : super(key: key);

  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    precacheImage(NetworkImage(user.photoURL ?? ''), context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 1,
            child: FutureBuilder(
              future: () async {
                DocumentSnapshot student =
                    await firestore.collection('students').doc(user.uid).get();
                return student.data();
              }(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
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
                      Text(snapshot.hasData
                          ? '${data['grade']}학년 ${data['classNum']}반 ${data['numberInClass']}번 ${data['name']}'
                          : '불러오는 중...')
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[400],
                  ),
                );
              },
            )),
        Expanded(
          flex: 2,
          child: ListView(
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.zero,
            children: [
              Divider(height: 0),
              ListTile(
                title: Text('메인'),
                dense: true,
                leading: Icon(Icons.home),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(widget.parentContext,
                      MaterialPageRoute(builder: (context) => HomePage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('과제 및 수행평가'),
                dense: true,
                leading: Icon(Icons.assignment),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      widget.parentContext,
                      MaterialPageRoute(
                          builder: (context) => AssignmentsPage()));
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
                            TextSpan(
                              style: TextStyle(color: Colors.black),
                              text: '\n\n* 앱 이용과 관련해 문의사항이 있으시거나 '
                                  '오류 등으로 이용에 지장이 생기는 경우 '
                                  '언제든 상기 메일 주소를 통해 연락 '
                                  '또는 주중에 1학년 8반에 방문해주십시오.',
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
    ));
  }
}