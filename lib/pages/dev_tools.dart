import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'beacon.dart';
import 'register.dart';
import 'std_monitor.dart';

class DevtoolsPage extends StatefulWidget {
  @override
  _DevtoolsPageState createState() => _DevtoolsPageState();
}

class _DevtoolsPageState extends State<DevtoolsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final remoteConfig = RemoteConfig.instance;
  final storage = new LocalStorage('auth.json');
  final firestore = FirebaseFirestore.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String? idToken;

  Future<Map<dynamic, dynamic>> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/timetables/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTimetable();
    } else {
      throw Exception('Failed to load post');
    }
  }

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
                  style: TextStyle(fontSize: 13),
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
                                    child: SelectableText(
                                      snapshot.data!,
                                      style: TextStyle(fontSize: 13),
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
              Divider(height: 0),
              ListTile(
                title: Text('Shared Preferences 확인'),
                subtitle: Text(
                  '애플리케이션 공유 변수 확인',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Shared Preferences'),
                          content: FutureBuilder(
                            future: storage.ready,
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.data != true) return Text('불러오는 중');

                              return Scrollbar(
                                child: SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.only(right: 5),
                                    child: SelectableText(
                                      storage.getItem('AUTH_TOKEN').toString(),
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                isAlwaysShown: true,
                              );
                            },
                          ),
                          actions: [
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
                  style: TextStyle(fontSize: 13),
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
                  style: TextStyle(fontSize: 13),
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
              Divider(height: 0),
              ListTile(
                title: Text('학생 모니터링 (교직원용)'),
                subtitle: Text(
                  '학생 모니터링 화면으로 이동',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentMonitorPage(),
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
                  style: TextStyle(fontSize: 13),
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
              Divider(height: 0),
              ListTile(
                title: Text('시간표 위젯 업데이트'),
                subtitle: Text(
                  '시간표 위젯을 동기화하고 업데이트합니다.',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () async {
                  final timetable = await fetchTimetable();

                  final dow = DateTime.now().weekday;

                  final tod = TimeOfDay.now();
                  final inMin = tod.hour * 60 + tod.minute;

                  int period = 0;
                  if (inMin < 8 * 60 + 20) {
                    period = 0;
                  } else if (8 * 60 + 20 <= inMin && inMin < 9 * 60 + 20) {
                    period = 1;
                  } else if (9 * 60 + 20 <= inMin && inMin < 10 * 60 + 20) {
                    period = 2;
                  } else if (10 * 60 + 20 <= inMin && inMin < 11 * 60 + 20) {
                    period = 3;
                  } else if (11 * 60 + 20 <= inMin && inMin < 12 * 60 + 20) {
                    period = 4;
                  } else if (12 * 60 + 20 <= inMin && inMin < 13 * 60 + 20) {
                    period = 0;
                  } else if (13 * 60 + 20 <= inMin && inMin < 14 * 60 + 20) {
                    period = 5;
                  } else if (14 * 60 + 20 <= inMin && inMin < 15 * 60 + 20) {
                    period = 6;
                  } else if (15 * 60 + 20 <= inMin && inMin < 16 * 60 + 20) {
                    period = 7;
                  }

                  final filteredTable = (timetable['table'] as List)
                      .where((e) => e['dow'] == dow)
                      .toList();
                  filteredTable.sort((a, b) => a['period'] - b['period']);

                  print(filteredTable.map((e) =>
                      e['subject']?['short_name'] ?? e['subject']?['name']));

                  try {
                    await Future.wait([
                      ...List.generate(7, (i) => i + 1).map((e) {
                        final data = filteredTable.firstWhere(
                          (o) => o['period'] == e,
                          orElse: () => null,
                        );

                        return HomeWidget.saveWidgetData<String>(
                          'p${e}',
                          data?['subject']['short_name'] ??
                              data?['subject']['name'] ??
                              'a',
                        );
                      }),
                      ...(filteredTable.isNotEmpty ? [
                        HomeWidget.saveWidgetData<bool>('visibility', true)
                      ] : [
                        HomeWidget.saveWidgetData<String>('centerMessage', '시간표 정보가 없습니다.'),
                        HomeWidget.saveWidgetData<bool>('visibility', false)
                      ]),
                      HomeWidget.saveWidgetData<int>('currentDow', dow),
                      HomeWidget.saveWidgetData<int>('currentPeriod', period)
                    ]);
                    HomeWidget.updateWidget(
                      name: 'TimetableWidgetProvider',
                      iOSName: 'homeWidget',
                    );
                  } on PlatformException catch (exception) {
                    debugPrint('Error Sending Data. $exception');
                  }
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
