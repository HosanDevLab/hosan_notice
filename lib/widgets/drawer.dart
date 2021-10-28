import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/pages/assignments.dart';
import 'package:hosan_notice/main.dart';
import 'package:hosan_notice/pages/beacon.dart';
import 'package:hosan_notice/pages/calendar.dart';
import 'package:hosan_notice/pages/meal_info.dart';
import 'package:hosan_notice/pages/my_attend.dart';
import 'package:hosan_notice/pages/navigation.dart';
import 'package:hosan_notice/pages/register.dart';
import 'package:hosan_notice/pages/toilet_paper_status.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/login.dart';

class MainDrawer extends StatefulWidget {
  final BuildContext parentContext;

  MainDrawer({Key? key, required this.parentContext}) : super(key: key);

  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(NetworkImage(user.photoURL ?? ''), context);
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
            child: UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(user.photoURL ?? ''),
                backgroundColor: Colors.transparent,
              ),
              accountEmail: Text((user.email ?? '') + '\n'),
              accountName: Text(user.displayName ?? ''),
              decoration: BoxDecoration(
                color: Colors.deepPurple[400],
              ),
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
                title: Text('내 출결 및 활동'),
                dense: true,
                leading: Icon(Icons.fact_check),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(widget.parentContext,
                      MaterialPageRoute(builder: (context) => MyAttendancePage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('한눈에 보는 일정표'),
                dense: true,
                leading: Icon(Icons.event_note),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(widget.parentContext,
                      MaterialPageRoute(builder: (context) => CalendarPage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('교내 내비게이션'),
                dense: true,
                leading: Icon(Icons.room),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      widget.parentContext,
                      MaterialPageRoute(
                          builder: (context) => NavigationPage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('급식 메뉴'),
                dense: true,
                leading: Icon(Icons.dining),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(widget.parentContext,
                      MaterialPageRoute(builder: (context) => MealInfoPage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('화장실 휴지 현황'),
                dense: true,
                leading: Icon(Icons.data_usage),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      widget.parentContext,
                      MaterialPageRoute(
                          builder: (context) => ToiletPaperStatusPage()));
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
                title: Text('[DEBUG] 등록 화면'),
                dense: true,
                leading: Icon(Icons.login),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(),
                    ),
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('[DEBUG] 비콘'),
                dense: true,
                leading: Icon(Icons.bluetooth_connected),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      widget.parentContext,
                      MaterialPageRoute(
                          builder: (context) => BeaconScanPage()));
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('[DEBUG] 알림 테스트'),
                dense: true,
                leading: Icon(Icons.notifications),
                onTap: () async {
                  Navigator.pop(context);
                  var androidPlatformChannelSpecifics =
                  AndroidNotificationDetails(
                      'test_channel', '테스트 알림',
                      channelDescription: '테스트용 알림입니다.',
                      importance: Importance.max,
                      priority: Priority.high);

                  var iosPlatformChannelSpecifics =
                  IOSNotificationDetails(sound: 'slow_spring.board.aiff');
                  var platformChannelSpecifics = NotificationDetails(
                      android: androidPlatformChannelSpecifics,
                      iOS: iosPlatformChannelSpecifics);

                  await flutterLocalNotificationsPlugin.show(
                    0,
                    '테스트 알림',
                    '이것은 Flutter 노티피케이션!',
                    platformChannelSpecifics,
                    payload: 'Hello Flutter',
                  );
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
