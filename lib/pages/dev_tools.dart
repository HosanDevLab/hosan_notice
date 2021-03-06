import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final remoteConfig = FirebaseRemoteConfig.instance;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('????????? ??????'),
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
                  child: Text('??????'),
                ),
                Expanded(child: Divider())
              ],
            ),
            ListTile(
              title: Text('?????? ID ?????? ??????'),
              subtitle: Text(
                '?????? ?????? ?????????????????? Firebase ID Token ????????????',
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
                            if (!snapshot.hasData) return Text('???????????? ???');
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
                              thumbVisibility: true,
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            child: Text('??????'),
                            onPressed: () =>
                                Clipboard.setData(ClipboardData(text: idToken)),
                          ),
                          TextButton(
                            child: Text('??????'),
                            onPressed: () => Navigator.pop(context, "??????"),
                          )
                        ],
                      );
                    });
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('Shared Preferences ??????'),
              subtitle: Text(
                '?????????????????? ?????? ?????? ??????',
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
                            if (snapshot.data != true) return Text('???????????? ???');

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
                              thumbVisibility: true,
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            child: Text('??????'),
                            onPressed: () => Navigator.pop(context, "??????"),
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
                  child: Text('????????? ??????'),
                ),
                Expanded(child: Divider())
              ],
            ),
            ListTile(
              title: Text('?????? ???????????? ??????'),
              subtitle: Text(
                '?????? ???????????? ??????',
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
              title: Text('?????? ?????????'),
              subtitle: Text(
                '??? ?????? ?????? ??????',
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
              title: Text('?????? ???????????? (????????????)'),
              subtitle: Text(
                '?????? ???????????? ???????????? ??????',
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
                  child: Text('?????? ?????????'),
                ),
                Expanded(child: Divider())
              ],
            ),
            ListTile(
              title: Text('????????? ?????? ??????'),
              subtitle: Text(
                '?????? ?????????',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () async {
                var androidPlatformChannelSpecifics =
                    AndroidNotificationDetails('test_channel', '????????? ??????',
                        channelDescription: '???????????? ???????????????.',
                        importance: Importance.max,
                        priority: Priority.high);

                var iosPlatformChannelSpecifics =
                    IOSNotificationDetails(sound: 'slow_spring.board.aiff');
                var platformChannelSpecifics = NotificationDetails(
                    android: androidPlatformChannelSpecifics,
                    iOS: iosPlatformChannelSpecifics);

                await flutterLocalNotificationsPlugin.show(
                  0,
                  '????????? ??????',
                  '????????? Flutter ??????????????????!',
                  platformChannelSpecifics,
                  payload: 'Hello Flutter',
                );
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('????????? ?????? ????????????'),
              subtitle: Text(
                '????????? ????????? ??????????????? ?????????????????????.',
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
                    ...(filteredTable.isNotEmpty
                        ? [HomeWidget.saveWidgetData<bool>('visibility', true)]
                        : [
                            HomeWidget.saveWidgetData<String>(
                                'centerMessage', '????????? ????????? ????????????.'),
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
    );
  }
}
