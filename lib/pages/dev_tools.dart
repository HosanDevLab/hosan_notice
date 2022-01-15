import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hosan_notice/pages/register.dart';
import 'package:hosan_notice/widgets/drawer.dart';

import 'beacon.dart';

class DevtoolsPage extends StatefulWidget {
  @override
  _DevtoolsPageState createState() => _DevtoolsPageState();
}

class _DevtoolsPageState extends State<DevtoolsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String? idToken;

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('개발자 옵션'),
          centerTitle: true,
        ),
        body: Container(
          child: ListView(
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            children: [
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text('일반'),
                  ),
                  Expanded(child: Divider())
                ],
              ),
              ListTile(
                title: Text('유저 ID 토큰 확인'),
                subtitle: Text(
                  '현재 유저 클라이언트의 Firebase ID Token 확인하기',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('ID Token'),
                          content: FutureBuilder(
                            future: () async {
                              final token = await user.getIdToken();
                              setState(() {
                                idToken = token;
                              });
                              return token;
                            }(),
                            builder: (BuildContext context,
                                AsyncSnapshot<String> snapshot) {
                              if (!snapshot.hasData) return Text('불러오는 중');
                              return Scrollbar(
                                child: SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.only(right: 5),
                                    child: Text(
                                      snapshot.data!,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                isAlwaysShown: true,
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              child: Text('복사'),
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: idToken)),
                            ),
                            TextButton(
                              child: Text('닫기'),
                              onPressed: () => Navigator.pop(context, "닫기"),
                            )
                          ],
                        );
                      });
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text('페이지 이동'),
                  ),
                  Expanded(child: Divider())
                ],
              ),
              ListTile(
                title: Text('등록 화면으로 이동'),
                subtitle: Text(
                  '등록 화면으로 이동',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(),
                    ),
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('비콘 디버깅'),
                subtitle: Text(
                  '내 주변 비콘 스캔',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BeaconScanPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text('기능 테스트'),
                  ),
                  Expanded(child: Divider())
                ],
              ),
              ListTile(
                title: Text('테스트 알림 전송'),
                subtitle: Text(
                  '알림 테스트',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () async {
                  var androidPlatformChannelSpecifics =
                      AndroidNotificationDetails('test_channel', '테스트 알림',
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
            ],
          ),
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
